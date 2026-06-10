# Contributing

Thanks for your interest in improving the tempus.build runner images.

## License of contributions and sign-off (DCO)

Contributions are accepted under the repository license, [Apache-2.0](LICENSE). By submitting a
PR you certify the [Developer Certificate of Origin](https://developercertificate.org/); sign off
each commit (`git commit -s`, adds a `Signed-off-by:` trailer). No CLA is required.

## Development setup

Requires Docker, [`just`](https://github.com/casey/just), and
[`pre-commit`](https://pre-commit.com/). After cloning:

```bash
just hooks    # install the pre-commit git hook
```

## Checks (run before opening a PR)

```bash
just ci       # everything CI runs: lint + build/test/scan of both images
```

Or piecewise: `just lint`, `just test` / `just scan` (full image, builds it first),
`just test-minimal` / `just scan-minimal` (minimal image); `just --list` shows all recipes.
The same set runs in CI — PRs must be green on the `test` workflow.

## Conventions

- **Pin everything.** Base image by `sha256:` digest, toolchain by exact versions,
  GitHub Actions by commit SHA. Never `:latest` or floating tags. Downloaded tarballs
  are verified by SHA256.
- **Security baseline.** Run as the unprivileged `runner` user; no secrets in layers,
  ENV, or ARG; clean the apt cache in the same `RUN`; keep the surface minimal.
- **CVEs.** The build fails on fixable HIGH/CRITICAL. Prefer fixing over suppressing;
  documented exceptions go in `.trivyignore.yaml` with a `statement` and `expired_at`.
- **Comments** are English, written only where they add non-obvious context — no
  decorative banners, no restating the obvious.
- **Shell scripts** start with `set -euo pipefail`.

## Versions

Before bumping a base or toolchain version, check the upstream release/manifest. When
bumping `RUNNER_VERSION`, recompute and update `RUNNER_SHA256` (Renovate does not bump
the hash). Pinned Go/Python toolcache versions come from `go.dev/dl` and the
`actions/python-versions` manifest, respectively.

## Reporting security issues

Do not open a public issue for a vulnerability — see [`SECURITY.md`](SECURITY.md).
