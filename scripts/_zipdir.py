#!/usr/bin/env python3
"""Recursively zip a directory's contents into a .zip (or .mcpb) archive.

Paths inside the archive are relative to <src_dir>, with forward-slash
separators (so manifests built on Windows produce the same archive as
on Linux). Existing output is overwritten.

Usage: _zipdir.py <src_dir> <output_archive>

We use this in place of the `zip` CLI so the scripts work on minimal runner
images (debian13 minimal doesn't ship `zip`/`unzip`). Python stdlib only.
"""

from __future__ import annotations

import os
import sys
import zipfile


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: _zipdir.py <src_dir> <output_archive>", file=sys.stderr)
        return 64

    src = os.path.abspath(sys.argv[1])
    out = os.path.abspath(sys.argv[2])
    if not os.path.isdir(src):
        print(f"not a directory: {src}", file=sys.stderr)
        return 66

    if os.path.exists(out):
        os.remove(out)

    with zipfile.ZipFile(out, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for root, dirs, files in os.walk(src):
            # Deterministic order, useful for byte-stable bundles across runs.
            dirs.sort()
            for fname in sorted(files):
                full = os.path.join(root, fname)
                arc = os.path.relpath(full, src).replace(os.sep, "/")
                z.write(full, arc)

    sz = os.path.getsize(out)
    print(f"==> {out}  ({sz} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
