# Security Policy

`tempusbuild/runner-images` is a public image that executes customer code for tempus.build.
Its trust posture rests on two things: **verifiable provenance** and a **transparent CVE policy**.
This document explains how a consumer can verify all of it independently, and how to report a
vulnerability.

Image: `ghcr.io/tempusbuild/runner-ubuntu-24.04`
Tags: `vYYYYMMDD` and `sha-<commit>` (no floating `:latest` — consumers pin `tag@sha256:...`).

## Verifying provenance

All images from `main` are signed with **cosign keyless** (Sigstore / Fulcio + Rekor, GitHub Actions
OIDC) and carry **SLSA provenance** and an **SBOM** attestation. The signature is applied only after a
green trivy scan of the published-by-digest artifact, so a valid signature means the image passed the
CVE gate.

Requires [cosign](https://github.com/sigstore/cosign) (step 1, signature) and `docker buildx`
(steps 2–3, attestations). Everywhere below, work against the immutable `@sha256:` digest rather than
a floating tag.

```sh
IMAGE=ghcr.io/tempusbuild/runner-ubuntu-24.04
# Pin the digest of a specific image:
DIGEST=$(docker buildx imagetools inspect "${IMAGE}:vYYYYMMDD" --format '{{.Manifest.Digest}}')
```

### 1. Signature (cosign keyless)

```sh
cosign verify \
  --certificate-identity-regexp '^https://github\.com/tempusbuild/runner-images/\.github/workflows/build\.yml@refs/heads/main$' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  "${IMAGE}@${DIGEST}"
```

`--certificate-identity-regexp` binds the signature to the `build.yml` workflow on `refs/heads/main`
of this repository; `--certificate-oidc-issuer` binds it to GitHub OIDC. Any other identity/issuer is
not our build.

### 2. SLSA build provenance

Build provenance is a Sigstore-signed attestation (`actions/attest-build-provenance`) pushed to the
registry next to the digest. Verify with the `gh` CLI:

```sh
gh attestation verify "oci://${IMAGE}@${DIGEST}" --owner tempusbuild
```

### 3. SBOM (SPDX)

The SPDX SBOM is attached as a cosign attestation to the digest (keyless, same OIDC identity as the
signature — the full-image SBOM exceeds GitHub attest's predicate size cap). Verify and read it:

```sh
cosign verify-attestation --type spdxjson \
  --certificate-identity-regexp '^https://github\.com/tempusbuild/runner-images/\.github/workflows/build\.yml@refs/heads/main$' \
  --certificate-oidc-issuer 'https://token.actions.githubusercontent.com' \
  "${IMAGE}@${DIGEST}"
```

Every attestation's certificate identity binds to `build.yml` on `refs/heads/main`, the same trust
anchor as the signature in step 1.

## Vulnerability (CVE) policy

- **Build gate**: every push to `main` is scanned by `trivy` against the published digest with
  `--severity HIGH,CRITICAL`. An unhandled fixable HIGH/CRITICAL **fails** the build, which means the
  image is not signed and is not admitted to run by the consumer's admission policy.
- **Scope**: the blocking gate is **OS-scoped** (`--scanners vuln --pkg-types os`) — the apt/base
  layer this project patches directly (apt security updates + base-digest bump on the weekly rebuild).
  The image is a toolbox of pinned third-party tools (Node/Go/.NET/Ruby/Python CLIs, browsers, CodeQL,
  Selenium, …); CVEs inside those tools' bundled dependencies are addressed by **keeping the tool
  versions current** (Renovate proposes bumps as upstream ships fixes), not by an unmaintainable
  per-dependency ignore list — the same posture GitHub-hosted runner images take. Image secrets are
  covered by `gitleaks` (source) and Dockle (image), so trivy's secret scanner is not run.
- **`--ignore-unfixed`**: enabled. CVEs with no available fix do not block the build (nothing to fix),
  but are picked up automatically once upstream ships a patch — that is what the weekly rebuild
  (`weekly-rebuild.yml`) is for.
- **Documented exceptions** live in [`.trivyignore.yaml`](.trivyignore.yaml). Silent suppression and
  widening the severity filter are not allowed. Each exception carries:
  - `id` — the CVE identifier;
  - `statement` — the rationale (why the fix is unavailable/inapplicable for now);
  - `expired_at` — the date after which trivy stops ignoring the CVE → forced re-triage.
- **Review**: exceptions and unfixed CVEs are re-checked on every weekly rebuild. An expired
  `expired_at` fails the gate again until the decision is updated (a fix or an extended rationale).

## Currency of pins

The base image is pinned by `sha256:` digest; the bundled toolset (runner, language runtimes and
toolcaches, CLIs, build tools, browsers and drivers) by exact versions with SHA256/512-verified
downloads or key-verified vendor apt repositories; and all GitHub Actions by commit SHA. Pin
currency is maintained by:

- **`weekly-rebuild.yml`** — a weekly rebuild with the same digest/pins (pulls apt package patches
  into the layers, refreshes attestations);
- **Renovate** ([`renovate.json`](renovate.json)) — proposes PRs to bump the base digest, action SHAs,
  and toolchain versions.

## Reporting a vulnerability

If you find a vulnerability in the image or the supply-chain pipeline:

- Preferably — privately via **GitHub Security Advisories**: "Report a vulnerability" on the
  **Security** tab of this repository
  (`https://github.com/tempusbuild/runner-images/security/advisories/new`).
- Do not open a public issue for an unpatched vulnerability.

We will acknowledge receipt and keep you posted on triage and the fix. Since the image is public and
executes customer code, supply-chain reports are high priority.
