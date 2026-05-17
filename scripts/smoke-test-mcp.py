#!/usr/bin/env python3
"""Smoke-test a gitea-mcp binary by speaking the MCP handshake over stdio.

This launches the binary in stdio transport mode, sends an `initialize`
JSON-RPC request, and asserts a sane response. No Gitea instance needed —
the server initializes before it touches the network, so this proves the
binary is runnable and speaks MCP.

Usage: smoke-test-mcp.py <path-to-gitea-mcp[.exe]>
Exit:  0 on success, non-zero on failure (with reason on stderr).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import time


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: smoke-test-mcp.py <path-to-gitea-mcp>", file=sys.stderr)
        return 64

    binary = sys.argv[1]
    if not os.path.isfile(binary):
        print(f"not found: {binary}", file=sys.stderr)
        return 66

    # Spawn in stdio mode. Use a bogus host that won't be hit unless we make
    # a real tool call. We're only testing initialize.
    proc = subprocess.Popen(
        [binary, "-t", "stdio", "-H", "https://example.invalid"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env={**os.environ, "GITEA_ACCESS_TOKEN": "smoke-test-no-real-token"},
    )

    init_req = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "initialize",
        "params": {
            "protocolVersion": "2025-03-26",
            "capabilities": {},
            "clientInfo": {"name": "gitea-mcpb-smoke-test", "version": "0.0.0"},
        },
    }

    try:
        assert proc.stdin is not None and proc.stdout is not None
        proc.stdin.write((json.dumps(init_req) + "\n").encode())
        proc.stdin.flush()

        # Read with a generous-but-finite timeout
        deadline = time.monotonic() + 10
        line = b""
        while time.monotonic() < deadline:
            chunk = proc.stdout.readline()
            if chunk:
                line = chunk
                break
        if not line:
            print("FAIL: no response from server within 10s", file=sys.stderr)
            stderr = proc.stderr.read(4096) if proc.stderr else b""
            print(stderr.decode(errors="replace"), file=sys.stderr)
            return 1

        resp = json.loads(line)
        if resp.get("id") != 1 or "result" not in resp:
            print(f"FAIL: unexpected response: {resp}", file=sys.stderr)
            return 1

        result = resp["result"]
        server_info = result.get("serverInfo", {})
        proto = result.get("protocolVersion")
        print(
            f"OK: server '{server_info.get('name', '?')}' "
            f"v{server_info.get('version', '?')} "
            f"speaks MCP {proto}"
        )
        return 0
    finally:
        try:
            proc.stdin.close()
        except Exception:
            pass
        proc.terminate()
        try:
            proc.wait(timeout=2)
        except subprocess.TimeoutExpired:
            proc.kill()


if __name__ == "__main__":
    sys.exit(main())
