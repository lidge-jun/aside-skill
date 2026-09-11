#!/usr/bin/env python3
"""Prove the episodic union dropped nothing.

A union that reorders blocks shows deletions in `git diff`. That is expected.
A union that DROPS content also shows deletions, and looks identical in a diffstat.
This separates the two: every non-blank line present in either input must still be
present in the merged output.

Run from inside the memory repo:
    python3 verify-union.py <hold-dir>
"""
import collections
import pathlib
import subprocess
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

MEM = pathlib.Path.home() / ".aside" / "u" / "0" / "memory"
DATES = ["2026-09-10", "2026-09-11"]


def hub_version(rel):
    out = subprocess.run(
        ["git", "-C", str(MEM), "show", "hub/main:" + rel],
        capture_output=True,
    )
    if out.returncode != 0:
        return None
    return out.stdout.decode("utf-8")


def lines(text):
    return [ln.strip() for ln in text.splitlines() if ln.strip()]


def main():
    hold = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else None
    failed = 0
    for d in DATES:
        rel = "episodic/%s.md" % d
        merged = (MEM / "episodic" / ("%s.md" % d)).read_text(encoding="utf-8")
        hub = hub_version(rel)
        win = None
        if hold is not None:
            p = hold / "episodic" / ("%s.md" % d)
            if p.exists():
                win = p.read_text(encoding="utf-8")

        mset = collections.Counter(lines(merged))
        print("== %s ==" % rel)
        for label, src in (("hub", hub), ("windows", win)):
            if src is None:
                print("  %-8s SKIPPED (not available)" % label)
                continue
            missing = [ln for ln in lines(src) if mset[ln] < 1]
            if missing:
                failed += 1
                print("  %-8s MISSING %d lines" % (label, len(missing)))
                for ln in missing[:5]:
                    print("      %s" % ln[:110])
            else:
                print("  %-8s all %d non-blank lines present" % (label, len(lines(src))))
        print("  merged non-blank lines: %d" % len(lines(merged)))

    print()
    if failed:
        print("UNION VERIFY: %d source(s) lost content" % failed)
        return 1
    print("UNION VERIFY: nothing was dropped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
