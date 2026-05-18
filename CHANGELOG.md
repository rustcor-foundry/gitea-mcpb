# Changelog

All notable changes to `gitea-mcpb` are documented here.

Version numbers track upstream [`gitea-mcp`](https://gitea.com/gitea/gitea-mcp) when we ship an upstream bump. For **packaging-only fixes** between upstream releases, we bump our own patch number ahead of upstream — e.g. `1.3.1` packages upstream `1.3.0` with our fix. The CHANGELOG entry calls out which upstream version is wrapped.

(We previously planned to use SemVer build-metadata suffixes like `1.3.0+pkg.1`, but act-runner's tag-glob filter doesn't match tags containing `+`. Simple patch-bumping works with all tooling.)

The format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

Nothing pending. Tag the next upstream release to ship.

## [1.3.1] — 2026-05-17

Packaging-only fix. Wraps upstream `gitea-mcp v1.3.0` (upstream unchanged).

### Fixed
- `icon.png` is now actually included in built bundles. The manifest referenced it but the build script wasn't copying it, so Claude Desktop fell back to first-letter rendering ("G") instead of the Gitea cup-of-tea logo.
- Workflow `is_prerelease` detection no longer flags `+pkg.N` build-metadata tags as prerelease. Per semver, only `-` denotes prerelease; `+` is build metadata. (Moot now that we use patch-bumping instead of `+` suffixes — see CHANGELOG header — but the workflow fix stays.)

## [1.3.0] — 2026-05-17

First public release. Wraps upstream [`gitea-mcp` v1.3.0](https://gitea.com/gitea/gitea-mcp/releases/tag/v1.3.0).

Version mirrors upstream per the policy in `PLAN.md` §3.4 — `gitea-mcpb 1.3.0` ships the `gitea-mcp 1.3.0` binary verbatim, plus our packaging.

### Added
- MCPB v0.3 manifest with `server.type: binary` and `platform_overrides` for win32, darwin, linux. `${__dirname}` substitution in `command` to locate the per-OS binary inside the unpacked bundle.
- Multi-platform main bundle: amd64 binaries for win32, darwin, linux included in `gitea-1.3.0.mcpb`. Per-arch sidecar bundles published alongside for native arm64 on each OS (and freebsd-amd64 built from source).
- `user_config` fields: Gitea host URL, personal access token (`sensitive: true` → encrypted at rest by Claude Desktop), allow-insecure-TLS toggle, read-only mode toggle.
- Build scripts: `fetch-upstream.sh` (download + SHA256 verify against upstream sums), `build-bundle.sh` (assemble main + per-arch + freebsd bundles), `build-from-source-freebsd.sh` (Go cross-build for FreeBSD on the bsd-ws01 runner), `smoke-test-mcp.py` (MCP `initialize` handshake test).
- Gitea Actions workflows: `release.yml` (tag-triggered, native smoke-tests on linux/windows/macOS-arm64/freebsd runners, builds and publishes), `pr.yml` (manifest lint + dry-pack), `upstream-watch.yml` (daily cron, opens bump PRs when upstream is newer).
- Install snippets in README for Claude Desktop, Claude Code CLI, Codex CLI.
- Front-door docs: `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`, `LICENSE`, `icon.png`.

### Known limitations
- Linux arm64 and Windows arm64 binaries ship without native CI smoke-test (no runner available yet — runner additions tracked separately).
- macOS amd64 is tested via Rosetta on the Apple Silicon runner only — no native Intel Mac runner.
- Multi-host Gitea support requires installing the bundle twice. MCPB doesn't currently allow multiple instances of the same server name in one client.

### Earlier internal iterations (not released)
- `0.0.1`–`0.0.4`: smoke builds during initial Claude Desktop install testing (manifest schema iteration, `${__dirname}` substitution verification, `user_config` object-vs-array fix). Never published.
- `0.1.0`: internal multi-platform bundle, validated against `gitea.w-sky.net` from Claude Code (40 repos returned via `list_org_repos`). Bumped to 1.3.0 before first public release to align with upstream + our versioning policy.
