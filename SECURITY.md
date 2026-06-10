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

### 2. SLSA provenance attestation

Provenance is attached by BuildKit (`provenance: mode=max`) as an **in-toto attestation — an OCI
referrer next to the digest** (targets SLSA Build L3), not as a separate cosign signature. Inspect it
with `docker buildx imagetools` (requires docker buildx):

```sh
docker buildx imagetools inspect "${IMAGE}@${DIGEST}" --format '{{ json .Provenance }}' | jq .
```

The cryptographic trust anchor is the cosign signature from step 1: it covers the image by
`@${DIGEST}`, and provenance and SBOM are attached to the same digest. (cosign-signed attestations on
top are on the roadmap; `verify-attestation` does not apply to them yet.)

### 3. SBOM (SPDX)

The SBOM (SPDX) is also attached by BuildKit (`sbom: true`) as an attestation to the digest. Inspect:

```sh
docker buildx imagetools inspect "${IMAGE}@${DIGEST}" --format '{{ json .SBOM }}' | jq .
```

## Vulnerability (CVE) policy

- **Build gate**: every push to `main` is scanned by `trivy` against the published digest with
  `--severity HIGH,CRITICAL`. An unhandled fixable HIGH/CRITICAL **fails** the build, which means the
  image is not signed and is not admitted to run by the consumer's admission policy.
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

The base image is pinned by `sha256:` digest, the toolchain (runner, Node, npm, Python and Go
toolcache, Rust/rustup) by exact versions with SHA256-verified downloads, and all GitHub Actions
by commit SHA. Pin currency is maintained by:

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
