#!/usr/bin/env python3
"""Validate portable docs and execute their marked guest examples on scratch data."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[3])
    parser.add_argument('--codemode-cli', type=Path)
    parser.add_argument('--static-only', action='store_true')
    args = parser.parse_args()
    root = args.root.resolve()
    docs = [root / 'README.md', *sorted((root / 'aside-jun').rglob('*.md'))]
    assert len(docs) >= 11, 'missing skill documents'
    broken = []
    for doc in docs:
        for target in re.findall(r'\[[^\]]*\]\(([^\s)]+)(?:\s+[^)]*)?\)', doc.read_text()):
            if '://' in target or target.startswith(('#', 'mailto:')):
                continue
            target = target.split('#')[0]
            if target and not (doc.parent / target).exists():
                broken.append(f'{doc.relative_to(root)}: {target}')
    assert not broken, '\n'.join(broken)
    print(f'Links: {len(docs)} documents; no broken local targets')
    if args.static_only:
        return
    assert args.codemode_cli and args.codemode_cli.is_file(), '--codemode-cli must name an existing entrypoint'
    source = (root / 'aside-jun/references/codemode.md').read_text()
    snippets = {}
    for name in ('local-batch', 'browser-discovery', 'browser-batch'):
        matches = re.findall(r'<!-- example: ' + name + r' -->\s*```js\n(.*?)\n```', source, re.S)
        assert len(matches) == 1, f'expected one executable {name} example'
        snippets[name] = matches[0]
    node = shutil.which('node')
    rg = shutil.which('rg')
    assert node and rg, 'existing Node and ripgrep are required; no installation performed'
    version = json.loads((args.codemode_cli.resolve().parent.parent / 'package.json').read_text())['version']
    assert tuple(int(x) for x in version.split('.')[:3]) >= (0, 9, 0), '0.9.0 completeness contract required'
    with tempfile.TemporaryDirectory(prefix='aside-skill-proof-') as temporary:
        scratch = Path(temporary)
        fixture = scratch / 'fixture'
        fixture.mkdir()
        (fixture / 'alpha.txt').write_text('TODO alpha\n')
        (fixture / 'beta.txt').write_text('TODO beta\n')
        config = scratch / 'config.json'
        config.write_text(json.dumps({'roots': [str(fixture)], 'rgPath': rg,
            'excludeGlobs': [], 'browseCaps': {'enabled': False}}))
        env = {k: v for k, v in os.environ.items() if not k.startswith('CODEMODE_')}
        env.update(CODEMODE_IGNORE_REPO_CONFIG='1', XDG_CONFIG_HOME=str(scratch / 'xdg'))

        def run(name, code):
            job = scratch / (name + '.js')
            job.write_text(code)
            result = subprocess.run([node, str(args.codemode_cli.resolve()), '--config', str(config),
                '--cwd', str(fixture), '--code-file', str(job)], env=env,
                capture_output=True, text=True, timeout=30)
            try:
                data = json.loads(result.stdout)
            except json.JSONDecodeError as exc:
                raise AssertionError(f'{name}: not JSON: {result.stdout!r} {result.stderr!r}') from exc
            return result.returncode, data

        code, out = run('local', snippets['local-batch'])
        assert code == 0 and out['ok'] is True, out
        hits = out['result']['hits']
        assert {r['text'] for r in hits['rows']} == {'TODO alpha', 'TODO beta'}, hits
        assert hits['complete'] is True and hits['truncated'] is False and hits['partial'] == [], hits
        assert isinstance(hits['scope']['coverage'], dict), hits
        assert {r['text'].strip() for r in out['result']['excerpts']} == {'TODO alpha', 'TODO beta'}, out
        print(f'CLI {version}: exact documented local-batch returns two rows, excerpts and coverage')
        code, out = run('discovery', snippets['browser-discovery'])
        assert code == 0 and out['ok'] is True, out
        assert out['result']['exec']['path'] == 'browse.exec', out
        assert out['result']['capture']['path'] == 'browse.captureMany', out
        # Execute the exact example with a shape-only adapter: actual actions.check
        # owns validation; no browser is launched or content result claimed.
        shape = 'const validate = actions; const browse = {exec: async args => validate.check("browse.exec", args)};\n' + snippets['browser-batch']
        code, out = run('browser-shape', shape)
        assert code == 0 and out['ok'] is True and out['result']['ok'] is True, out
        for key in ('missing', 'unknown', 'typeErrors', 'invalid'):
            assert out['result'][key] == [], out
        print('Browser examples: discovery and actual argument schema pass; no navigation claimed')
        code, out = run('cap', 'return await search.content({path:".",query:"TODO",glob:"**/*.txt",max:1});')
        assert code == 0 and out['result']['complete'] is False and out['result']['truncated'] is True, out
        for name, guest, expected in [
            ('outside', 'return await read_file({path:"../outside.txt"});', 'EROOT'),
            ('import', 'return await import("node:fs");', 'EGUESTIMPORT'),
            ('disabled', snippets['browser-batch'], 'EDISABLED'),
        ]:
            code, out = run(name, guest)
            assert code != 0 and out['ok'] is False and out['code'] == expected, out
        print('Negatives: capped result disclosed; EROOT, EGUESTIMPORT and EDISABLED observed')
    print('PASS: source-extracted recipes and bounded negative controls')


if __name__ == '__main__':
    main()
