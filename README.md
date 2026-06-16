# runner-images

[![test](https://github.com/tempusbuild/runner-images/actions/workflows/test.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/test.yml)
[![build](https://github.com/tempusbuild/runner-images/actions/workflows/build.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/build.yml)
[![weekly-rebuild](https://github.com/tempusbuild/runner-images/actions/workflows/weekly-rebuild.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/weekly-rebuild.yml)

[![OpenSSF Scorecard](https://api.scorecard.dev/projects/github.com/tempusbuild/runner-images/badge)](https://scorecard.dev/viewer/?uri=github.com/tempusbuild/runner-images)
[![codeql](https://github.com/tempusbuild/runner-images/actions/workflows/codeql.yml/badge.svg)](https://github.com/tempusbuild/runner-images/actions/workflows/codeql.yml)
[![renovate](https://img.shields.io/badge/renovate-enabled-brightgreen?logo=renovate)](https://github.com/tempusbuild/runner-images/issues/3)

[![ghcr](https://img.shields.io/badge/ghcr.io-runner--ubuntu--24.04-blue?logo=docker&logoColor=white)](https://github.com/tempusbuild/runner-images/pkgs/container/runner-ubuntu-24.04)
[![license](https://img.shields.io/github/license/tempusbuild/runner-images)](LICENSE)

Docker images for self-hosted GitHub Actions runners for [tempus.build](https://tempus.build) —
running GitHub Actions workflows on our infrastructure via ARC `gha-runner-scale-set`.

Public for transparency: you can see exactly what your code runs inside.

## Images

| Image                  | Label                       | Contents                                                                                                                                                                                                                                                                           |
| ---------------------- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ubuntu-24.04`         | `tempus-ubuntu-24.04-4core` | runner + full `ubuntu-latest` toolset parity: languages + prebaked toolcaches (Node/Python/Go/Ruby/PyPy), Java/.NET/PHP/Swift/Julia/Kotlin/Haskell, DevOps/cloud/k8s CLIs, databases, browsers + drivers, Android SDK/NDK — see [`ubuntu-24.04/README.md`](ubuntu-24.04/README.md) |
| `ubuntu-24.04-minimal` | —                           | runner + base (no Node/Docker). Built and tested in CI, **not published yet** — only `ubuntu-24.04` is pushed to ghcr                                                                                                                                                              |

`ubuntu-24.04` provides full toolset parity with GitHub's `ubuntu-latest` (Ubuntu 24.04) on the
standard public-runner shape (4 vCPU / 16 GB). See [`ubuntu-24.04/README.md`](ubuntu-24.04/README.md)
for the complete inventory and the inclusion policy.

## Local

```bash
just lint    # hadolint, shellcheck, yamllint, actionlint, gitleaks, zizmor, mdformat, markdownlint
just test    # build the full image + smoke tests
just scan    # build + trivy (HIGH/CRITICAL)
just ci      # everything CI runs: lint + build/test/scan of both images
```

## CI

- `test` — on PR: lint + build (full + minimal) + size gate + smoke + trivy.
- `build` — on push to `main` / manual: build → smoke + trivy scan by digest → tags →
  **cosign sign + SBOM + SLSA provenance + GitHub attestations**.
- `weekly-rebuild` — weekly: rebuild for security patches + re-sign.
- `scorecard` — OpenSSF Scorecard (supply-chain posture); `codeql` — SAST for the workflows.
- `ghcr-cleanup` — monthly: prune untagged image versions; scheduled failures auto-open an issue.

Published tags: `vYYYYMMDD` and `sha-<commit>`, no floating `:latest`; the consumer (ARC scale-set)
pins `tag@sha256:`. How to verify the image signature/provenance — [`SECURITY.md`](SECURITY.md).

## Contributing

Dev setup, checks and DCO sign-off — [`CONTRIBUTING.md`](CONTRIBUTING.md);
community rules — [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
Vulnerability reports — privately via [`SECURITY.md`](SECURITY.md), not public issues.

## License

[Apache-2.0](LICENSE). The **tempus.build** name and logo are trademarks of tempus.build and
are not covered by the license.
