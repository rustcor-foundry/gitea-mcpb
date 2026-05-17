# gitea-mcpb

One-click and one-snippet install of the official [Gitea MCP server](https://gitea.com/gitea/gitea-mcp) for Claude Desktop, Claude Code CLI, and Codex CLI.

Wraps upstream `gitea-mcp` (Go binary, MIT-licensed, maintained by the Gitea project itself) and ships it in three forms so it works wherever you talk to AI.

| Client | Install path | Effort |
|---|---|---|
| Claude Desktop | Double-click `.mcpb` bundle | 30 seconds |
| Claude Code CLI | Paste a JSON snippet into `~/.claude.json` | 1 minute |
| Codex CLI | Paste a TOML snippet into `~/.codex/config.toml` | 1 minute |

The MCP server itself is the same upstream Go binary in all three cases. Only the wrapper differs.

## Prerequisites

1. A Gitea instance you can reach.
2. A personal access token. Create at `<your-gitea-host>/user/settings/applications`, scopes:
   - `repository` (read or write, your choice)
   - `issue`
   - `pull_request`
   - `read:user` (for `get_me`)

If your Gitea uses a self-signed TLS cert, you'll also need `GITEA_INSECURE=true` (covered in each install section).

---

## Install: Claude Desktop (`.mcpb`)

1. Download the latest `gitea-X.Y.Z.mcpb` from [Releases](#) <!-- link once published -->.
2. Double-click the file. Claude Desktop opens its install dialog.
3. Enter your Gitea host URL and access token.
4. Done. New chats have the `gitea` MCP tools available.

The bundle ships amd64 binaries for win32, darwin, and linux. Apple Silicon and Windows-on-ARM run via OS-provided emulation (Rosetta 2 / x64 emulation). Native arm64 binaries are planned.

To uninstall: **Settings → Extensions → Gitea → Uninstall**.

---

## Install: Claude Code CLI

Paste this block into `~/.claude.json` (top level, alongside other settings). Replace `<...>` placeholders.

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

Where to get the binary:
- **Windows:** [`gitea-mcp_Windows_x86_64.zip`](https://gitea.com/gitea/gitea-mcp/releases) — extract `gitea-mcp.exe`
- **macOS:** [`gitea-mcp_Darwin_x86_64.tar.gz`](https://gitea.com/gitea/gitea-mcp/releases) — extract `gitea-mcp`
- **Linux:** [`gitea-mcp_Linux_x86_64.tar.gz`](https://gitea.com/gitea/gitea-mcp/releases) — extract `gitea-mcp`

Drop the binary anywhere stable (e.g. `~/.local/bin/`, `%LOCALAPPDATA%\gitea-mcp\`) and point `command` at it.

Restart Claude Code. The `gitea` server appears in the trust prompt — accept it. Test:

> Use the gitea MCP to list repos under `<your-org>`.

If you'd rather not put the token in JSON, set `GITEA_ACCESS_TOKEN` in your user environment and use a small wrapper script as `command`. Claude Code doesn't have a built-in "read from env" hint like Codex does.

---

## Install: Codex CLI

Paste this block into `~/.codex/config.toml`.

```toml
[mcp_servers.gitea]
command = "<absolute path to gitea-mcp(.exe)>"
args = ["-t", "stdio", "-H", "https://<your-gitea-host>"]
env = { GITEA_INSECURE = "true" }
env_vars = ["GITEA_ACCESS_TOKEN"]
startup_timeout_sec = 60
tool_timeout_sec = 120
```

Then set the token in your shell environment (one-time, persists):

**Windows (PowerShell, user scope):**
```powershell
[System.Environment]::SetEnvironmentVariable("GITEA_ACCESS_TOKEN", "<your_pat>", "User")
```

**macOS / Linux (add to `~/.zshrc` or `~/.bashrc`):**
```bash
export GITEA_ACCESS_TOKEN="<your_pat>"
```

Restart Codex. Test with:

```
codex
> use gitea to list repos under <your-org>
```

`env_vars` reads from Codex's local environment at server-spawn time — the token never lands in `config.toml`.

---

## Tool surface

The upstream server exposes ~50 MCP tools across:

- **Repositories** — `list_my_repos`, `list_org_repos`, `search_repos`, `create_repo`, `fork_repo`, `get_repository_tree`, `get_dir_contents`, `get_file_contents`, `create_or_update_file`, `delete_file`
- **Branches & commits** — `list_branches`, `create_branch`, `delete_branch`, `list_commits`, `get_commit`
- **Tags & releases** — `list_tags`, `get_tag`, `create_tag`, `delete_tag`, `list_releases`, `get_release`, `get_latest_release`, `create_release`, `delete_release`
- **Issues & PRs** — `list_issues`, `search_issues`, `issue_read`, `issue_write`, `list_pull_requests`, `pull_request_read`, `pull_request_write`, `pull_request_review_write`
- **Labels & milestones** — `label_read`, `label_write`, `milestone_read`, `milestone_write`
- **Orgs, users, notifications** — `get_me`, `get_user_orgs`, `search_users`, `search_org_teams`, `notification_read`, `notification_write`
- **Wiki, packages, time-tracking, actions** — `wiki_read/write`, `package_read/write`, `timetracking_read/write`, `actions_config_read/write`, `actions_run_read/write`
- **Misc** — `get_gitea_mcp_server_version`

`get_gitea_mcp_server_version` is useful for verifying you're on the version you think you are.

### Limiting the tool surface

If you want a smaller / read-only set:

- **Read-only mode:** add `GITEA_READONLY=true` to the env (or pass `-r`) — disables all write tools.
- **Explicit tool list:** add `GITEA_TOOLS=tool1,tool2,...` to the env (or pass `-O`).

---

## Security notes

- **Token storage:** the Codex install path (env var via `env_vars`) keeps the token out of any config file. The Claude Code path requires the token in `~/.claude.json` unless you wrap with a launcher. The Claude Desktop path encrypts sensitive fields at rest via DPAPI/Keychain.
- **Self-signed TLS:** `GITEA_INSECURE=true` disables certificate verification for the connection to your Gitea host. Don't enable it unless you actually need it (i.e. your CA isn't in the system trust store).
- **Provenance:** binaries shipped in the `.mcpb` bundle are downloaded from upstream's GitHub release at build time and verified against [`gitea-mcp_X.Y.Z_checksums.txt`](https://gitea.com/gitea/gitea-mcp/releases). The bundle is fully reproducible from this repo.

## Versioning

`gitea-mcpb` version mirrors upstream `gitea-mcp` exactly. If we ship a packaging-only fix without an upstream change, we append `+pkg.N`: e.g. `1.3.0+pkg.1`.

## Upstream

- Server: https://gitea.com/gitea/gitea-mcp
- Issues with the underlying tools, server behavior, or Gitea API surface → file there.
- Issues with packaging (manifest, install, bundle format) → file here.

## License

MIT, matching upstream. The bundled binary is © the Gitea project under their license (also MIT-style; see `UPSTREAM_LICENSE` inside the bundle).
