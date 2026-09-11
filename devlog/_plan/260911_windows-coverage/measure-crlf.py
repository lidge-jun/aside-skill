#!/usr/bin/env python3
"""Byte-exact CRLF measurement for the Windows fleet-join decision.

Measures two things without any shell quoting in between:
  1. live Aside memory L1/L2 files in the active slot
  2. the aside-memory-merge driver's own output for a pure-LF 3-way input

Run:  %USERPROFILE%\\.aside\\runtime\\bin\\python3.cmd measure-crlf.py
"""
import os
import pathlib
import subprocess
import sys
import tempfile

HOME = pathlib.Path(os.path.expanduser("~"))
SLOT = HOME / ".aside" / "u" / "0" / "memory"
DRIVER = HOME / ".aside" / "tools" / "aside-memory-sync" / "bin" / "aside-memory-merge"
PY = HOME / ".aside" / "runtime" / "bin" / "python3.cmd"


def report(label, data):
    crlf = data.count(b"\r\n")
    lone_cr = data.count(b"\r") - crlf
    lf = data.count(b"\n") - crlf
    print("%-46s bytes=%-8d CRLF=%-6d bareLF=%-6d bareCR=%d"
          % (label, len(data), crlf, lf, lone_cr))
    return crlf


def main():
    print("== live slot files ==")
    for name in ("MEMORY.md", "USER.md", "TAXONOMY.md"):
        p = SLOT / name
        if p.exists():
            report(str(p), p.read_bytes())
        else:
            print("%-46s MISSING" % p)

    print()
    print("== driver output for pure-LF 3-way input ==")
    if not DRIVER.exists():
        print("DRIVER MISSING: %s" % DRIVER)
        return 2
    tmp = pathlib.Path(tempfile.mkdtemp(prefix="crlf-probe-"))
    base = tmp / "MEMORY.md"
    ours = tmp / "ours.md"
    theirs = tmp / "theirs.md"
    base.write_bytes(b"# Memory\n\n- alpha\n- bravo\n")
    ours.write_bytes(b"# Memory\n\n- alpha\n- bravo\n- windows-only\n")
    theirs.write_bytes(b"# Memory\n\n- alpha\n- bravo\n- mac-only\n")
    cmd = [str(PY), str(DRIVER), str(base), str(ours), str(theirs), "MEMORY.md"]
    proc = subprocess.run(cmd, capture_output=True)
    print("exit=%d" % proc.returncode)
    if proc.stderr:
        print("stderr: %s" % proc.stderr.decode("utf-8", "replace").strip()[:400])
    merged = ours.read_bytes()
    report("driver merged output (path A)", merged)
    print("--- merged text ---")
    sys.stdout.write(merged.decode("utf-8", "replace"))
    print("--- end ---")
    print("tmpdir=%s" % tmp)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
