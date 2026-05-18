# Privacy Policy

**Last updated:** 2026-05-18

This document covers the privacy behavior of the `gitea-mcpb` Claude Desktop extension (and the matching Claude Code CLI and Codex CLI install snippets) maintained by **Rustcor Foundry**.

## Plain-English summary

This extension is a thin packaging of the upstream [`gitea-mcp`](https://gitea.com/gitea/gitea-mcp) server, which talks to a Gitea instance **that you choose and control**. No traffic, telemetry, or analytics is sent to Rustcor Foundry, Anthropic, or any third party as a side effect of installing or running this extension.

The MCP server only contacts:

- **The Gitea host URL you configure** (e.g. `https://gitea.com` or your self-hosted instance).
- Nothing else.

## Data flow

```
Claude (Desktop / Code / Codex)
    ↓  stdio (JSON-RPC over MCP)
gitea-mcp binary (running locally on your machine)
    ↓  HTTPS (REST API calls)
The Gitea host you configured  ← all data goes here
```

The bundle does **not** open any other network connections at runtime.

## What the extension accesses

When invoked by Claude (or another MCP client), the server makes Gitea REST API calls using the **personal access token** you provide at install time. The scopes you grant to that token determine what the server can read or write:

- Repository contents, branches, commits, tags, releases
- Issues, pull requests, labels, milestones, wiki, packages
- Your own user/org metadata (for tools like `get_me`)
- Gitea Actions state (if configured)

You can restrict this surface at any time by:

- Reducing the scopes on your Gitea PAT
- Setting `GITEA_READONLY=true` (or `-r`) to disable all write tools
- Setting `GITEA_TOOLS=tool1,tool2,...` (or `-O`) to whitelist specific tools

## Where credentials are stored

Different MCP hosts handle the configured token differently:

| Host | Storage | Encrypted? |
|---|---|---|
| Claude Desktop (`.mcpb` install) | OS keyring (DPAPI on Windows, Keychain on macOS) via the manifest's `sensitive: true` flag | Yes |
| Claude Code CLI (`~/.claude.json`) | Plaintext in the JSON config file | No |
| Codex CLI (recommended pattern) | Read from the `GITEA_ACCESS_TOKEN` user-environment variable; the config file references the var by name, not the value | Not in the config file |

Rustcor Foundry never receives your token or any of your Gitea data. The bundle has no phone-home behavior, no analytics, and no auto-updater that contacts our servers.

## Telemetry

- **Bundle:** none.
- **Upstream `gitea-mcp` server binary:** Rustcor Foundry has no control over the upstream binary; see [the upstream README](https://gitea.com/gitea/gitea-mcp) for any telemetry it may include. To our knowledge as of v1.3.0 (2026-05) the upstream binary does not include telemetry.

## Third-party services

None. The bundle, the install snippets, and the documentation never call any third-party service. The Gitea host you configure is the only network destination.

## TLS verification

If you set `GITEA_INSECURE=true` (or `-k`), the server disables TLS certificate verification when talking to your Gitea host. Only use this for self-signed certificates on networks you trust. This setting does **not** affect anything else; it only relaxes verification for the user-configured Gitea host.

## Logs

The server writes diagnostic output to stderr; Claude Desktop captures this for the Extensions panel. Logs may include request URLs and HTTP status codes but never include the access token. Logs do not leave your machine.

## Children's privacy

This extension is a developer tool. It is not directed at children and does not knowingly collect any information from anyone.

## Updates

Rustcor Foundry may update this policy when packaging or upstream behavior changes. The latest version is always at the canonical location:

**https://github.com/rustcor-foundry/gitea-mcpb/blob/main/PRIVACY.md**

The `CHANGELOG.md` will note any user-impacting privacy change.

## Contact

For privacy concerns or questions:

- **Public issue:** https://github.com/rustcor-foundry/gitea-mcpb/issues
- **Security-sensitive report:** see [SECURITY.md](SECURITY.md) for the private channel.

For privacy concerns about the **upstream `gitea-mcp` server itself**, contact the Gitea project at https://gitea.com/gitea/gitea-mcp.
