# Gitea MCPB — Design & Build Plan

**Status:** draft, awaiting review
**Owner:** Paul (Orenthal Author)
**Repo:** `github.com/<your-org>/gitea-mcpb` *(name TBD)*
**Upstream:** [gitea.com/gitea/gitea-mcp](https://gitea.com/gitea/gitea-mcp) v1.3.0 (2026-05-14)

---

## 1. Why this exists

Claude Desktop (current build: v1.7196.0) installs MCP servers as DXT/MCPB extensions tracked in `extensions-installations.json`. The legacy `claude_desktop_config.json → mcpServers` hand-edit path is no longer read and gets clobbered on app restart. The Anthropic curated marketplace ships GitHub and GitLab MCPs but **no Gitea bundle exists**, even though an official `gitea-mcp` Go server is published by the Gitea project itself.

Result: Gitea users on Claude Desktop have no persistent path to add Gitea tooling. Anyone trying to wire it up by hand watches their config disappear. This project packages the upstream binary as an installable `.mcpb`, hosts it on GitHub, and submits it to the official marketplace so the fix lands once for everyone.

## 2. Scope

**In scope (v1):**
- Wrap upstream `gitea-mcp` binary as a `server.type: binary` MCPB bundle
- Per-OS binaries: `win32`/`darwin`/`linux`, both `amd64` and `arm64` where upstream publishes them
- User-facing config: Gitea host URL + access token (sensitive)
- CI to mirror upstream releases verbatim, with SHA256 verification
- Submission to [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)

**Out of scope (v1):**
- Writing or forking the MCP server itself — we ship upstream's binary as-is
- Code signing (Authenticode / Apple notarization) — defer until marketplace requires it
- Multi-instance support — one Gitea host per install; users wanting two install the bundle twice or run via CLI
- OAuth flows — PAT only, matching upstream

**Deferred (was in v1, pushed out):**
- Publishing to GitHub and submitting to the Anthropic marketplace. Build first, validate locally against `gitea.w-sky.net`, then publish once we know it works.

### 2.1 Multi-vendor strategy

The `gitea-mcp` binary is vendor-agnostic — every MCP host (Claude Desktop, Claude Code CLI, Codex, Cursor, Zed, etc.) just spawns a stdio process with the same `command`/`args`/`env`. Only the **packaging and registration** differ:

| Host | Install mechanism | What we ship |
|---|---|---|
| Claude Desktop | `.mcpb` bundle, double-click install | `gitea-<ver>.mcpb` |
| Claude Code CLI | `mcpServers` block in `~/.claude.json` (or `claude mcp add`) | Snippet in README; optional one-liner installer |
| Codex CLI | `[mcp_servers.gitea]` table in `~/.codex/config.toml` (or `codex mcp add`) | Snippet in README; optional one-liner installer |
| Cursor / Zed / others | Each app's own JSON/TOML config | README snippet |

**Implication:** we maintain one upstream-binary fetch pipeline. The MCPB bundle wraps it for Desktop. For everything else, we publish a cross-platform installer script (e.g. `install.sh` / `install.ps1`) that:

1. Detects the host (`claude`, `codex`, or both)
2. Downloads the upstream gitea-mcp binary for the user's platform (verifying SHA256)
3. Writes the right config block, asking for host URL + token

That installer is a **stretch goal for M2/M3**. For M1 we ship the MCPB and a manual snippet for the other hosts in the README.

**Explicit non-goals:**
- Patching upstream behavior. If a bug needs fixing, file it at `gitea.com/gitea/gitea-mcp` and bump our pin after they ship.

## 3. Architecture

### 3.1 Repository layout

```
gitea-mcpb/
├── manifest.json                  # MCPB v0.3 spec; references binaries below
├── server/
│   ├── gitea-mcp.exe              # win32-amd64
│   ├── gitea-mcp-win-arm64.exe    # win32-arm64 (if upstream ships)
│   ├── gitea-mcp-darwin-amd64
│   ├── gitea-mcp-darwin-arm64
│   ├── gitea-mcp-linux-amd64
│   └── gitea-mcp-linux-arm64
├── icon.png                       # 256×256 PNG; either upstream's or original
├── README.md                      # install instructions, config, troubleshooting
├── LICENSE                        # MIT (matching upstream)
├── CHANGELOG.md                   # per-release notes incl. upstream version
├── SECURITY.md                    # how to report; provenance policy
└── .github/
    ├── workflows/
    │   ├── build-bundle.yml       # on tag: fetch binaries, verify, pack, attach
    │   └── upstream-watch.yml     # cron: poll upstream, open PR on new release
    └── dependabot.yml             # for any node deps in CI
```

The binaries under `server/` are **not** committed. They're downloaded at build time and packaged into the `.mcpb` artifact attached to GitHub releases. The repo stays small.

### 3.2 Manifest (draft)

```json
{
  "$schema": "https://raw.githubusercontent.com/anthropics/mcpb/main/manifest.schema.json",
  "manifest_version": "0.3",
  "name": "gitea",
  "display_name": "Gitea",
  "version": "1.3.0",
  "description": "Interact with Gitea instances — repos, issues, pull requests, releases.",
  "long_description": "Wraps the official gitea-mcp server (gitea.com/gitea/gitea-mcp). Provides MCP tools for browsing repositories, managing issues and pull requests, reading code, and querying releases on any Gitea instance.",
  "author": {
    "name": "<your name or org>",
    "url": "https://github.com/<your-org>/gitea-mcpb"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/<your-org>/gitea-mcpb.git"
  },
  "homepage": "https://github.com/<your-org>/gitea-mcpb",
  "documentation": "https://github.com/<your-org>/gitea-mcpb#readme",
  "support": "https://github.com/<your-org>/gitea-mcpb/issues",
  "icon": "icon.png",
  "license": "MIT",
  "keywords": ["gitea", "git", "scm", "issues", "pull-requests", "self-hosted"],

  "server": {
    "type": "binary",
    "entry_point": "server/gitea-mcp",
    "mcp_config": {
      "command": "${__dirname}/server/gitea-mcp-linux-amd64",
      "args": ["-t", "stdio", "--host", "${user_config.host}"],
      "env": {
        "GITEA_ACCESS_TOKEN": "${user_config.token}",
        "GITEA_INSECURE": "${user_config.allow_insecure_tls}"
      },
      "platform_overrides": {
        "win32": {
          "command": "${__dirname}/server/gitea-mcp.exe"
        },
        "darwin": {
          "command": "${__dirname}/server/gitea-mcp-darwin-amd64"
        },
        "linux": {
          "command": "${__dirname}/server/gitea-mcp-linux-amd64"
        }
      }
    }
  },

  "user_config": [
    {
      "key": "host",
      "type": "string",
      "title": "Gitea host URL",
      "description": "Base URL of your Gitea instance, e.g. https://gitea.com or https://gitea.example.internal",
      "required": true
    },
    {
      "key": "token",
      "type": "string",
      "title": "Personal access token",
      "description": "Create at <host>/-/user/settings/applications. Needs repo, issue, and PR scopes.",
      "sensitive": true,
      "required": true
    },
    {
      "key": "allow_insecure_tls",
      "type": "string",
      "title": "Allow insecure TLS (advanced)",
      "description": "Set to \"true\" only for self-signed cert hosts. Leave blank otherwise.",
      "required": false,
      "default": ""
    }
  ],

  "compatibility": {
    "platforms": ["darwin", "win32", "linux"]
  }
}
```

**Open spec questions** (to resolve before tagging v0.1.0):

1. Does MCPB v0.3 support `arm64`-vs-`amd64` differentiation inside `platform_overrides`, or only by OS? If only by OS, we ship one binary per OS and pick `amd64` (covers ≥95% of installs); arm64 users wait for v1.1.
2. `GITEA_INSECURE` only matters when set to a truthy value. Passing an empty string should be safe but worth confirming upstream doesn't barf on it. If it does, we'll need to conditionally include the env var, which MCPB may or may not support — fallback is a wrapper script.
3. Is `${__dirname}` the correct substitution token (per Desktop Commander's manifest) or does the spec use `${extension_root}`? Need to skim the schema before first build.

### 3.3 Build & release pipeline

**`build-bundle.yml`** (triggered by pushing a tag `v*`):

1. Parse tag → extract upstream version (e.g. `v1.3.0` or `v1.3.0-r2` if we need to re-release without bumping upstream).
2. Fetch `https://gitea.com/gitea/gitea-mcp/releases/download/v<X.Y.Z>/SHA256SUMS` (or equivalent).
3. For each `(os, arch)` we support: download the binary, verify SHA256 against the upstream sums file. Fail the build if any mismatch.
4. Lay out the `server/` directory and copy `manifest.json` + `icon.png` + `README.md`.
5. Run `npx @anthropic-ai/mcpb pack` (or zip manually per the spec) to produce `gitea-<version>.mcpb`.
6. `gh release create` with the `.mcpb` + a `SHA256SUMS.txt` of our own bundle attached.
7. Provenance: emit a GitHub Actions attestation (`actions/attest-build-provenance`) so consumers can verify the bundle was built from this repo at this commit.

**`upstream-watch.yml`** (cron — daily at 13:00 UTC):

1. `gh api repos/... ` won't work for gitea.com — use their REST API: `GET https://gitea.com/api/v1/repos/gitea/gitea-mcp/releases/latest`.
2. Compare `tag_name` to our latest tag.
3. If newer: open a PR that bumps the version in `manifest.json` and `CHANGELOG.md`, with the upstream release notes copied into the PR body.
4. Human review (us) merges; merging-with-a-tag triggers `build-bundle.yml`.

### 3.4 Versioning

Our version **mirrors upstream** by default: `gitea-mcpb v1.3.0` wraps `gitea-mcp v1.3.0`. If we need to ship a packaging fix without an upstream change, append `+pkg.N`: `v1.3.0+pkg.1`. (SemVer-compliant build metadata.)

`manifest.json`'s `version` field must match the bundle filename for the marketplace's diff checks.

### 3.5 Marketplace submission

The submission process for [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) isn't formally documented in the MCPB repo. Expected path:

1. Land a green CI on `main` with at least one tagged release on the new repo.
2. Open a PR against `anthropics/claude-plugins-official` adding `external_plugins/gitea/` mirroring the structure of `gitlab/` and `github/` (those are the closest analogues already in the marketplace per the local marketplace cache at `~/.claude/plugins/marketplaces/claude-plugins-official/`).
3. If the maintainers require a different submission flow (e.g. a Google form, a separate registry repo), they'll redirect.

We'll dig into the marketplace repo's `CONTRIBUTING.md` (if any) before opening the PR. Worst case the PR itself is the submission and we get feedback in review.

## 4. Risks & mitigations

| Risk | Mitigation |
|---|---|
| Upstream changes CLI flags / env vars | Pin to exact upstream version per release; CI smoke-test (run binary with `--help`, assert flags present) catches drift before we ship |
| Binary distribution liability (we re-host upstream's executables) | (a) Always verify SHA256 against upstream sums; (b) `SECURITY.md` documents provenance and points to upstream; (c) reproducibility — any user can rebuild the bundle themselves from this repo + upstream release |
| Upstream goes unmaintained | We have full source path (Go, MIT-ish). Worst case fork their binary build and keep shipping |
| MCPB spec changes between v0.3 and what Claude Desktop ships next | Pin our `manifest_version`; if a desktop update breaks us, bump and re-release |
| `GITEA_INSECURE` becomes default-on by user error | Document clearly; ship default empty; consider validating at install time once MCPB supports input validation |
| Token leaked via process args or logs | Use env var (`GITEA_ACCESS_TOKEN`) not `--token` flag; mark `sensitive: true` in user_config |

## 5. Milestones

- **M0 — Plan approval** *(this doc)*: scope, repo home, manifest skeleton agreed.
- **M1 — First working bundle (v0.1.0)**: hand-built `.mcpb`, side-loaded into Claude Desktop on this machine, verified against `gitea.w-sky.net`. Also: Codex + Claude Code CLI snippets validated by hand on the same machine. No CI, no publish.
- **M2 — Local repo + cross-vendor installer script**: full repo layout, installer (`install.ps1` / `install.sh`) that wires up Claude Code CLI and Codex. Still local-only.
- **M3 — Publish to GitHub + CI**: push to `github.com/<org>/gitea-mcpb`, tagged release v1.3.0, build-bundle workflow green, README ready.
- **M4 — Upstream watcher (v1.3.0+pkg.1)**: scheduled job opens bump PRs.
- **M5 — Marketplace PR**: submitted to `anthropics/claude-plugins-official`.
- **M6 — Merged & discoverable**: appears in Claude Desktop's Settings → Extensions browser.

Rough effort: M1 is half a day, M2 a day, M3–M5 a day each, M6 is on Anthropic's review queue.

## 6. Open questions for Paul

1. **GitHub org/user** for the repo home? (only blocker for M1)
2. **Author name** to put in the manifest — your name, "rustcor", a different handle?
3. **Icon** — happy to draft something simple (Gitea cup-of-tea + Claude motif) or do you want to source one?
4. **License** — confirm MIT to mirror upstream? Anything else risks license-compat headaches.
5. **Defer or ship the orenthal worktree push** in the meantime? (we still haven't auth'd to Gitea — separate decision)

---

*Once approved, M0 closes and I create the repo, scaffold the files, and build the first .mcpb against this machine for live testing.*
