# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
# Minimal Ubuntu 24.04 runner image: just runner-agent + base (no Node/Docker CLI).
# For workflows that need no toolchain — faster to pull, smaller surface.
# Base pinned by digest; bumped on weekly rebuild.
FROM ubuntu:24.04@sha256:008173c23f95b170204355c12626cb5a965d779a7e1283b09e9cffbb1bf33ca3

ARG RUNNER_VERSION=2.337.0
# SHA256 of the linux-x64 runner tarball (from release notes). Verify on bump. x64-specific.
ARG RUNNER_SHA256=70920811a4f8ad4328818682bca5c6469c1c942fab52448868071d0063816613
ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# A mirror mid-sync can serve an InRelease newer than its package indices ("File has unexpected
# size ... Mirror sync in progress?"). apt's per-file Acquire::Retries re-fetches the same stale file,
# so the whole update is retried after a pause instead. --error-on=any also turns network failures
# (a warning with exit 0 by default) into a retried error. COPY (not RUN) keeps the script body out of
# the layer history, which Dockle would otherwise read as a bare 'apt-get update'.
COPY --chmod=0755 <<'EOF' /usr/local/sbin/apt-get-update-retry
#!/bin/bash
set -euo pipefail
for attempt in 1 2 3 4 5; do
  apt-get update --error-on=any && exit 0
  [ "$attempt" -lt 5 ] || break
  echo "apt-get update failed (attempt ${attempt}/5), retrying in 20s" >&2
  sleep 20
done
exit 1
EOF

# hadolint ignore=DL3008
RUN apt-get-update-retry \
    && apt-get install -y --no-install-recommends ca-certificates curl git jq sudo tar \
    && rm -rf /var/lib/apt/lists/*

# UID pinned to 1001 (same as the official ARC runner image) — dind volume permissions rely on it.
RUN useradd -m -u 1001 -s /bin/bash runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner \
    && chmod 0440 /etc/sudoers.d/runner

WORKDIR /home/runner

# Tarball verified by SHA256; strip bundled npm/npx/corepack from the node runtimes (pull CVEs, runner does not need them).
RUN RUNNER_ARCH="${TARGETARCH/amd64/x64}" \
    && curl -fsSL "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" -o runner.tar.gz \
    && echo "${RUNNER_SHA256}  runner.tar.gz" | sha256sum -c - \
    && tar xzf runner.tar.gz \
    && rm runner.tar.gz \
    && ./bin/installdependencies.sh \
    && rm -rf /var/lib/apt/lists/* \
    && for d in /home/runner/externals/node*/; do \
         rm -rf "${d}lib/node_modules/npm" "${d}lib/node_modules/corepack" \
                "${d}bin/npm" "${d}bin/npx" "${d}bin/corepack"; \
       done \
    && chown -R runner:runner /home/runner

# Static OCI metadata; dynamic labels (created/revision/version) are added by CI (docker/metadata-action).
LABEL org.opencontainers.image.title="runner-ubuntu-24.04-minimal" \
      org.opencontainers.image.description="Minimal Ubuntu 24.04 GitHub Actions runner image for tempus.build (ARC gha-runner-scale-set): runner agent + base tools only" \
      org.opencontainers.image.source="https://github.com/tempusbuild/runner-images" \
      org.opencontainers.image.url="https://tempus.build" \
      org.opencontainers.image.vendor="tempus.build" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="docker.io/library/ubuntu:24.04"

USER 1001

CMD ["/home/runner/run.sh"]
