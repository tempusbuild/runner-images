# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# Ubuntu 24.04 runner image for ARC gha-runner-scale-set (label tempus-ubuntu-24.04-4core):
# runner-agent + base CI toolchain.
# Base pinned by digest; bump on weekly rebuild via `docker buildx imagetools inspect`.
FROM ubuntu:24.04@sha256:786a8b558f7be160c6c8c4a54f9a57274f3b4fb1491cf65146521ae77ff1dc54

ARG RUNNER_VERSION=2.335.1
# SHA256 of the linux-x64 runner tarball (from release notes); recompute on version bump. x64-only.
ARG RUNNER_SHA256=4ef2f25285f0ae4477f1fe1e346db76d2f3ebf03824e2ddd1973a2819bf6c8cf
ARG NODE_MAJOR=22
# Fresh npm: npm's bundled deps from NodeSource pull in CVEs.
ARG NPM_VERSION=11.17.0
ARG TARGETARCH=amd64

# Python toolcache (matches setup-python: same actions/python-versions builds, offline cache hit).
# Exact patches and their SHA256 are pinned (the manifest publishes no hashes) — verify on bump.
ARG PYTHON_310=3.10.20
ARG PYTHON_311=3.11.15
ARG PYTHON_312=3.12.13
ARG PYTHON_313=3.13.14
ARG PYTHON_314=3.14.6
ARG PYTHON_310_SHA256=4ebefe0bdcd96dabd2e8e37388a758ecf5cc9a7738ec2bc57d60bdfc1b9966f5
ARG PYTHON_311_SHA256=f9b44dbcda5044f5b687e3c30bd0a4eacaafb8c9ae828542f474050bf79235c9
ARG PYTHON_312_SHA256=ca90dadd4f33275e829935a948d77b7b51b91e8463fd84f40ac6deaa99e14726
ARG PYTHON_313_SHA256=c54b2ef814e8002782c04e8fec521dda72cad93f3d1a835cb65b49f769b38842
ARG PYTHON_314_SHA256=29dc7f3887a430fe7a0005fee4732b00be1bbed5bf21aa1e43f8d947eb1b9f61
# 3.10/3.11 bundle an old setuptools with vulnerable vendored copies (CVE-2026-23949/-24049) —
# upgrade to the fixed version rather than ignoring (3.12+ bundle no setuptools, PEP 632).
ARG SETUPTOOLS_VERSION=82.0.1

# Go toolcache (matches setup-go: offline cache hit, no runtime download per run). We bake only
# supported minors (Go patches only the last 2): patch-current 1.25/1.26. EOL minors (1.22-1.24)
# are deliberately not baked — EOL Go is unpatched and its stdlib CVEs are unfixable in the image;
# anyone needing them installs via setup-go from the network. SHA256 from go.dev/dl JSON
# (files[].sha256 field). Recompute on bump (go.dev/dl/?mode=json&include=all).
ARG GO_125=1.25.11
ARG GO_126=1.26.4
ARG GO_125_SHA256=34f14304e856893f4ba30c2cacfe93906e9de7915c5f6aaaf3a81cdccd7ba30b
ARG GO_126_SHA256=1153d3d50e0ac764b447adfe05c2bcf08e889d42a02e0fe0259bd47f6733ad7f

# Rust via pinned rustup-init (not `curl | sh`): tarball by URL + SHA256 from <url>.sha256.
# default profile = rustc+cargo+rust-std+rustfmt+clippy. Exact toolchain pin for reproducibility.
ARG RUSTUP_VERSION=1.29.0
ARG RUST_VERSION=1.95.0
ARG RUSTUP_SHA256=4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10

ENV DEBIAN_FRONTEND=noninteractive \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1 \
    ImageOS=ubuntu24 \
    ImageVersion=24.04 \
    RUNNER_TOOL_CACHE=/opt/hostedtoolcache \
    AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    # /home/runner/.local/bin: pipx target; /home/runner/go/bin: `go install` target;
    # /usr/local/go/bin: default system `go` (parity with GitHub-hosted runners).
    PATH=/home/runner/.local/bin:/home/runner/go/bin:/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# DL3008 (apt version pinning) is intentionally ignored on the Node/Docker/gh installs below: the
# image pulls fresh security patches (weekly rebuild), pinning every version is impractical.
COPY packages.txt /tmp/packages.txt
RUN apt-get update \
    && xargs -a /tmp/packages.txt apt-get install -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* /tmp/packages.txt

# Node.js via the NodeSource keyring repo (not `curl | bash`); npm upgraded to a pinned fresh version.
# hadolint ignore=DL3008
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /etc/apt/keyrings/nodesource.asc \
    && chmod a+r /etc/apt/keyrings/nodesource.asc \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "npm@${NPM_VERSION}" \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

# Docker CLI (the daemon is provided by the ARC dind sidecar). Repo key verified by fingerprint.
# hadolint ignore=DL3008
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && gpg --show-keys --with-colons /etc/apt/keyrings/docker.asc | grep -q 9DC858229FC7DD38854AE2D88D81803C0EBFCD88 \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu noble stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (workflows commonly call `gh`).
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli.gpg \
    && chmod a+r /etc/apt/keyrings/githubcli.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

# Unprivileged runner (+sudo for setup-* steps) and a toolcache writable by the runner user.
# UID pinned to 1001 (same as the official ARC runner image) — dind volume permissions rely on it.
# docker group pinned to gid 123 — the gid the ARC dind sidecar creates docker.sock with, so the
# runner user can reach the daemon socket instead of getting permission denied.
RUN useradd -m -u 1001 -s /bin/bash runner \
    && groupadd -g 123 docker \
    && usermod -aG sudo,docker runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/runner \
    && chmod 0440 /etc/sudoers.d/runner \
    && mkdir -p /opt/hostedtoolcache \
    && chown runner:runner /opt/hostedtoolcache

WORKDIR /home/runner

# Actions runner (TARGETARCH amd64 -> x64), tarball verified by SHA256. Strip bundled npm/npx/corepack
# from the node runtimes: the runner executes actions via `node`, its npm is unneeded and pulls HIGH
# CVEs; node20/node24 themselves are required (using: node20/node24). A fix rather than an ignore.
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

# Prebake the Python toolcache: tarball for the exact version from the manifest, SHA256 check, then
# the bundled setup.sh (installs into $AGENT_TOOLSDIRECTORY/Python/<v>/x64 + a .complete marker for
# the setup-python cache hit).
# DL3003: setup.sh uses relative paths, a per-version WORKDIR inside the loop is impractical.
# hadolint ignore=DL3003
RUN PY_ARCH="${TARGETARCH/amd64/x64}" \
    && declare -A PY_SHA=( \
         ["${PYTHON_310}"]="${PYTHON_310_SHA256}" \
         ["${PYTHON_311}"]="${PYTHON_311_SHA256}" \
         ["${PYTHON_312}"]="${PYTHON_312_SHA256}" \
         ["${PYTHON_313}"]="${PYTHON_313_SHA256}" \
         ["${PYTHON_314}"]="${PYTHON_314_SHA256}" \
       ) \
    && manifest="$(curl -fsSL https://raw.githubusercontent.com/actions/python-versions/main/versions-manifest.json)" \
    && for v in "${PYTHON_310}" "${PYTHON_311}" "${PYTHON_312}" "${PYTHON_313}" "${PYTHON_314}"; do \
         echo "== prebake Python ${v} ==" \
         && url="$(printf '%s' "${manifest}" | PY_V="${v}" PY_A="${PY_ARCH}" python3 -c 'import json,os,sys; d=json.load(sys.stdin); print(next(f["download_url"] for r in d if r["version"]==os.environ["PY_V"] for f in r["files"] if f["platform"]=="linux" and f["arch"]==os.environ["PY_A"] and f["platform_version"]=="24.04"))')" \
         && work="/tmp/py-${v}" \
         && mkdir -p "${work}" \
         && curl -fsSL "${url}" -o "/tmp/py-${v}.tar.gz" \
         && echo "${PY_SHA[${v}]}  /tmp/py-${v}.tar.gz" | sha256sum -c - \
         && tar xzf "/tmp/py-${v}.tar.gz" -C "${work}" \
         && ( cd "${work}" && bash ./setup.sh ) \
         && py="/opt/hostedtoolcache/Python/${v}/x64/bin/python3" \
         && if PIP_ROOT_USER_ACTION=ignore "${py}" -m pip show setuptools >/dev/null 2>&1; then \
              PIP_ROOT_USER_ACTION=ignore "${py}" -m pip install --quiet --no-warn-script-location \
                --upgrade "setuptools==${SETUPTOOLS_VERSION}"; \
            fi \
         && rm -rf "${work}" "/tmp/py-${v}.tar.gz" || exit 1; \
       done \
    && rm -rf /tmp/* \
    && find /opt/hostedtoolcache/Python -depth -type d -name __pycache__ -exec rm -rf {} + \
    && chown -R runner:runner /opt/hostedtoolcache

# Prebake the Go toolcache (matches setup-go): go.dev tarball for the exact version + SHA256, the
# contents of go/ go into $RUNNER_TOOL_CACHE/go/<v>/x64 + a <v>/x64.complete marker (setup-go layout
# for the cache hit). The newest version is also symlinked to /usr/local/go and put on PATH as the
# default `go` (parity with ubuntu-latest, which exposes its newest cached Go) — so tools that assume
# a system Go (e.g. pre-commit golang hooks) work without downloading a toolchain.
RUN GO_ARCH="${TARGETARCH/amd64/x64}" \
    && declare -A GO_SHA=( \
         ["${GO_125}"]="${GO_125_SHA256}" \
         ["${GO_126}"]="${GO_126_SHA256}" \
       ) \
    && for v in "${GO_125}" "${GO_126}"; do \
         echo "== prebake Go ${v} ==" \
         && curl -fsSL "https://go.dev/dl/go${v}.linux-amd64.tar.gz" -o "/tmp/go-${v}.tar.gz" \
         && echo "${GO_SHA[${v}]}  /tmp/go-${v}.tar.gz" | sha256sum -c - \
         && dest="/opt/hostedtoolcache/go/${v}/${GO_ARCH}" \
         && mkdir -p "${dest}" \
         && tar xzf "/tmp/go-${v}.tar.gz" -C "${dest}" --strip-components=1 \
         && touch "/opt/hostedtoolcache/go/${v}/${GO_ARCH}.complete" \
         && rm -f "/tmp/go-${v}.tar.gz" || exit 1; \
       done \
    && rm -rf /tmp/* \
    && ln -sfn "/opt/hostedtoolcache/go/${GO_126}/x64" /usr/local/go \
    && chown -R runner:runner /opt/hostedtoolcache/go

# Rust via pinned rustup-init (not `curl | sh`): tarball + SHA256, then an offline install of the
# exact toolchain. The default profile installs rustc+cargo+rust-std+rustfmt+clippy. RUSTUP/CARGO_HOME
# are set in ENV; we hand ownership to runner (cargo writes to CARGO_HOME when building native crates).
RUN curl -fsSL "https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/x86_64-unknown-linux-gnu/rustup-init" -o /tmp/rustup-init \
    && echo "${RUSTUP_SHA256}  /tmp/rustup-init" | sha256sum -c - \
    && chmod +x /tmp/rustup-init \
    && /tmp/rustup-init -y --no-modify-path --profile default --default-toolchain "${RUST_VERSION}" \
    && rm -f /tmp/rustup-init \
    && chown -R runner:runner /usr/local/rustup /usr/local/cargo

# Static OCI metadata; dynamic labels (created/revision/version) are added by CI (docker/metadata-action).
LABEL org.opencontainers.image.title="runner-ubuntu-24.04" \
      org.opencontainers.image.description="Ubuntu 24.04 GitHub Actions runner image for tempus.build (ARC gha-runner-scale-set): runner agent + Node, Python/Go toolcache, Rust, Docker CLI, gh" \
      org.opencontainers.image.source="https://github.com/tempusbuild/runner-images" \
      org.opencontainers.image.documentation="https://github.com/tempusbuild/runner-images/blob/main/ubuntu-24.04/README.md" \
      org.opencontainers.image.url="https://tempus.build" \
      org.opencontainers.image.vendor="tempus.build" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="docker.io/library/ubuntu:24.04"

USER runner

# ARC sets the command itself; CMD is just a default for manual runs.
CMD ["/home/runner/run.sh"]
