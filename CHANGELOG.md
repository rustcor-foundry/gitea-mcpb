# Changelog

All notable changes to `gitea-mcpb` are documented here.

Version numbers track upstream [`gitea-mcp`](https://gitea.com/gitea/gitea-mcp) exactly. Packaging-only re-releases use the `+pkg.N` build-metadata suffix (e.g. `1.3.0+pkg.1`).

The format roughly follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

Nothing pending. Tag the next upstream release to ship.

## [0.1.0] — 2026-05-17

Initial release. Wraps upstream `gitea-mcp` v1.3.0.

### Added
- MCPB v0.3 manifest with `server.type: binary` and `platform_overrides` for win32, darwin, linux.
- Multi-platform bundle: amd64 binaries for win32, darwin, linux included in the main `.mcpb`. arm64 binaries shipped as per-arch sidecar bundles.
- `user_config` fields: host URL, access token (sensitive), allow-insecure-TLS toggle, read-only mode toggle.
- Build scripts: `fetch-upstream.sh` (download + SHA256 verify against upstream sums), `build-bundle.sh` (assemble + pack), `build-from-source-freebsd.sh` (compile upstream from source for FreeBSD), `smoke-test-mcp.py` (MCP `initialize` handshake test).
- Gitea Actions workflows: `release.yml` (tag-triggered, native-tests on linux/windows/macOS-arm64/freebsd runners), `pr.yml` (manifest lint + dry-pack), `upstream-watch.yml` (daily cron, opens bump PRs).
- README with install snippets for Claude Desktop, Claude Code CLI, Codex CLI.
- Front-door docs: `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`, `LICENSE`.

### Known limitations
- Linux arm64 and Windows arm64 binaries ship without native CI smoke-test (no runner available yet).
- macOS amd64 is tested via Rosetta on the Apple Silicon runner only — no native Intel Mac runner.
- Multi-version Gitea host support requires installing the bundle twice. MCPB doesn't currently allow multiple instances of the same server name.
