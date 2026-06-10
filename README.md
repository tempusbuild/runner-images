# runner-images

[![test](https://github.com/tempusbuild/runner-images/actions/workflows/test.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/test.yml)
[![build](https://github.com/tempusbuild/runner-images/actions/workflows/build.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/build.yml)
[![weekly-rebuild](https://github.com/tempusbuild/runner-images/actions/workflows/weekly-rebuild.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/weekly-rebuild.yml)
[![codeql](https://github.com/tempusbuild/runner-images/actions/workflows/codeql.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/codeql.yml)
[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/tempusbuild/runner-images/badge)](https://scorecard.dev/viewer/?uri=github.com/tempusbuild/runner-images)
[![license](https://img.shields.io/github/license/tempusbuild/runner-images)](LICENSE)
[![ghcr](https://img.shields.io/badge/ghcr.io-runner--ubuntu--24.04-blue?logo=docker&logoColor=white)](https://github.com/tempusbuild/runner-images/pkgs/container/runner-ubuntu-24.04)

Docker images for self-hosted GitHub Actions runners for [tempus.build](https://tempus.build) —
running GitHub Actions workflows on our infrastructure via ARC `gha-runner-scale-set`.

Public for transparency: you can see exactly what your code runs inside.

## Images

| Image                  | Label                       | Contents                                                                                                              |
| ---------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `ubuntu-24.04`         | `tempus-ubuntu-24.04-4core` | runner + Node 22 + Python (3.12 + toolcache 3.10–3.14) + Go (1.25/1.26) + Rust + Docker CLI + `gh` + base             |
| `ubuntu-24.04-minimal` | —                           | runner + base (no Node/Docker). Built and tested in CI, **not published yet** — only `ubuntu-24.04` is pushed to ghcr |

`ubuntu-24.04` matches GitHub's `ubuntu-latest` (Ubuntu 24.04) and the standard public runner
(4 vCPU / 16 GB). See [`ubuntu-24.04/README.md`](ubuntu-24.04/README.md) for details.

## Local

```bash
just lint    # hadolint, shellcheck, yamllint, actionlint, gitleaks, zizmor, mdformat, markdownlint
just test    # build the full image + smoke tests
just scan    # build + trivy (HIGH/CRITICAL)
just ci      # everything CI runs: lint + build/test/scan of both images
```

## CI

- `test` — on PR: lint + build (full + minimal) + smoke + trivy.
- `build` — on push to `main` / manual: build → trivy scan by digest → tags → **cosign sign + SBOM + SLSA provenance**.
- `weekly-rebuild` — weekly: rebuild for security patches + re-sign.
- `scorecard` — OpenSSF Scorecard (supply-chain posture).

Published tags: `vYYYYMMDD` and `sha-<commit>`, no floating `:latest`; the consumer (ARC scale-set)
pins `tag@sha256:`. How to verify the image signature/provenance — [`SECURITY.md`](SECURITY.md).

## Contributing

Dev setup, checks and DCO sign-off — [`CONTRIBUTING.md`](CONTRIBUTING.md);
community rules — [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
Vulnerability reports — privately via [`SECURITY.md`](SECURITY.md), not public issues.

## License

[Apache-2.0](LICENSE). The **tempus.build** name and logo are trademarks of tempus.build and
are not covered by the license.
