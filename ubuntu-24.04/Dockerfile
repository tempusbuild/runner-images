# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
# Ubuntu 24.04 runner image for ARC gha-runner-scale-set (label tempus-ubuntu-24.04-4core):
# runner-agent + base CI toolchain.
# Base pinned by digest; bump on weekly rebuild via `docker buildx imagetools inspect`.
FROM ubuntu:24.04@sha256:33ceb71981b602c1a7443a53469e4dba065f7503eab3078a2d7a57a2ab987517

ARG RUNNER_VERSION=2.336.0
# SHA256 of the linux-x64 runner tarball (from release notes); recompute on version bump. x64-only.
ARG RUNNER_SHA256=04cf0be1aff4c3ec3554466c39124ca250e3effd8873bb7e8d68535aa9505d5d
# Action archive cache (parity with ubuntu-latest install-actions-cache.sh): prebundled tarballs of
# common actions the runner resolves offline. Pinned tarball + SHA256 (recompute on bump). ~273 MB.
ARG ACTION_ARCHIVE_CACHE_VERSION=1.0.53
ARG ACTION_ARCHIVE_CACHE_SHA256=af0f07f79b208f6ab409f99207f21bfe085db006ada0f4ca41c4aa66bbafb127
ARG NODE_MAJOR=22
# Fresh npm: npm's bundled deps from NodeSource pull in CVEs.
ARG NPM_VERSION=11.19.0
ARG TARGETARCH=amd64

# Python toolcache (matches setup-python: same actions/python-versions builds, offline cache hit).
# Exact patches and their SHA256 are pinned (the manifest publishes no hashes) — verify on bump.
ARG PYTHON_310=3.10.21
ARG PYTHON_311=3.11.16
ARG PYTHON_312=3.12.14
ARG PYTHON_313=3.13.15
ARG PYTHON_314=3.14.7
ARG PYTHON_310_SHA256=3ae6d012a8c2cb41bf7a2957a99f1d6d329a264a727053e71edb76b1cfda6f52
ARG PYTHON_311_SHA256=07b61e35f30861939ff95314297921de8f57cd48f85bb18d777651b3ea45f2ee
ARG PYTHON_312_SHA256=5a03168292516f6dd6dcf630f4bf5369b108abd7c699a7e1db37f1e622257fff
ARG PYTHON_313_SHA256=4e544242f8a4ef647a6f511b67f9b00eefc9ef366644e3c40a27a6eff709ae2b
ARG PYTHON_314_SHA256=76d5ddab6d2dd89a39c06220f6efeda486a48ed481eae97bfc596c74ac3623db
# 3.10/3.11 bundle an old setuptools with vulnerable vendored copies (CVE-2026-23949/-24049) —
# upgrade to the fixed version rather than ignoring (3.12+ bundle no setuptools, PEP 632).
ARG SETUPTOOLS_VERSION=83.0.0

# Go toolcache (matches setup-go: offline cache hit, no runtime download per run). We bake only
# supported minors (Go patches only the last 2): patch-current 1.25/1.26. EOL minors (1.22-1.24)
# are deliberately not baked — EOL Go is unpatched and its stdlib CVEs are unfixable in the image;
# anyone needing them installs via setup-go from the network. SHA256 from go.dev/dl JSON
# (files[].sha256 field). Recompute on bump (go.dev/dl/?mode=json&include=all).
ARG GO_125=1.25.14
ARG GO_126=1.26.7
ARG GO_125_SHA256=a21ae5633a269bcd7e90cf767e48225633795e99d831742cbf3397064fee7712
ARG GO_126_SHA256=ffb5f8de10c62550dfddab66b36b57030721e0a44a3218e9e1181d7b59f121ca

# Node.js toolcache (matches setup-node: offline cache hit). Newest patch of each cached major
# (22, 24); SHA256 from nodejs.org SHASUMS256.txt. NODE_MAJOR above is the system Node (apt).
ARG NODE_TC_22=22.23.2
ARG NODE_TC_24=24.19.0
ARG NODE_TC_22_SHA256=b294a556e639d64338823920e5866c21c02741742d2e1529ee1a225c1ec9252a
ARG NODE_TC_24_SHA256=f625d97cd707df4ff96254916fbc5ff014f09c09effe5a1e0ca8f6d41a8789d4

# Ruby toolcache (matches ruby/setup-ruby): prebuilt ruby-builder tarballs for ubuntu-24.04.
ARG RUBY_32=3.2.11
ARG RUBY_33=3.3.12
ARG RUBY_34=3.4.10
ARG RUBY_40=4.0.6
ARG RUBY_32_SHA256=1b89cf6de50def9e15701f369e526c4fbfb79abf1f7576b01eec695291d46299
ARG RUBY_33_SHA256=3fa2d6242e105a65f694fae86e9f68d9617c827fc14d1fcf611035b9ae2cbdb8
ARG RUBY_34_SHA256=2a16c29b57203754da3fcb0c25d9dd7f7340e858f46f835bef32feef348ebc93
ARG RUBY_40_SHA256=a65a82adf40df54d9bfcab4c61055f01bccff14a52c5b7c0c2cfecc1e9895fae

# PyPy toolcache (matches actions/setup-pypy): dir named by the Python-compat version; PyPy build in
# the filename. Tarball symlinks (python3 -> pypy3) are already present. Bumped manually (the
# python<->pypy version pairing has no clean Renovate datasource).
ARG PYPY_39=3.9.19
ARG PYPY_310=3.10.16
ARG PYPY_311=3.11.15
ARG PYPY_39_FILE=pypy3.9-v7.3.16-linux64
ARG PYPY_310_FILE=pypy3.10-v7.3.19-linux64
ARG PYPY_311_FILE=pypy3.11-v7.3.23-linux64
ARG PYPY_39_SHA256=16f9c5b808c848516e742986e826b833cdbeda09ad8764e8704595adbe791b23
ARG PYPY_310_SHA256=c73ac2cc2380ac9227fd297482bf2a3e17a80618ba46db7544d535515321ec1e
ARG PYPY_311_SHA256=16f9f56e82d1f4ec95a324c1a8cacfd78afc7f0656c0a809a18725ef4391453a

# Rust via pinned rustup-init (not `curl | sh`): tarball by URL + SHA256 from <url>.sha256.
# default profile = rustc+cargo+rust-std+rustfmt+clippy. Exact toolchain pin for reproducibility.
ARG RUSTUP_VERSION=1.29.0
ARG RUST_VERSION=1.98.0
ARG RUSTUP_SHA256=4acc9acc76d5079515b46346a485974457b5a79893cfb01112423c89aeb5aa10

# yq (mikefarah) pinned binary + SHA256 — parity with ubuntu-latest (jq comes from apt; yq does not).
ARG YQ_VERSION=4.53.6
ARG YQ_SHA256=c5f056448f973ae7d39b5401949648a78f2dc1947d6a8eb65be60d5c504b9385

# cmake / git-lfs pinned binaries + SHA256 — version parity with ubuntu-latest (apt ships older).
# Two cmake majors like ubuntu-latest: 3.31 is the default `cmake`, 4.x is exposed as `cmake4`.
ARG CMAKE_VERSION=3.31.12
ARG CMAKE_SHA256=0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c
ARG CMAKE4_VERSION=4.4.2
ARG CMAKE4_SHA256=3ada9a3f5d8a85413579bdd0ea6aa8e8da86efdd6d15c91a1afa517f2021956c
ARG GITLFS_VERSION=3.7.1
ARG GITLFS_SHA256=1c0b6ee5200ca708c5cebebb18fdeb0e1c98f1af5c1a9cba205a4c0ab5a5ec08
# pipx pinned via pip (Ubuntu's apt pipx lags behind ubuntu-latest).
ARG PIPX_VERSION=1.16.7

# zstd built from source + SHA256 (apt zstd lags; upstream ships no prebuilt linux binary).
ARG ZSTD_VERSION=1.5.7
ARG ZSTD_SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3

# kubectl / Helm pinned binaries + SHA256. Helm stays on 3.x (ubuntu-latest parity), not v4 (major).
ARG KUBECTL_VERSION=1.36.4
ARG KUBECTL_SHA256=8b8f088da2dab964f853b38464033b1be15ede2839eca751482357c45abdd05a
ARG HELM_VERSION=3.21.4
ARG HELM_SHA256=61f88ab166748cb19604d7884cb100ae9ccb13804ddeb98e08af167eacbb6a14

# AWS CLI v2 pinned installer + SHA256. Azure CLI and Google Cloud CLI come from vendor apt repos.
ARG AWSCLI_VERSION=2.36.30
ARG AWSCLI_SHA256=a0a4f1dd3fe547f7be0569d127b3adb77646e232ef69820aa79edf4f7ea2a5a2
# AWS Session Manager plugin (.deb from AWS S3) — pinned version + SHA256 of the deb.
ARG SSM_PLUGIN_VERSION=1.2.835.0
ARG SSM_PLUGIN_SHA256=7c6dcad12518571cc7959a713e6a8ae1bdf6ed66fd9bee37dc189e39ca58ae03

# Browser drivers. geckodriver + Selenium server are pinned (SHA256); chromedriver/msedgedriver
# float to match the apt browser version (fetched by version at build, like the browsers themselves).
ARG GECKODRIVER_VERSION=0.37.1
ARG GECKODRIVER_SHA256=e815130ea95983e162ae91843b48d3a3ce991735635fce83a647afde21e09f7e
ARG SELENIUM_VERSION=4.47.0
ARG SELENIUM_SHA256=045002e16ba2530f1f47ff601323d2020390902e76f9bd20db02fc90e6f8ad75

# DevOps tools — pinned binaries + SHA256 (Newman/Parcel via npm; Ansible/yamllint via pipx;
# Fastlane via gem; Podman/Buildah/Skopeo from apt).
ARG BAZELISK_VERSION=1.29.0
ARG BAZELISK_SHA256=5a408715e932c0250d28bd84555f12edbf70117de42f9181691c736eacc4a992
ARG KIND_VERSION=0.32.0
ARG KIND_SHA256=50030de23cf40a18505f20426f6a8506bedf13c6e509244bd1fa9463721b0f54
ARG MINIKUBE_VERSION=1.38.1
ARG MINIKUBE_SHA256=099477eaf248bcb5bcea8ce78a2898e93ac01461c35189da1848c3de82ecd22e
ARG KUSTOMIZE_VERSION=5.8.1
ARG KUSTOMIZE_SHA256=029a7f0f4e1932c52a0476cf02a0fd855c0bb85694b82c338fc648dcb53a819d
ARG PACKER_VERSION=1.16.0
ARG PACKER_SHA256=5edcd14ab59b535040c512dbecd6ec9ef976a000b073c19d93e4c431c948581e
ARG BICEP_VERSION=0.46.1
ARG BICEP_SHA256=3e011d629ea4311b7a7dd8f0040ab2b1a072ea4ff5d02cb75e0e55a9a6703fb9
ARG AZCOPY_VERSION=10.32.7
ARG AZCOPY_SHA256=771dabec5bd8034223010d6f5186956203649e1013ed1d9e6b533fc09ed4a9ee
ARG CODEQL_VERSION=2.26.3
ARG CODEQL_SHA256=77e5be1b550d66662e600e795b6cf2ea1729e853e3dc79e02594f767039d2a29
ARG NEWMAN_VERSION=6.2.2
ARG PARCEL_VERSION=2.16.4
ARG LERNA_VERSION=10.0.1
ARG TYPESCRIPT_VERSION=6.0.3
ARG WEBPACK_VERSION=5.109.2
ARG WEBPACK_CLI_VERSION=7.2.2
ARG GRUNT_VERSION=1.6.3
ARG GULP_VERSION=5.0.1
ARG FASTLANE_VERSION=2.238.0
ARG MULTIJSON_VERSION=1.21.1

# JVM project-management tools — Maven/Gradle pinned (Ant is from apt).
ARG MAVEN_VERSION=3.9.16
ARG MAVEN_SHA512=831a8591fe20c8243b1dbe7d71e3244f31d1665b0804b2e825e38cbbe5ce0cafb8338851f90780735568773e0a6cd07bbec107cda0b896b008b861075358b6f6
ARG GRADLE_VERSION=9.7.1
ARG GRADLE_SHA256=acd53f1edaf02f1a8ff99879f8a34b302661a057d9b063ae9e35b552f804d20a

# Misc tools: Pulumi (pinned tarball), nvm (git tag), n (npm); Composer + PHPUnit (pinned phars).
ARG PULUMI_VERSION=3.259.0
ARG PULUMI_SHA256=94ba357acac23d01474084c4b00098dc0f7bc70ce13f34c777459254a5f718e5
# OpenTofu (MPL-2.0, OSS) — Terraform-compatible IaC; ubuntu-latest dropped Terraform (BSL), so this
# is a deliberate OSS extra beyond strict parity.
ARG OPENTOFU_VERSION=1.12.6
ARG OPENTOFU_SHA256=5dc43da4f750f33873dc25e94587128709e819e544b7be9016b255316153c3a8
ARG NVM_VERSION=0.40.7
ARG N_VERSION=10.2.0
ARG COMPOSER_VERSION=2.10.2
ARG COMPOSER_SHA256=5ee7125f8a30a34d246cefdc0bc85b8a783b28f2aec968994118512350d28027
ARG PHPUNIT_VERSION=8.5.54
ARG PHPUNIT_SHA256=26b4ad495b513f82f489ed754ee912cc5cbb7125c469a686ae23e793e93bac6d

# Language runtimes (Julia/Kotlin pinned binaries; PowerShell tarball; Haskell via ghcup).
ARG JULIA_VERSION=1.12.7
ARG JULIA_SHA256=4e7e9e776634d24835250de67cde39b0d4af15bc432eb20697e6be6c28ea69e8
ARG KOTLIN_VERSION=2.4.10
ARG KOTLIN_SHA256=473dd66c7a3ef4b182065b3da670466c1bf2773a9dbb0ed8b33a39fe9d4f876d
ARG POWERSHELL_VERSION=7.6.5
ARG POWERSHELL_SHA256=b34ab3b19acac1d3d4d0d3cfdb02acf62f457b0b6a962ff008132033f7566844
ARG GHCUP_VERSION=0.2.6.2
ARG GHCUP_SHA256=9ed5da5449b48043a0d17e767c05d2ef585e25a639bb934329496c6d2fad9cf8
# ghc/cabal/stack are installed through ghcup, so their versions are bounded by ghcup's
# metadata catalog, not upstream GitHub releases — bump only to a ghcup-available version
# (verified by the build). No Renovate manager for these; they track ubuntu-latest's pins.
ARG GHC_VERSION=9.14.1
ARG CABAL_VERSION=3.18.1.0
ARG STACK_VERSION=3.11.1
ARG SWIFT_VERSION=6.3.3
ARG SWIFT_SHA256=da8272a5fddccd65b1529ed0e52e04526e2eadd4237d58d6220efeb973c6cd19

# dotnet-install.sh pinned to a commit + SHA256 (not the rolling dot.net/v1 script); it drives the
# version-pinned SDK installs below. Bump commit + recompute SHA256 together (manual).
ARG DOTNET_INSTALL_COMMIT=6f559c420847ded38591392dafe785ad511f39f5
ARG DOTNET_INSTALL_SHA256=082f7685e156738a1b2e2ed8381a621870d4ce8e8c59278034556f05c186eb2e

# Android SDK (cmdline-tools pinned + SHA256); NDK versions match the ANDROID_NDK* env below.
# Manually bumped (no clean Renovate datasource): cmdline-tools build id, NDK/build-tools/platform.
ARG ANDROID_CMDLINE_VERSION=16111833
ARG ANDROID_CMDLINE_SHA256=0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8
ARG ANDROID_NDK_VERSION=27.3.13750724
ARG ANDROID_NDK_28_VERSION=28.2.13676358
ARG ANDROID_NDK_LATEST_VERSION=29.0.14206865
# Full Android matrix (parity with ubuntu-latest): every platforms/build-tools >= the minimum is
# installed dynamically via sdkmanager (mirrors actions/runner-images install-android-sdk.sh), plus
# the m2repository/play-services extras and the sdkmanager CMake builds.
ARG ANDROID_PLATFORM_MIN=34
ARG ANDROID_BUILD_TOOLS_MIN=34.0.0
ARG ANDROID_CMAKE1_VERSION=3.31.5
ARG ANDROID_CMAKE2_VERSION=4.1.2

# Environment managers + AWS SAM. Homebrew/vcpkg are pinned by git tag; Miniconda/SAM by SHA256.
# MINICONDA_VERSION is bumped manually (no Renovate datasource for its pyXXX_NN.N.N-N installer name).
ARG HOMEBREW_VERSION=6.0.19
ARG VCPKG_VERSION=2026.07.29
ARG MINICONDA_VERSION=py314_26.5.3-2
ARG MINICONDA_SHA256=80bc27f13c4de90f10e387aa45e864de4f0860692c1221aef5900009a2b55302
ARG SAM_VERSION=1.165.0
ARG SAM_SHA256=e95678af994e5c1f12b59314de7bdee644be7246df1e85c4a4f2b48448d8569f

ENV DEBIAN_FRONTEND=noninteractive \
    RUNNER_MANUALLY_TRAP_SIG=1 \
    ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT=1 \
    ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE=/opt/actionarchivecache \
    ImageOS=ubuntu24 \
    ImageVersion=24.04 \
    RUNNER_TOOL_CACHE=/opt/hostedtoolcache \
    AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache \
    RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    CONDA=/usr/share/miniconda \
    VCPKG_INSTALLATION_ROOT=/usr/local/share/vcpkg \
    CHROMEWEBDRIVER=/usr/local/share/chromedriver-linux64 \
    EDGEWEBDRIVER=/usr/local/share/edge_driver \
    GECKOWEBDRIVER=/usr/local/share/gecko_driver \
    SELENIUM_JAR_PATH=/usr/share/java/selenium-server.jar \
    NVM_DIR=/usr/local/nvm \
    ANDROID_HOME=/usr/local/lib/android/sdk \
    ANDROID_SDK_ROOT=/usr/local/lib/android/sdk \
    ANDROID_NDK=/usr/local/lib/android/sdk/ndk/27.3.13750724 \
    ANDROID_NDK_HOME=/usr/local/lib/android/sdk/ndk/27.3.13750724 \
    ANDROID_NDK_ROOT=/usr/local/lib/android/sdk/ndk/27.3.13750724 \
    ANDROID_NDK_LATEST_HOME=/usr/local/lib/android/sdk/ndk/29.0.14206865 \
    # /home/runner/.local/bin: pipx target; /home/runner/go/bin: `go install` target; /usr/local/go/bin:
    # default `go`; /home/linuxbrew/...: Homebrew; /opt/pulumi: Pulumi (parity with GitHub-hosted).
    PATH=/home/runner/.local/bin:/home/runner/go/bin:/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/.ghcup/bin:/home/linuxbrew/.linuxbrew/bin:/opt/pulumi:/opt/swift/usr/bin:/usr/local/lib/android/sdk/cmdline-tools/latest/bin:/usr/local/lib/android/sdk/platform-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# DL3008 (apt version pinning) is intentionally ignored on the Node/Docker/gh installs below: the
# image pulls fresh security patches (weekly rebuild), pinning every version is impractical.
COPY packages.txt /tmp/packages.txt
RUN apt-get update \
    && xargs -a /tmp/packages.txt apt-get install -y --no-install-recommends \
    && phpdismod -v 8.3 pcov \
    && rm -rf /var/lib/apt/lists/* /tmp/packages.txt

# Newer Git from the maintainers' PPA (Ubuntu ships an older point release) — version parity.
# Key fetched by fingerprint into a keyring (retried) instead of `add-apt-repository`, whose
# single-shot Launchpad key lookup flakes (GPGKeyTemporarilyNotFoundError) and breaks the build.
# hadolint ignore=DL3008
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL --retry 5 --retry-all-errors "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF911AB184317630C59970973E363C90F8F1B6217" \
       | gpg --dearmor -o /etc/apt/keyrings/git-core-ppa.gpg \
    && chmod a+r /etc/apt/keyrings/git-core-ppa.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/git-core-ppa.gpg] https://ppa.launchpadcontent.net/git-core/ppa/ubuntu noble main" \
       > /etc/apt/sources.list.d/git-core.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

# pipx pinned via pip (apt pipx lags). --break-system-packages: install into the system interpreter
# on PEP 668; pipx then isolates every app it installs into its own venvs.
RUN python3 -m pip install --break-system-packages --no-cache-dir "pipx==${PIPX_VERSION}"

# Node.js via the NodeSource keyring repo (not `curl | bash`); npm upgraded to a pinned fresh version.
# hadolint ignore=DL3008
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /etc/apt/keyrings/nodesource.asc \
    && chmod a+r /etc/apt/keyrings/nodesource.asc \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "npm@${NPM_VERSION}" \
    && corepack enable \
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

RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" -o /usr/local/bin/yq \
    && echo "${YQ_SHA256}  /usr/local/bin/yq" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/yq

RUN curl -fsSL "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" -o /tmp/cmake.tar.gz \
    && echo "${CMAKE_SHA256}  /tmp/cmake.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/cmake \
    && tar -C /opt/cmake --strip-components=1 -xzf /tmp/cmake.tar.gz \
    && ln -sf /opt/cmake/bin/* /usr/local/bin/ \
    && curl -fsSL "https://github.com/Kitware/CMake/releases/download/v${CMAKE4_VERSION}/cmake-${CMAKE4_VERSION}-linux-x86_64.tar.gz" -o /tmp/cmake4.tar.gz \
    && echo "${CMAKE4_SHA256}  /tmp/cmake4.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/cmake-4.x \
    && tar -C /opt/cmake-4.x --strip-components=1 -xzf /tmp/cmake4.tar.gz \
    && ln -sf /opt/cmake-4.x/bin/cmake /usr/local/bin/cmake4 \
    && rm -f /tmp/cmake.tar.gz /tmp/cmake4.tar.gz

RUN curl -fsSL "https://github.com/git-lfs/git-lfs/releases/download/v${GITLFS_VERSION}/git-lfs-linux-amd64-v${GITLFS_VERSION}.tar.gz" -o /tmp/git-lfs.tar.gz \
    && echo "${GITLFS_SHA256}  /tmp/git-lfs.tar.gz" | sha256sum -c - \
    && tar -C /tmp -xzf /tmp/git-lfs.tar.gz \
    && install -m 0755 "/tmp/git-lfs-${GITLFS_VERSION}/git-lfs" /usr/local/bin/git-lfs \
    && git-lfs install --system \
    && rm -rf /tmp/git-lfs.tar.gz "/tmp/git-lfs-${GITLFS_VERSION}"

# zstd from source (newer than apt; the binary is what actions/cache invokes).
RUN curl -fsSL "https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz" -o /tmp/zstd.tar.gz \
    && echo "${ZSTD_SHA256}  /tmp/zstd.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/zstd.tar.gz -C /tmp \
    && make -C "/tmp/zstd-${ZSTD_VERSION}/programs" -j"$(nproc)" zstd \
    && install -m 0755 "/tmp/zstd-${ZSTD_VERSION}/programs/zstd" /usr/local/bin/zstd \
    && rm -rf /tmp/zstd.tar.gz "/tmp/zstd-${ZSTD_VERSION}"

RUN curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
    && echo "${KUBECTL_SHA256}  /usr/local/bin/kubectl" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/kubectl \
    && curl -fsSL "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" -o /tmp/helm.tar.gz \
    && echo "${HELM_SHA256}  /tmp/helm.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/helm.tar.gz -C /tmp \
    && install -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm \
    && rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip" -o /tmp/awscliv2.zip \
    && echo "${AWSCLI_SHA256}  /tmp/awscliv2.zip" | sha256sum -c - \
    && unzip -q /tmp/awscliv2.zip -d /tmp \
    && /tmp/aws/install \
    && curl -fsSL "https://s3.amazonaws.com/session-manager-downloads/plugin/${SSM_PLUGIN_VERSION}/ubuntu_64bit/session-manager-plugin.deb" -o /tmp/ssm.deb \
    && echo "${SSM_PLUGIN_SHA256}  /tmp/ssm.deb" | sha256sum -c - \
    && dpkg -i /tmp/ssm.deb \
    && rm -rf /tmp/awscliv2.zip /tmp/aws /tmp/ssm.deb

# Azure CLI from the Microsoft apt repo, + the azure-devops extension into a shared extension dir
# (AZURE_EXTENSION_DIR persists to runtime, world-readable, so the runner user resolves `az devops`)
# — matches ubuntu-latest's install-azure-devops-cli.sh.
ENV AZURE_EXTENSION_DIR=/opt/az/azcliextensions
# hadolint ignore=DL3008
RUN curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /etc/apt/keyrings/microsoft.gpg \
    && chmod a+r /etc/apt/keyrings/microsoft.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ noble main" \
       > /etc/apt/sources.list.d/azure-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends azure-cli \
    && mkdir -p "${AZURE_EXTENSION_DIR}" \
    && az extension add -n azure-devops \
    && rm -rf /var/lib/apt/lists/*

# Google Cloud CLI from the Google apt repo.
# hadolint ignore=DL3008
RUN curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /etc/apt/keyrings/cloud.google.gpg \
    && chmod a+r /etc/apt/keyrings/cloud.google.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
       > /etc/apt/sources.list.d/google-cloud-sdk.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Eclipse Temurin JDKs 8/11/17/21/25 (matching ubuntu-latest) from the Adoptium apt repo; default 17.
# hadolint ignore=DL3008
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg \
    && chmod a+r /etc/apt/keyrings/adoptium.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb noble main" \
       > /etc/apt/sources.list.d/adoptium.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends temurin-8-jdk temurin-11-jdk temurin-17-jdk temurin-21-jdk temurin-25-jdk \
    && update-alternatives --set java /usr/lib/jvm/temurin-17-jdk-amd64/bin/java \
    && update-alternatives --set javac /usr/lib/jvm/temurin-17-jdk-amd64/bin/javac \
    && rm -rf /var/lib/apt/lists/*
ENV JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64 \
    JAVA_HOME_8_X64=/usr/lib/jvm/temurin-8-jdk-amd64 \
    JAVA_HOME_11_X64=/usr/lib/jvm/temurin-11-jdk-amd64 \
    JAVA_HOME_17_X64=/usr/lib/jvm/temurin-17-jdk-amd64 \
    JAVA_HOME_21_X64=/usr/lib/jvm/temurin-21-jdk-amd64 \
    JAVA_HOME_25_X64=/usr/lib/jvm/temurin-25-jdk-amd64

# Databases: PostgreSQL 16 (PGDG repo) + MySQL 8.0 (Ubuntu) — clients and servers (parity).
# hadolint ignore=DL3008
RUN curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg \
    && chmod a+r /etc/apt/keyrings/pgdg.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
       > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends postgresql-16 postgresql-client-16 mysql-server mysql-client \
    && rm -rf /var/lib/apt/lists/*

# Google Chrome + matching ChromeDriver (Chrome for Testing). Chrome floats to latest stable (apt);
# the driver is fetched to match the installed full version.
# hadolint ignore=DL3008
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && chmod a+r /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && CHROME_VER="$(google-chrome-stable --version | grep -oE '[0-9]+(\.[0-9]+){3}')" \
    && curl -fsSL "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VER}/linux64/chromedriver-linux64.zip" -o /tmp/chromedriver.zip \
    && unzip -q /tmp/chromedriver.zip -d /tmp \
    && mkdir -p /usr/local/share/chromedriver-linux64 \
    && install -m 0755 /tmp/chromedriver-linux64/chromedriver /usr/local/share/chromedriver-linux64/chromedriver \
    && ln -s /usr/local/share/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64 /var/lib/apt/lists/*

# Microsoft Edge + matching msedgedriver (reuses the Microsoft keyring from the Azure CLI step).
# hadolint ignore=DL3008
RUN echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" \
       > /etc/apt/sources.list.d/microsoft-edge.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends microsoft-edge-stable \
    && EDGE_VER="$(microsoft-edge-stable --version | grep -oE '[0-9]+(\.[0-9]+){3}')" \
    && curl -fsSL "https://msedgedriver.microsoft.com/${EDGE_VER}/edgedriver_linux64.zip" -o /tmp/edgedriver.zip \
    && unzip -q /tmp/edgedriver.zip -d /tmp/edgedriver \
    && mkdir -p /usr/local/share/edge_driver \
    && install -m 0755 /tmp/edgedriver/msedgedriver /usr/local/share/edge_driver/msedgedriver \
    && ln -s /usr/local/share/edge_driver/msedgedriver /usr/local/bin/msedgedriver \
    && rm -rf /tmp/edgedriver.zip /tmp/edgedriver /var/lib/apt/lists/*

# Firefox from the Mozilla apt repo (not the Ubuntu snap transitional package), pinned above it,
# plus pinned geckodriver (SHA256).
# hadolint ignore=DL3008
RUN curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/packages.mozilla.org.asc \
    && chmod a+r /etc/apt/keyrings/packages.mozilla.org.asc \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
       > /etc/apt/sources.list.d/mozilla.list \
    && printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla \
    && apt-get update \
    && apt-get install -y --no-install-recommends firefox \
    && curl -fsSL "https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-linux64.tar.gz" -o /tmp/geckodriver.tar.gz \
    && echo "${GECKODRIVER_SHA256}  /tmp/geckodriver.tar.gz" | sha256sum -c - \
    && mkdir -p /usr/local/share/gecko_driver \
    && tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/share/gecko_driver geckodriver \
    && chmod 0755 /usr/local/share/gecko_driver/geckodriver \
    && ln -s /usr/local/share/gecko_driver/geckodriver /usr/local/bin/geckodriver \
    && rm -rf /tmp/geckodriver.tar.gz /var/lib/apt/lists/*

RUN mkdir -p /usr/share/java \
    && curl -fsSL "https://github.com/SeleniumHQ/selenium/releases/download/selenium-${SELENIUM_VERSION}/selenium-server-${SELENIUM_VERSION}.jar" -o /usr/share/java/selenium-server.jar \
    && echo "${SELENIUM_SHA256}  /usr/share/java/selenium-server.jar" | sha256sum -c - \
    && printf '#!/usr/bin/env bash\nexec java -jar /usr/share/java/selenium-server.jar "$@"\n' > /usr/local/bin/selenium-server \
    && chmod 0755 /usr/local/bin/selenium-server

# DevOps single-binary tools (pinned + SHA256). bazelisk is installed as `bazel`.
RUN curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/v${BAZELISK_VERSION}/bazelisk-linux-amd64" -o /usr/local/bin/bazel \
    && echo "${BAZELISK_SHA256}  /usr/local/bin/bazel" | sha256sum -c - && chmod 0755 /usr/local/bin/bazel && ln -s bazel /usr/local/bin/bazelisk \
    && curl -fsSL "https://github.com/kubernetes-sigs/kind/releases/download/v${KIND_VERSION}/kind-linux-amd64" -o /usr/local/bin/kind \
    && echo "${KIND_SHA256}  /usr/local/bin/kind" | sha256sum -c - && chmod 0755 /usr/local/bin/kind \
    && curl -fsSL "https://github.com/kubernetes/minikube/releases/download/v${MINIKUBE_VERSION}/minikube-linux-amd64" -o /usr/local/bin/minikube \
    && echo "${MINIKUBE_SHA256}  /usr/local/bin/minikube" | sha256sum -c - && chmod 0755 /usr/local/bin/minikube \
    && curl -fsSL "https://github.com/Azure/bicep/releases/download/v${BICEP_VERSION}/bicep-linux-x64" -o /usr/local/bin/bicep \
    && echo "${BICEP_SHA256}  /usr/local/bin/bicep" | sha256sum -c - && chmod 0755 /usr/local/bin/bicep

# DevOps archive tools (pinned + SHA256): kustomize, packer, azcopy.
RUN curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" -o /tmp/kustomize.tgz \
    && echo "${KUSTOMIZE_SHA256}  /tmp/kustomize.tgz" | sha256sum -c - && tar -xzf /tmp/kustomize.tgz -C /usr/local/bin kustomize \
    && curl -fsSL "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" -o /tmp/packer.zip \
    && echo "${PACKER_SHA256}  /tmp/packer.zip" | sha256sum -c - && unzip -q -o /tmp/packer.zip -d /usr/local/bin packer \
    && curl -fsSL "https://github.com/Azure/azure-storage-azcopy/releases/download/v${AZCOPY_VERSION}/azcopy_linux_amd64_${AZCOPY_VERSION}.tar.gz" -o /tmp/azcopy.tgz \
    && echo "${AZCOPY_SHA256}  /tmp/azcopy.tgz" | sha256sum -c - && tar -xzf /tmp/azcopy.tgz -C /tmp \
    && install -m 0755 "/tmp/azcopy_linux_amd64_${AZCOPY_VERSION}/azcopy" /usr/local/bin/azcopy \
    && ln -s azcopy /usr/local/bin/azcopy10 \
    && rm -rf /tmp/kustomize.tgz /tmp/packer.zip /tmp/azcopy.tgz "/tmp/azcopy_linux_amd64_${AZCOPY_VERSION}"

# Ansible + yamllint via pipx (shared bin dir); Newman + Parcel via npm; Fastlane via gem.
# DL3013: pipx installs apps (not pip libs); versions track latest via weekly rebuild, like apt/npm.
# hadolint ignore=DL3013
RUN PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install --include-deps ansible \
    && PIPX_HOME=/opt/pipx PIPX_BIN_DIR=/usr/local/bin pipx install yamllint \
    && npm install -g "newman@${NEWMAN_VERSION}" "parcel@${PARCEL_VERSION}" "lerna@${LERNA_VERSION}" "n@${N_VERSION}" \
         "typescript@${TYPESCRIPT_VERSION}" "webpack@${WEBPACK_VERSION}" "webpack-cli@${WEBPACK_CLI_VERSION}" \
         "grunt@${GRUNT_VERSION}" "gulp@${GULP_VERSION}" \
    && npm cache clean --force \
    && gem install --no-document fastlane -v "${FASTLANE_VERSION}" \
    && gem install --no-document multi_json -v "${MULTIJSON_VERSION}"

RUN curl -fsSL "https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz" -o /tmp/maven.tar.gz \
    && echo "${MAVEN_SHA512}  /tmp/maven.tar.gz" | sha512sum -c - \
    && tar -xzf /tmp/maven.tar.gz -C /opt \
    && ln -s "/opt/apache-maven-${MAVEN_VERSION}/bin/mvn" /usr/local/bin/mvn \
    && curl -fsSL "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" -o /tmp/gradle.zip \
    && echo "${GRADLE_SHA256}  /tmp/gradle.zip" | sha256sum -c - \
    && unzip -q /tmp/gradle.zip -d /opt \
    && ln -s "/opt/gradle-${GRADLE_VERSION}/bin/gradle" /usr/local/bin/gradle \
    && rm -f /tmp/maven.tar.gz /tmp/gradle.zip

RUN curl -fsSL "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer \
    && echo "${COMPOSER_SHA256}  /usr/local/bin/composer" | sha256sum -c - && chmod 0755 /usr/local/bin/composer \
    && curl -fsSL "https://phar.phpunit.de/phpunit-${PHPUNIT_VERSION}.phar" -o /usr/local/bin/phpunit \
    && echo "${PHPUNIT_SHA256}  /usr/local/bin/phpunit" | sha256sum -c - && chmod 0755 /usr/local/bin/phpunit

RUN curl -fsSL "https://github.com/pulumi/pulumi/releases/download/v${PULUMI_VERSION}/pulumi-v${PULUMI_VERSION}-linux-x64.tar.gz" -o /tmp/pulumi.tar.gz \
    && echo "${PULUMI_SHA256}  /tmp/pulumi.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/pulumi.tar.gz -C /opt \
    && rm -f /tmp/pulumi.tar.gz

RUN curl -fsSL "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.zip" -o /tmp/tofu.zip \
    && echo "${OPENTOFU_SHA256}  /tmp/tofu.zip" | sha256sum -c - \
    && unzip -q -o /tmp/tofu.zip tofu -d /usr/local/bin \
    && chmod 0755 /usr/local/bin/tofu \
    && rm -f /tmp/tofu.zip

RUN curl -fsSL "https://julialang-s3.julialang.org/bin/linux/x64/${JULIA_VERSION%.*}/julia-${JULIA_VERSION}-linux-x86_64.tar.gz" -o /tmp/julia.tar.gz \
    && echo "${JULIA_SHA256}  /tmp/julia.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/julia.tar.gz -C /opt \
    && ln -s "/opt/julia-${JULIA_VERSION}/bin/julia" /usr/local/bin/julia \
    && curl -fsSL "https://github.com/JetBrains/kotlin/releases/download/v${KOTLIN_VERSION}/kotlin-compiler-${KOTLIN_VERSION}.zip" -o /tmp/kotlin.zip \
    && echo "${KOTLIN_SHA256}  /tmp/kotlin.zip" | sha256sum -c - \
    && unzip -q /tmp/kotlin.zip -d /opt \
    && ln -s /opt/kotlinc/bin/kotlin /usr/local/bin/kotlin \
    && ln -s /opt/kotlinc/bin/kotlinc /usr/local/bin/kotlinc \
    && rm -f /tmp/julia.tar.gz /tmp/kotlin.zip

# Swift toolchain (pinned tarball + SHA256) into /opt/swift; bin on PATH via ENV.
RUN curl -fsSL "https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2404/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04.tar.gz" -o /tmp/swift.tar.gz \
    && echo "${SWIFT_SHA256}  /tmp/swift.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/swift \
    && tar -xzf /tmp/swift.tar.gz -C /opt/swift --strip-components=1 \
    && rm -f /tmp/swift.tar.gz

RUN mkdir -p /opt/microsoft/powershell/7 \
    && curl -fsSL "https://github.com/PowerShell/PowerShell/releases/download/v${POWERSHELL_VERSION}/powershell-${POWERSHELL_VERSION}-linux-x64.tar.gz" -o /tmp/pwsh.tar.gz \
    && echo "${POWERSHELL_SHA256}  /tmp/pwsh.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/pwsh.tar.gz -C /opt/microsoft/powershell/7 \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh \
    && rm -f /tmp/pwsh.tar.gz \
    && pwsh -NoProfile -Command "Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
       Install-Module -Name Az -RequiredVersion 15.6.1 -Scope AllUsers -Force; \
       Install-Module -Name Microsoft.Graph -RequiredVersion 2.39.0 -Scope AllUsers -Force; \
       Install-Module -Name Pester -RequiredVersion 5.9.0 -Scope AllUsers -Force; \
       Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope AllUsers -Force"

ENV GHCUP_INSTALL_BASE_PREFIX=/usr/local
RUN curl -fsSL "https://downloads.haskell.org/ghcup/${GHCUP_VERSION}/x86_64-linux-ghcup-${GHCUP_VERSION}" -o /usr/local/bin/ghcup \
    && echo "${GHCUP_SHA256}  /usr/local/bin/ghcup" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/ghcup \
    && ghcup install ghc "${GHC_VERSION}" --set \
    && ghcup install cabal "${CABAL_VERSION}" --set \
    && ghcup install stack "${STACK_VERSION}" --set

# The SDK patch list is bumped manually (no Renovate datasource for the exact-patch set).
ENV DOTNET_ROOT=/usr/lib/dotnet \
    DOTNET_NOLOGO=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1
RUN curl -fsSL "https://raw.githubusercontent.com/dotnet/install-scripts/${DOTNET_INSTALL_COMMIT}/src/dotnet-install.sh" -o /tmp/dotnet-install.sh \
    && echo "${DOTNET_INSTALL_SHA256}  /tmp/dotnet-install.sh" | sha256sum -c - \
    && chmod +x /tmp/dotnet-install.sh \
    && for v in 8.0.130 8.0.206 8.0.319 8.0.424 9.0.120 9.0.205 9.0.317 10.0.111 10.0.204 10.0.303 10.0.400; do \
         /tmp/dotnet-install.sh --version "${v}" --install-dir /usr/lib/dotnet --no-path || exit 1; \
       done \
    && ln -s /usr/lib/dotnet/dotnet /usr/local/bin/dotnet \
    && /usr/lib/dotnet/dotnet tool install --tool-path /usr/local/bin nbgv \
    && rm -f /tmp/dotnet-install.sh

# Miniconda (batch install; reachable via $CONDA, not on the default PATH by design — parity).
RUN curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" -o /tmp/miniconda.sh \
    && echo "${MINICONDA_SHA256}  /tmp/miniconda.sh" | sha256sum -c - \
    && bash /tmp/miniconda.sh -b -p /usr/share/miniconda \
    && rm -f /tmp/miniconda.sh

RUN curl -fsSL "https://github.com/aws/aws-sam-cli/releases/download/v${SAM_VERSION}/aws-sam-cli-linux-x86_64.zip" -o /tmp/sam.zip \
    && echo "${SAM_SHA256}  /tmp/sam.zip" | sha256sum -c - \
    && unzip -q /tmp/sam.zip -d /tmp/sam-install \
    && /tmp/sam-install/install \
    && rm -rf /tmp/sam.zip /tmp/sam-install

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

# Action archive cache (matches ubuntu-latest install-actions-cache.sh): prebundled action tarballs
# the runner resolves offline via $ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE. Pinned tarball + SHA256.
RUN mkdir -p /opt/actionarchivecache \
    && curl -fsSL "https://github.com/actions/action-versions/releases/download/v${ACTION_ARCHIVE_CACHE_VERSION}/action-versions.tar.gz" -o /tmp/action-versions.tar.gz \
    && echo "${ACTION_ARCHIVE_CACHE_SHA256}  /tmp/action-versions.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/action-versions.tar.gz -C /opt/actionarchivecache \
    && rm -f /tmp/action-versions.tar.gz \
    && chown -R runner:runner /opt/actionarchivecache

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

# Prebake the Node toolcache (matches setup-node): nodejs.org tarball + SHA256 into
# $RUNNER_TOOL_CACHE/node/<v>/x64 + a <v>/x64.complete marker (setup-node layout, offline cache hit).
RUN NODE_ARCH="${TARGETARCH/amd64/x64}" \
    && declare -A NODE_SHA=( \
         ["${NODE_TC_22}"]="${NODE_TC_22_SHA256}" \
         ["${NODE_TC_24}"]="${NODE_TC_24_SHA256}" \
       ) \
    && for v in "${NODE_TC_22}" "${NODE_TC_24}"; do \
         echo "== prebake Node ${v} ==" \
         && curl -fsSL "https://nodejs.org/dist/v${v}/node-v${v}-linux-x64.tar.gz" -o "/tmp/node-${v}.tar.gz" \
         && echo "${NODE_SHA[${v}]}  /tmp/node-${v}.tar.gz" | sha256sum -c - \
         && dest="/opt/hostedtoolcache/node/${v}/${NODE_ARCH}" \
         && mkdir -p "${dest}" \
         && tar -xzf "/tmp/node-${v}.tar.gz" -C "${dest}" --strip-components=1 \
         && touch "/opt/hostedtoolcache/node/${v}/${NODE_ARCH}.complete" \
         && rm -f "/tmp/node-${v}.tar.gz" || exit 1; \
       done \
    && rm -rf /tmp/* \
    && chown -R runner:runner /opt/hostedtoolcache/node

# Prebake the Ruby toolcache (matches ruby/setup-ruby): ruby-builder tarball (top-level x64/) + SHA256
# into $RUNNER_TOOL_CACHE/Ruby/<v>/x64 + a <v>/x64.complete marker (offline cache hit).
RUN declare -A RUBY_SHA=( \
         ["${RUBY_32}"]="${RUBY_32_SHA256}" \
         ["${RUBY_33}"]="${RUBY_33_SHA256}" \
         ["${RUBY_34}"]="${RUBY_34_SHA256}" \
         ["${RUBY_40}"]="${RUBY_40_SHA256}" \
       ) \
    && for v in "${RUBY_32}" "${RUBY_33}" "${RUBY_34}" "${RUBY_40}"; do \
         echo "== prebake Ruby ${v} ==" \
         && curl -fsSL "https://github.com/ruby/ruby-builder/releases/download/ruby-${v}/ruby-${v}-ubuntu-24.04-x64.tar.gz" -o "/tmp/ruby-${v}.tar.gz" \
         && echo "${RUBY_SHA[${v}]}  /tmp/ruby-${v}.tar.gz" | sha256sum -c - \
         && mkdir -p "/opt/hostedtoolcache/Ruby/${v}" \
         && tar -xzf "/tmp/ruby-${v}.tar.gz" -C "/opt/hostedtoolcache/Ruby/${v}" \
         && touch "/opt/hostedtoolcache/Ruby/${v}/x64.complete" \
         && rm -f "/tmp/ruby-${v}.tar.gz" || exit 1; \
       done \
    && rm -rf /tmp/* \
    && chown -R runner:runner /opt/hostedtoolcache/Ruby

# Prebake the PyPy toolcache (matches actions/setup-pypy): downloads.python.org tarball + SHA256 into
# $RUNNER_TOOL_CACHE/PyPy/<python-version>/x64 (dir named by Python-compat version) + x64.complete.
RUN declare -A PYPY_FILE=( \
         ["${PYPY_39}"]="${PYPY_39_FILE}" \
         ["${PYPY_310}"]="${PYPY_310_FILE}" \
         ["${PYPY_311}"]="${PYPY_311_FILE}" \
       ) \
    && declare -A PYPY_SHA=( \
         ["${PYPY_39}"]="${PYPY_39_SHA256}" \
         ["${PYPY_310}"]="${PYPY_310_SHA256}" \
         ["${PYPY_311}"]="${PYPY_311_SHA256}" \
       ) \
    && for v in "${PYPY_39}" "${PYPY_310}" "${PYPY_311}"; do \
         echo "== prebake PyPy ${v} ==" \
         && curl -fsSL "https://downloads.python.org/pypy/${PYPY_FILE[${v}]}.tar.bz2" -o "/tmp/pypy-${v}.tar.bz2" \
         && echo "${PYPY_SHA[${v}]}  /tmp/pypy-${v}.tar.bz2" | sha256sum -c - \
         && dest="/opt/hostedtoolcache/PyPy/${v}/x64" \
         && mkdir -p "${dest}" \
         && tar -xjf "/tmp/pypy-${v}.tar.bz2" -C "${dest}" --strip-components=1 \
         && touch "/opt/hostedtoolcache/PyPy/${v}/x64.complete" \
         && rm -f "/tmp/pypy-${v}.tar.bz2" || exit 1; \
       done \
    && rm -rf /tmp/* \
    && chown -R runner:runner /opt/hostedtoolcache/PyPy

# CodeQL bundle into the toolcache (matches github/codeql-action offline lookup) + on PATH.
RUN curl -fsSL "https://github.com/github/codeql-action/releases/download/codeql-bundle-v${CODEQL_VERSION}/codeql-bundle-linux64.tar.gz" -o /tmp/codeql.tar.gz \
    && echo "${CODEQL_SHA256}  /tmp/codeql.tar.gz" | sha256sum -c - \
    && mkdir -p "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64" \
    && tar -xzf /tmp/codeql.tar.gz -C "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64" \
    && touch "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64.complete" \
    && ln -s "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64/codeql/codeql" /usr/local/bin/codeql \
    && chown -R runner:runner /opt/hostedtoolcache/CodeQL \
    && rm -f /tmp/codeql.tar.gz

# Homebrew (Linux), pinned by git tag and owned by runner (brew refuses to run as root).
RUN git clone --depth 1 --branch "${HOMEBREW_VERSION}" https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew \
    && mkdir -p /home/linuxbrew/.linuxbrew/bin \
    && ln -s /home/linuxbrew/.linuxbrew/Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew \
    && chown -R runner:runner /home/linuxbrew

# vcpkg, pinned by git tag, bootstrapped, owned by runner ($VCPKG_INSTALLATION_ROOT).
RUN git clone --depth 1 --branch "${VCPKG_VERSION}" https://github.com/microsoft/vcpkg /usr/local/share/vcpkg \
    && /usr/local/share/vcpkg/bootstrap-vcpkg.sh -disableMetrics \
    && ln -s /usr/local/share/vcpkg/vcpkg /usr/local/bin/vcpkg \
    && chown -R runner:runner /usr/local/share/vcpkg

# nvm (pinned git tag) at $NVM_DIR, owned by runner (it writes node installs there).
RUN git clone --depth 1 --branch "v${NVM_VERSION}" https://github.com/nvm-sh/nvm /usr/local/nvm \
    && chown -R runner:runner /usr/local/nvm

# Android SDK + NDK (cmdline-tools pinned + SHA256; full matrix via sdkmanager on Temurin): NDK 27/28/29,
# the m2repository/play-services extras, two sdkmanager CMake builds, platform-tools, and every
# platforms/build-tools >= the pinned minimums (resolved from `sdkmanager --list`, like ubuntu-latest's
# install-android-sdk.sh). Owned by runner. sdkmanager verifies downloads against Google's signed repo.
RUN set -euo pipefail; \
    sdk=/usr/local/lib/android/sdk; mgr="$sdk/cmdline-tools/latest/bin/sdkmanager"; \
    mkdir -p "$sdk/cmdline-tools"; \
    curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_VERSION}_latest.zip" -o /tmp/cmdtools.zip; \
    echo "${ANDROID_CMDLINE_SHA256}  /tmp/cmdtools.zip" | sha256sum -c -; \
    unzip -q /tmp/cmdtools.zip -d /tmp/cmdtools; \
    mv /tmp/cmdtools/cmdline-tools "$sdk/cmdline-tools/latest"; \
    yes 2>/dev/null | "$mgr" --sdk_root="$sdk" --licenses >/dev/null || true; \
    listing="$("$mgr" --sdk_root="$sdk" --list)"; \
    components=( "extras;android;m2repository" "extras;google;m2repository" "extras;google;google_play_services" \
                 "cmake;${ANDROID_CMAKE1_VERSION}" "cmake;${ANDROID_CMAKE2_VERSION}" "platform-tools" \
                 "ndk;${ANDROID_NDK_VERSION}" "ndk;${ANDROID_NDK_28_VERSION}" "ndk;${ANDROID_NDK_LATEST_VERSION}" ); \
    for p in $(printf '%s\n' "$listing" | grep -oE 'platforms;android-[0-9]+(-ext[0-9]+)?([[:space:]|]|$)' | grep -oE 'platforms;android-[0-9]+(-ext[0-9]+)?' | sort -u); do \
      v="$(printf '%s' "$p" | grep -oE '[0-9.]+' | head -n1)"; \
      if [ "$(printf '%s\n%s\n' "${ANDROID_PLATFORM_MIN}" "$v" | sort -V | head -n1)" = "${ANDROID_PLATFORM_MIN}" ]; then components+=("$p"); fi; \
    done; \
    for b in $(printf '%s\n' "$listing" | grep -oE 'build-tools;[0-9.]+(-rc[0-9]+)?' | grep -v rc | sort -u); do \
      v="${b#build-tools;}"; \
      if [ "$(printf '%s\n%s\n' "${ANDROID_BUILD_TOOLS_MIN}" "$v" | sort -V | head -n1)" = "${ANDROID_BUILD_TOOLS_MIN}" ]; then components+=("$b"); fi; \
    done; \
    echo y | "$mgr" --sdk_root="$sdk" "${components[@]}" >/dev/null; \
    rm -rf /tmp/cmdtools.zip /tmp/cmdtools; \
    chown -R runner:runner /usr/local/lib/android

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
      org.opencontainers.image.description="Ubuntu 24.04 GitHub Actions runner image for tempus.build (ARC gha-runner-scale-set) — full ubuntu-latest toolset parity: languages + offline toolcaches, DevOps/cloud/Kubernetes CLIs, databases, browsers + drivers, and Android SDK/NDK" \
      org.opencontainers.image.source="https://github.com/tempusbuild/runner-images" \
      org.opencontainers.image.documentation="https://github.com/tempusbuild/runner-images/blob/main/ubuntu-24.04/README.md" \
      org.opencontainers.image.url="https://tempus.build" \
      org.opencontainers.image.vendor="tempus.build" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="docker.io/library/ubuntu:24.04"

USER 1001

# ARC sets the command itself; CMD is just a default for manual runs.
CMD ["/home/runner/run.sh"]
