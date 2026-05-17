# Contributing

Thanks for considering a contribution. This project is small and exists to package an upstream server, so most contributions land in one of three buckets:

1. **Packaging improvements** — manifest tweaks, install UX, install scripts, CI workflows.
2. **Documentation** — README clarifications, install troubleshooting, more host examples.
3. **Bumps** — most version bumps are automated via `.gitea/workflows/upstream-watch.yml`, but a manual PR is fine if you want a release out faster.

For changes to the underlying Gitea MCP server itself (new tools, tool behavior, server bugs), file upstream at [gitea.com/gitea/gitea-mcp](https://gitea.com/gitea/gitea-mcp/issues). We don't carry server patches here.

## Dev setup

You can build a bundle locally without any of the CI infrastructure:

```bash
# Linux/macOS/WSL
./scripts/fetch-upstream.sh 1.3.0     # download + verify upstream binaries
./scripts/build-bundle.sh   1.3.0     # pack dist/gitea-1.3.0.mcpb + sidecars
```

Requirements: `bash`, `curl`, `unzip`, `tar`, `sha256sum`, `zip`, `python3`. On Windows use WSL or Git Bash.

To smoke-test a built bundle's binary speaks MCP:

```bash
python3 scripts/smoke-test-mcp.py path/to/gitea-mcp[.exe]
```

This launches the binary in stdio mode and sends an `initialize` JSON-RPC request. No Gitea instance needed.

## Repo layout

```
gitea-mcpb/
├── manifest.json              # MCPB v0.3 manifest, source of truth
├── icon.png                   # 512×512, included in bundles
├── README.md                  # user-facing
├── PLAN.md                    # design + roadmap
├── LICENSE / CONTRIBUTING / SECURITY / CHANGELOG
├── scripts/
│   ├── fetch-upstream.sh
│   ├── build-bundle.sh
│   ├── build-from-source-freebsd.sh
│   └── smoke-test-mcp.py
└── .gitea/workflows/
    ├── release.yml            # on tag v*  → builds, tests, publishes
    ├── pr.yml                 # on PR      → manifest lint + dry-pack
    └── upstream-watch.yml     # daily cron → opens bump PR if upstream is newer
```

Things that exist locally but **are not committed** (see `.gitignore`):

- `dist-cache/` — downloaded upstream archives + extracted binaries
- `build/` — staging area for the current bundle being packed
- `dist/` — output `.mcpb` files
- `bin/` — a developer's stable path for their own Claude Code / Codex install

## Submitting a PR

1. Branch off `main`.
2. If touching `manifest.json`, run `python3 -c "import json; json.load(open('manifest.json'))"` to confirm it parses. CI does this for you (`pr.yml`).
3. PR title in [Conventional Commits](https://www.conventionalcommits.org/) style: `feat:`, `fix:`, `ci:`, `docs:`, `chore:`.
4. CI runs `pr.yml` (manifest lint + dry-pack). Must be green.
5. Squash-merge once approved. Versioned releases happen via tag push, not merge.

## Releases

Tagged releases go through `release.yml`:

1. Tag `vX.Y.Z` (matching upstream version) on `main`.
2. CI fetches upstream binaries, builds freebsd from source, smoke-tests on every native runner, packs `.mcpb` + per-arch sidecars, publishes a Gitea release with all artifacts attached.
3. After Gitea release lands, the GitHub mirror picks it up (when configured).

If you need to ship a packaging-only fix without an upstream change, tag `vX.Y.Z+pkg.N`.

## Code of conduct

Be kind. Assume good faith. If a discussion needs facilitation, ping a maintainer.
