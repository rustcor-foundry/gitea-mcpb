# Security Policy

## Reporting a vulnerability

If you find a security issue in this packaging — for example, the install flow leaks credentials, the bundle's binary verification can be bypassed, or the CI release pipeline can be subverted — **do not open a public issue**.

Email **security@w-sky.net** with:

- A description of the issue
- Steps to reproduce
- Affected versions
- Any suggested fix or workaround

You'll get an acknowledgment within 72 hours. We'll work with you on disclosure timing.

## Out of scope

Bugs in the **upstream `gitea-mcp` server itself** — tool behavior, Gitea API exposure, server-side parsing flaws — are out of scope here and should be reported to the upstream project:

- https://gitea.com/gitea/gitea-mcp/issues
- For security-sensitive upstream issues, follow the Gitea project's security policy.

We track upstream releases and pull in fixes automatically via `.gitea/workflows/upstream-watch.yml`.

## Token handling

The MCP server requires a Gitea personal access token. The three install paths handle it differently:

| Path | Where the token lives | Encrypted? |
|---|---|---|
| Claude Desktop (`.mcpb`) | `extensions-installations.json` (or settings file) | Yes — DPAPI on Windows, Keychain on macOS, via `sensitive: true` |
| Claude Code (`~/.claude.json`) | Plain text in JSON | No |
| Codex (`~/.codex/config.toml` + env) | Token in user env var, only ref in TOML | No (but isolated to user env) |

If your security model can't tolerate plaintext-on-disk for the token, the Codex pattern (env var) is the safest of the three.

## Provenance

Every binary in a release bundle is either:

1. **Downloaded from upstream** at CI build time and verified against [`gitea-mcp_X.Y.Z_checksums.txt`](https://gitea.com/gitea/gitea-mcp/releases). SHA256 mismatch fails the build.
2. **Built from source** on a trusted runner at the same tag (currently only freebsd-amd64, which upstream doesn't ship).

The build is reproducible: anyone can run `scripts/fetch-upstream.sh <ver> && scripts/build-bundle.sh <ver>` and produce a byte-identical bundle from the same upstream artifacts. (Zip metadata may differ; the contained binaries and manifest will match.)

## Supported versions

We track upstream `gitea-mcp` releases. Only the **latest** is actively supported. Older versions don't receive packaging fixes — upgrade.
