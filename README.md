<div align="center">

<img src="icon.png" alt="Gitea logo" width="128" height="128" />

# gitea-mcpb

**One-click install of the official Gitea MCP server for Claude Desktop, Claude Code, and Codex.**

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Upstream: gitea-mcp](https://img.shields.io/badge/upstream-gitea--mcp-green.svg)](https://gitea.com/gitea/gitea-mcp)
[![MCPB: v0.3](https://img.shields.io/badge/MCPB-v0.3-orange.svg)](https://github.com/anthropics/mcpb)

</div>

---

`gitea-mcpb` packages the [official Gitea MCP server](https://gitea.com/gitea/gitea-mcp) — written and maintained by the Gitea project itself — as a DXT/MCPB bundle for Claude Desktop, with matching install snippets for Claude Code CLI and Codex CLI. Same upstream binary in all three. No Python toolchain, no forks, no glue code: you talk to your Gitea from any MCP client with one consistent surface of ~50 tools.

Built and maintained by **[Rustcor Foundry](https://gitea.w-sky.net/rustcor)**.

## Pick your install

| Client | How to install | Time |
|---|---|---|
| **Claude Desktop** | Download the `.mcpb` from [Releases](https://gitea.w-sky.net/rustcor/gitea-mcpb/releases), double-click | ~30 sec |
| **Claude Code CLI** | Paste JSON snippet into `~/.claude.json` | ~1 min |
| **Codex CLI** | Paste TOML snippet into `~/.codex/config.toml` | ~1 min |

Detailed steps below.

## Why

Claude Desktop installs MCP servers as MCPB extensions tracked in `extensions-installations.json`. Hand-editing the legacy `claude_desktop_config.json` no longer works — entries are silently dropped on app restart. The Anthropic curated marketplace ships GitHub and GitLab MCPs but had no Gitea bundle, even though the Gitea project publishes an official `gitea-mcp` Go server.

This bundle closes that gap once for everyone, and bundles the same binary as drop-in snippets for the two CLI clients while we're at it.

## Prerequisites

- A Gitea instance you can reach (gitea.com, or self-hosted).
- A Gitea personal access token. Create at `<your-gitea-host>/user/settings/applications` with these scopes:
  - `repository` (read or write — your choice)
  - `issue`
  - `pull_request`
  - `read:user` (for `get_me`)

If your Gitea uses a self-signed TLS cert, you'll also need to set `GITEA_INSECURE=true` (covered in each section below).

---

## Install: Claude Desktop (`.mcpb`)

1. Download the latest `gitea-X.Y.Z.mcpb` from [Releases](https://gitea.w-sky.net/rustcor/gitea-mcpb/releases).
2. Double-click. Claude Desktop opens its install dialog.
3. Fill in host URL and access token. (Optionally toggle insecure TLS / read-only.)
4. Done. New chats have the `gitea` MCP tools available.

The main bundle ships **amd64** binaries for win32, darwin, and linux. Apple Silicon and Windows-on-ARM run via OS-provided emulation (Rosetta 2 / x64 emulation) and work fine. Per-arch sidecar bundles (`gitea-X.Y.Z-darwin-arm64.mcpb`, etc.) are also published if you want native arm64.

To uninstall: **Settings → Extensions → Gitea → Uninstall**.

## Install: Claude Code CLI

Add this block to `~/.claude.json` (top level, alongside other settings):

```json
"mcpServers": {
  "gitea": {
    "command": "<absolute path to gitea-mcp(.exe)>",
    "args": ["-t", "stdio", "-H", "https://<your-gitea-host>"],
    "env": {
      "GITEA_ACCESS_TOKEN": "<your_pat>",
      "GITEA_INSECURE": "true"
    }
  }
}
```

Download the binary for your OS from [upstream releases](https://gitea.com/gitea/gitea-mcp/releases) (or extract from a downloaded `.mcpb`), drop it somewhere stable like `~/.local/bin/gitea-mcp` or `%LOCALAPPDATA%\gitea-mcp\gitea-mcp.exe`, and point `command` at it.

Restart Claude Code. Accept the `gitea` server in the trust prompt. Test:

> Use the gitea MCP to list repos under `<your-org>`.

## Install: Codex CLI

Add this block to `~/.codex/config.toml`:

```toml
[mcp_servers.gitea]
command = "<absolute path to gitea-mcp(.exe)>"
args = ["-t", "stdio", "-H", "https://<your-gitea-host>"]
env = { GITEA_INSECURE = "true" }
env_vars = ["GITEA_ACCESS_TOKEN"]
startup_timeout_sec = 60
tool_timeout_sec = 120
```

Then set the token in your user environment (one-time, persists across sessions):

**Windows PowerShell:**
```powershell
[System.Environment]::SetEnvironmentVariable("GITEA_ACCESS_TOKEN", "<your_pat>", "User")
```

**macOS / Linux** (`~/.zshrc` or `~/.bashrc`):
```bash
export GITEA_ACCESS_TOKEN="<your_pat>"
```

Restart Codex. The `env_vars` mechanism reads from Codex's local environment at server-spawn time — the token never lands in `config.toml`.

---

## What you get

The upstream server exposes ~50 MCP tools spanning every common Gitea workflow:

- **Repos** — list, search, create, fork, tree/dir/file read, file write, file delete
- **Branches & commits** — list, create, delete, commit log, single commit
- **Tags & releases** — list, get, create, delete, latest release
- **Issues** — list, search, read, write
- **Pull requests** — list, read, write, review
- **Labels, milestones** — read + write
- **Orgs, users, notifications** — me, orgs, search users, search teams, notification ops
- **Wiki, packages, time-tracking, Actions** — read + write each
- **Server introspection** — `get_gitea_mcp_server_version`

### Limiting the surface

If you want a smaller / safer set:

| Goal | How |
|---|---|
| Read-only | `GITEA_READONLY=true` (env) or `-r` (flag) |
| Specific tools only | `GITEA_TOOLS=tool1,tool2,...` or `-O tool1,tool2,...` |

---

## Security notes

- **Token storage**: the Codex path keeps the token out of any config file by reading it from `GITEA_ACCESS_TOKEN`. The Claude Code path requires the token in `~/.claude.json` unless you wrap with a launcher. The Claude Desktop path encrypts `sensitive: true` fields at rest (DPAPI on Windows, Keychain on macOS).
- **Self-signed TLS**: `GITEA_INSECURE=true` disables certificate verification for the connection to your Gitea host. Don't enable it unless you actually need it.
- **Binary provenance**: every binary inside a `.mcpb` is downloaded from upstream's release at CI build time and verified against [`gitea-mcp_X.Y.Z_checksums.txt`](https://gitea.com/gitea/gitea-mcp/releases). The freebsd-amd64 binary (which upstream doesn't ship) is built from source at the same tag on our own runner. The bundle is reproducible from this repo: run `scripts/fetch-upstream.sh <version> && scripts/build-bundle.sh <version>`.

See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## Versioning

`gitea-mcpb` version mirrors upstream `gitea-mcp` exactly. If we ship a packaging-only fix without an upstream change, we append `+pkg.N` (e.g. `1.3.0+pkg.1`). See [CHANGELOG.md](CHANGELOG.md).

## Platform coverage

| Platform | Source | CI-tested |
|---|---|---|
| Linux amd64 | Upstream binary | ✅ native |
| Linux arm64 | Upstream binary | ⚠️ shipped untested |
| Windows amd64 | Upstream binary | ✅ native |
| Windows arm64 | Upstream binary | ⚠️ shipped untested |
| macOS amd64 (Intel) | Upstream binary | ⚠️ tested via Rosetta only |
| macOS arm64 (Apple Silicon) | Upstream binary | ✅ native |
| FreeBSD amd64 | **Built from source in CI** | ✅ native |

## Contributing

Bug reports, feature requests, and PRs welcome at [Issues](https://gitea.w-sky.net/rustcor/gitea-mcpb/issues). See [CONTRIBUTING.md](CONTRIBUTING.md) for dev setup and CI structure.

Bugs in the **underlying server** (tool behavior, Gitea API surface, performance) → file upstream at [gitea.com/gitea/gitea-mcp](https://gitea.com/gitea/gitea-mcp/issues). Bugs in the **packaging** (manifest, install flow, bundle format, install scripts) → file here.

## Acknowledgments

The MCP server itself is the work of the [Gitea project](https://gitea.com/gitea/gitea-mcp). This repo is just packaging. The Gitea name and logo are trademarks of the Gitea project, used here under their brand guidelines to identify the upstream server we package. Rustcor Foundry is not affiliated with or endorsed by the Gitea project.

## License

[MIT](LICENSE), matching upstream. The bundled server binary is © the Gitea project under its own MIT license (a copy travels inside every `.mcpb` as `UPSTREAM_LICENSE`).
