# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# Minimal Ubuntu 24.04 runner image: just runner-agent + base (no Node/Docker CLI).
# For workflows that need no toolchain — faster to pull, smaller surface.
# Base pinned by digest; bumped on weekly rebuild.
FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54

ARG RUNNER_VERSION=2.335.1
# SHA256 of the linux-x64 runner tarball (from release notes). Verify on bump. x64-specific.
ARG RUNNER_SHA256=4ef2f25285f0ae4477f1fe1e346db76d2f3ebf03824e2ddd1973a2819bf6c8cf
ARG TARGETARCH=amd64

ENV DEBIAN_FRONTEND=noninteractive \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN apt-get update \
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

USER runner

CMD ["/home/runner/run.sh"]
