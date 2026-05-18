# Anthropic Desktop Extensions Directory — Submission Package

**Target form:** https://clau.de/desktop-extention-submission (redirects to a Google Form)
**Fallback contact:** mcp-review@anthropic.com (if the form is unreachable behind a tenant restriction)

This file is the prepared content for the submission form. Open the form, paste each field from the matching section below, attach the icon, and submit.

---

## 1. Server / extension name

```
Gitea
```

## 2. Server URL (public canonical)

```
https://github.com/rustcor-foundry/gitea-mcpb
```

## 3. Tagline (one sentence)

```
One-click access from Claude to any Gitea instance — gitea.com or self-hosted — with ~50 read/write tools across repos, issues, pull requests, releases, CI, and more.
```

## 4. Description (one paragraph)

```
gitea-mcpb is a packaging of the official Gitea MCP server (gitea.com/gitea/gitea-mcp) as a one-click Desktop Extension. The same upstream Go binary that the Gitea project itself maintains is wrapped here as a multi-platform .mcpb bundle with a small user_config block (host URL, personal access token, optional read-only / insecure-TLS toggles). All ~50 upstream tools are exposed unmodified, covering the full Gitea surface — repositories, branches, commits, tags, releases, issues, pull requests, labels, milestones, wiki, packages, time tracking, and Gitea Actions. The bundle is reproducible from public sources: CI fetches upstream's signed release binaries, verifies SHA256 against upstream's checksums file, and packs the result. Maintained by Rustcor Foundry under MIT; the bundled binary is © the Gitea project under its own MIT license.
```

## 5. Use cases (bullet list, 3-6 items)

```
- Browse and read code in any Gitea repo without leaving the chat — recent commits, file contents, diffs, blame trails.
- Triage and respond to issues / pull requests on self-hosted or cloud Gitea instances; create, comment, label, milestone, close.
- Drive release workflows — query Gitea Actions runs, read job logs, create tags + releases, attach release notes.
- Maintain a Gitea wiki, packages, or time-tracking data from natural language.
- Bridge Claude to internal corporate Gitea instances behind a firewall (self-signed TLS supported via opt-in flag).
```

## 6. Auth type

```
Personal Access Token (Gitea PAT). User creates the token at <host>/user/settings/applications with scopes matching the operations they want — minimally `read:user`; typically `repository`, `issue`, `pull_request`. The token is stored encrypted at rest by Claude Desktop (DPAPI on Windows, Keychain on macOS) via the manifest's `sensitive: true` flag on the user_config field. OAuth is not currently supported by the upstream server.
```

## 7. Transport protocol

```
stdio
```

## 8. Read / write capabilities

```
Both. The bundle exposes the full upstream tool surface by default. Users can restrict to read-only at install time by setting the manifest's `read_only` field to "true" (sets GITEA_READONLY=true), or whitelist specific tools by populating GITEA_TOOLS=tool1,tool2,...
```

## 9. Connection requirements

```
- Network reachability from the user's machine to their Gitea host (HTTPS).
- A Gitea PAT, scoped to the operations they want.
- No other connection requirements. The bundle includes per-OS amd64 binaries for win32/darwin/linux in the main artifact; per-arch sidecars are available for win-arm64, darwin-arm64, linux-arm64, freebsd-amd64 as separate downloads on the same release.
```

## 10. Data handling practices

```
The bundle does not transmit any data anywhere except to the user-configured Gitea host. No telemetry, analytics, or phone-home from us. No third-party SDKs, no remote logging. Credentials are stored encrypted at rest by Claude Desktop (sensitive: true). The upstream binary, to our knowledge as of v1.3.0, also has no telemetry — see https://gitea.com/gitea/gitea-mcp for upstream's own data posture. Full data-flow diagram in PRIVACY.md: https://github.com/rustcor-foundry/gitea-mcpb/blob/main/PRIVACY.md
```

## 11. Third-party connections

```
None at runtime. The only network destination is the user-configured Gitea host.
```

## 12. Health data access

```
None.
```

## 13. Category

```
Developer Tools / Source Control / Git Forge
```

## 14. Tools, resources, prompts

**Resources:** none. (Upstream `gitea-mcp` does not expose MCP resources.)
**Prompts:** none.
**Tools (~52):**

| Tool | Human-readable name | Mode |
|---|---|---|
| `get_gitea_mcp_server_version` | Get gitea-mcp server version | read |
| `get_me` | Get current user | read |
| `get_user_orgs` | Get the current user's organizations | read |
| `search_users` | Search Gitea users | read |
| `search_org_teams` | Search teams within an organization | read |
| `list_my_repos` | List my repositories | read |
| `list_org_repos` | List organization repositories | read |
| `search_repos` | Search repositories | read |
| `create_repo` | Create a repository | write |
| `fork_repo` | Fork a repository | write |
| `get_repository_tree` | Get repository tree | read |
| `get_dir_contents` | List directory contents | read |
| `get_file_contents` | Read file contents | read |
| `create_or_update_file` | Create or update a file in a repo | write |
| `delete_file` | Delete a file from a repo | write |
| `list_branches` | List branches | read |
| `create_branch` | Create a branch | write |
| `delete_branch` | Delete a branch | write |
| `list_commits` | List commits | read |
| `get_commit` | Get a single commit | read |
| `list_tags` | List tags | read |
| `get_tag` | Get a single tag | read |
| `create_tag` | Create a tag | write |
| `delete_tag` | Delete a tag | write |
| `list_releases` | List releases | read |
| `get_release` | Get a single release | read |
| `get_latest_release` | Get the latest release | read |
| `create_release` | Create a release | write |
| `delete_release` | Delete a release | write |
| `list_issues` | List issues | read |
| `search_issues` | Search issues | read |
| `issue_read` | Read issue / comments | read |
| `issue_write` | Create / update / close issues | write |
| `list_pull_requests` | List pull requests | read |
| `pull_request_read` | Read pull-request details / files | read |
| `pull_request_write` | Create / update / merge / close pull requests | write |
| `pull_request_review_write` | Submit / dismiss pull-request reviews | write |
| `label_read` | List or get labels | read |
| `label_write` | Create / update / delete labels | write |
| `milestone_read` | List or get milestones | read |
| `milestone_write` | Create / update / delete milestones | write |
| `wiki_read` | Read wiki pages | read |
| `wiki_write` | Create / update / delete wiki pages | write |
| `package_read` | Read packages | read |
| `package_write` | Manage packages | write |
| `notification_read` | Read notifications | read |
| `notification_write` | Mark notifications read / managed | write |
| `timetracking_read` | Read time-tracking entries on issues | read |
| `timetracking_write` | Add or stop time-tracking entries on issues | write |
| `actions_config_read` | Read Gitea Actions configuration | read |
| `actions_config_write` | Modify Gitea Actions configuration | write |
| `actions_run_read` | Read Gitea Actions runs / jobs / logs | read |
| `actions_run_write` | Trigger or cancel Gitea Actions runs | write |

**Known gap to flag in the submission:** upstream `gitea-mcp` v1.3.0 does not yet annotate tools with `title` / `readOnlyHint` / `destructiveHint` MCP metadata. We mirror upstream's tool definitions verbatim. We've filed [an upstream request](#) (link once filed) to add these annotations; the table above shows our manual classification in the meantime.

## 15. Links

| | URL |
|---|---|
| Documentation (README) | https://github.com/rustcor-foundry/gitea-mcpb#readme |
| Privacy Policy | https://github.com/rustcor-foundry/gitea-mcpb/blob/main/PRIVACY.md |
| Security Policy | https://github.com/rustcor-foundry/gitea-mcpb/blob/main/SECURITY.md |
| Support / issues | https://github.com/rustcor-foundry/gitea-mcpb/issues |
| Upstream server | https://gitea.com/gitea/gitea-mcp |
| Source | https://github.com/rustcor-foundry/gitea-mcpb |
| Releases | https://github.com/rustcor-foundry/gitea-mcpb/releases |

## 16. Credentials — setup steps for a reviewer

A reviewer can validate the extension against the public **gitea.com** instance:

1. Create a free Gitea account at https://gitea.com (any email).
2. Go to **Settings → Applications → Manage Access Tokens** at https://gitea.com/user/settings/applications.
3. Click **Generate New Token**. Name: `claude-review`. Scopes: `read:user`, `read:repository`, `read:issue`, `read:pull_request` (read-only is sufficient for a review pass).
4. Copy the generated token. (Gitea shows it only once.)
5. Install the latest `.mcpb` from https://github.com/rustcor-foundry/gitea-mcpb/releases (double-click `gitea-X.Y.Z.mcpb`).
6. In the install dialog, fill:
   - **Gitea host URL:** `https://gitea.com`
   - **Personal access token:** the token from step 4
   - **Allow insecure TLS:** leave blank
   - **Read-only mode:** type `true` for a read-only review pass
7. Start a fresh chat and ask, e.g., *"List repos under the `gitea` organization."* — should return a populated list.
8. Optional: also test against a self-signed instance by configuring `https://gitea-test.example` with `Allow insecure TLS = true`.

For a write-mode review, scope the token to `write:repository`, `write:issue`, `write:pull_request` and create a throwaway repo under your Gitea user; the extension can create issues, branches, and files there.

## 17. GA date

```
2026-05-18
```

## 18. Surfaces tested

```
- Claude Desktop on Windows 11 x64: native install of the multi-platform .mcpb, manually verified end-to-end against an internal Gitea instance and against gitea.com.
- Claude Desktop on macOS arm64 (Apple Silicon): the macOS binary inside the bundle is smoke-tested in CI on every release on a real Mac mini arm64 runner (MCP initialize handshake against the running binary). UI install pass on macOS is pending a Mac reviewer.
- Claude Desktop on macOS x86_64 (Intel via Rosetta): the darwin-amd64 binary is smoke-tested on the same Mac mini under Rosetta on every release.
- Claude Code CLI on Windows: live (the same upstream binary wired into ~/.claude.json mcpServers.gitea). Validated end-to-end.
- Codex CLI on Windows: live (same binary, env-var token via Codex's env_vars mechanism). Validated end-to-end.
- Linux amd64: binary smoke-tested in CI on every release.
- Linux arm64 / Windows arm64: binaries shipped but not natively smoke-tested (no runner). amd64 Rosetta / x64-emulation paths cover the common case.
- FreeBSD amd64: cross-compiled from source in CI and shipped as a sidecar.

claude.ai (web) was not tested — this is a local Desktop extension.
```

## 19. Server logo

Direct raw URL:
```
https://raw.githubusercontent.com/rustcor-foundry/gitea-mcpb/main/icon.png
```

512×512 PNG. This is the official Gitea cup-of-tea brand mark, used to identify the upstream server we package, per the Gitea project's brand guidelines. Attribution is in LICENSE and README. (If Anthropic prefers a non-trademarked icon we can swap.)

## 20. Favicon

The HTML pages we host (the GitHub repo, the release pages) use GitHub's own favicon; we don't currently serve a separate favicon. If a custom favicon is required for the directory listing, the icon.png above can be down-rendered to 32×32 / 16×16 — let us know if needed.

---

## Submission policy checklist (per claude.com/docs/connectors/building/submission)

- [x] Server name, URL, tagline, description, use cases — sections 1-5
- [x] Auth type, transport, read/write, connection requirements — sections 6-9
- [x] Data handling, third-party connections, health data, category — sections 10-13
- [x] Tools/resources/prompts listed with human-readable names — section 14
- [x] Links to docs, privacy policy, support — section 15
- [x] Credentials + reviewer setup steps — section 16
- [x] GA date and surfaces tested — sections 17-18
- [x] Server logo URL — section 19
- [ ] **Known gap:** tool definitions lack `title` / `readOnlyHint` / `destructiveHint` (upstream limitation, manually classified in section 14)
- [ ] **Note:** Auth is PAT, not OAuth 2.0. Upstream doesn't support OAuth as of v1.3.0.
- [x] Compliance with Anthropic Software Directory Terms + Policy — we agree on submission
- [x] Privacy Policy section in README and `privacy_policies` array in manifest.json — landed in v1.3.3
- [x] Documentation public by publish date — README + PRIVACY.md + SECURITY.md + CHANGELOG.md all public on GitHub
