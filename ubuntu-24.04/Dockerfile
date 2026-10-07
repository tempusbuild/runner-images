# syntax=docker/dockerfile:1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e
# Ubuntu 24.04 runner image for ARC gha-runner-scale-set (label tempus-ubuntu-24.04-4core):
# runner-agent + base CI toolchain.
# Base pinned by digest; bump on weekly rebuild via `docker buildx imagetools inspect`.
FROM ubuntu:24.04@sha256:534baea6a22c03a63003dbc8dbe78fe34bc0d7e595d9a9dc9834884ff530eb55

ARG RUNNER_VERSION=2.338.0
# SHA256 of the linux-x64 runner tarball (from release notes); recompute on version bump. x64-only.
ARG RUNNER_SHA256=af4b794c1bc41d73d40535e3fe092a39f9679cd8d965954c2aca25a05ca41d32
# Action archive cache (parity with ubuntu-latest install-actions-cache.sh): prebundled tarballs of
# common actions the runner resolves offline. Pinned tarball + SHA256 (recompute on bump). ~273 MB.
ARG ACTION_ARCHIVE_CACHE_VERSION=1.0.58
ARG ACTION_ARCHIVE_CACHE_SHA256=f5e80269a8357e3509a7e1c5eb146c5743fb02b3b569e96c967bf6606f0ddbf1
ARG NODE_MAJOR=22
# Fresh npm: npm's bundled deps from NodeSource pull in CVEs.
ARG NPM_VERSION=11.21.0
ARG TARGETARCH=amd64
# libicu70 from the jammy pool (as ubuntu-latest's configure-dpkg.sh) for prebuilt binaries linked
# against ICU 70; SHA512 is the one ubuntu-latest pins.
ARG LIBICU70_SHA512=a6315482d93606e375c272718d2458870b95e4ed4b672ea8640cf7bc2d2c2f41aea13b798b1e417e1ffc472a90c6aad150d3d293aa9bddec48e39106e4042807

# Python toolcache (matches setup-python: same actions/python-versions builds, offline cache hit).
# Exact patches and their SHA256 are pinned (the manifest publishes no hashes) — verify on bump.
ARG PYTHON_310=3.10.22
ARG PYTHON_311=3.11.17
ARG PYTHON_312=3.12.15
ARG PYTHON_313=3.13.16
ARG PYTHON_314=3.14.8
ARG PYTHON_310_SHA256=4c96c0e9380150d436c38be322bafa04a5632db7eb2def147b7553ed7e88fd16
ARG PYTHON_311_SHA256=ae713815fe406a06f1691856f697a0b1e58b3e986f44e62f0cd0bca2424f1aac
ARG PYTHON_312_SHA256=fcb672b0437c2d8df5565b7cc250b2b0d7455e2b8d6a4a107cfa6f2efe4f7ed8
ARG PYTHON_313_SHA256=d6f5f504043400592e9dcf368ba262c64d998608646cc22281b5a75beecbc872
ARG PYTHON_314_SHA256=fa74abc70a55c10f6631967784878704eef81bbde9b8ec27469534f6ba997cb3
# 3.10/3.11 bundle an old setuptools with vulnerable vendored copies (CVE-2026-23949/-24049) —
# upgrade to the fixed version rather than ignoring (3.12+ bundle no setuptools, PEP 632).
ARG SETUPTOOLS_VERSION=83.0.0

# Go toolcache (matches setup-go: offline cache hit, no runtime download per run). We bake only
# supported minors (Go patches only the last 2): patch-current 1.25/1.26. EOL minors (1.22-1.24)
# are deliberately not baked — EOL Go is unpatched and its stdlib CVEs are unfixable in the image;
# anyone needing them installs via setup-go from the network. SHA256 from go.dev/dl JSON
# (files[].sha256 field). Recompute on bump (go.dev/dl/?mode=json&include=all).
ARG GO_125=1.25.14
ARG GO_126=1.26.8
ARG GO_125_SHA256=a21ae5633a269bcd7e90cf767e48225633795e99d831742cbf3397064fee7712
ARG GO_126_SHA256=d0f743b33e8d8945e6b1f432edd15785c70507121d6e2a723b21285eddf8b57b

# Node.js toolcache (matches setup-node: offline cache hit). Newest patch of each cached major
# (22, 24); SHA256 from nodejs.org SHASUMS256.txt. NODE_MAJOR above is the system Node (apt).
ARG NODE_TC_22=22.23.3
ARG NODE_TC_24=24.21.0
ARG NODE_TC_22_SHA256=1084aa36196bba4c3a5e69a1ee388a6e4ff729dad09445fbcd434b28fe3c24af
ARG NODE_TC_24_SHA256=6e1db87ef58b8819e5d5402eff1536491b18edd8eb7bee5ef7897876e88dc5ff

# Ruby toolcache (matches ruby/setup-ruby): prebuilt ruby-builder tarballs for ubuntu-24.04.
ARG RUBY_32=3.2.11
ARG RUBY_33=3.3.12
ARG RUBY_34=3.4.11
ARG RUBY_40=4.0.7
ARG RUBY_32_SHA256=1b89cf6de50def9e15701f369e526c4fbfb79abf1f7576b01eec695291d46299
ARG RUBY_33_SHA256=3fa2d6242e105a65f694fae86e9f68d9617c827fc14d1fcf611035b9ae2cbdb8
ARG RUBY_34_SHA256=e3d114c546332243f84755aa277ba1e1781deba686050d729d2806d3766baf25
ARG RUBY_40_SHA256=a11b84469b76a38175bce72176f66389fc05b87a3e7545329e8685b01dcb2176

# PyPy toolcache (matches actions/setup-pypy): dir named by the Python-compat version; PyPy build in
# the filename. Tarball symlinks (python3 -> pypy3) are already present. Bumped manually (the
# python<->pypy version pairing has no clean Renovate datasource). *_FILE includes the archive
# extension: PyPy 8 ships .tar.gz only, older lines .tar.bz2; tar auto-detects the compression.
ARG PYPY_39=3.9.19
ARG PYPY_310=3.10.16
ARG PYPY_311=3.11.16
ARG PYPY_39_FILE=pypy3.9-v7.3.16-linux64.tar.bz2
ARG PYPY_310_FILE=pypy3.10-v7.3.19-linux64.tar.bz2
ARG PYPY_311_FILE=pypy3.11-v8.0.0-linux64.tar.gz
ARG PYPY_39_SHA256=16f9c5b808c848516e742986e826b833cdbeda09ad8764e8704595adbe791b23
ARG PYPY_310_SHA256=c73ac2cc2380ac9227fd297482bf2a3e17a80618ba46db7544d535515321ec1e
ARG PYPY_311_SHA256=66a3657e9ddf2d62ead44d3a44b9ea2f6e7dbf28d812554cae5c982a0585bfa5

# Rust via pinned rustup-init (not `curl | sh`): tarball by URL + SHA256 from <url>.sha256.
# default profile = rustc+cargo+rust-std+rustfmt+clippy. Exact toolchain pin for reproducibility.
ARG RUSTUP_VERSION=1.29.1
ARG RUST_VERSION=1.99.0
ARG RUSTUP_SHA256=dda7234360b7f578ca8b0ddcb80145646fa61a67c1720a5abc7051b35c9fcb71

# yq (mikefarah) pinned binary + SHA256 — parity with ubuntu-latest (jq comes from apt; yq does not).
ARG YQ_VERSION=4.54.1
ARG YQ_SHA256=8e34fc298390875de416e6a4afcb8cabeceb25d9aa8506c1a2f9353cf702ea5f

# cmake / git-lfs pinned binaries + SHA256 — version parity with ubuntu-latest (apt ships older).
# Two cmake majors like ubuntu-latest: 3.31 is the default `cmake`, 4.x is exposed as `cmake4`.
ARG CMAKE_VERSION=3.31.12
ARG CMAKE_SHA256=0dc2e9a6860f06bf10bd8fadc03e35d9eeb4df46e33763a7e480e987758f385c
ARG CMAKE4_VERSION=4.4.4
ARG CMAKE4_SHA256=e5bb807f7728cb60cd8b27ebc97a2edb469b68655f21e844a600c3575b76f5bb
ARG GITLFS_VERSION=3.8.0
ARG GITLFS_SHA256=e455e00f15d9b95661b8d53498ffb0c3367962cf1ec73c31ab7369516cd6ab8d
# pipx pinned via pip (Ubuntu's apt pipx lags behind ubuntu-latest).
ARG PIPX_VERSION=1.16.7

# zstd built from source + SHA256 (apt zstd lags; upstream ships no prebuilt linux binary).
ARG ZSTD_VERSION=1.5.7
ARG ZSTD_SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3

# kubectl / Helm pinned binaries + SHA256. Helm stays on 3.x (ubuntu-latest parity), not v4 (major).
ARG KUBECTL_VERSION=1.37.1
ARG KUBECTL_SHA256=65691ff77eb6fa44c908b77a1082c9f092c3b9733b5cefabec0d1104890e21a8
ARG HELM_VERSION=3.22.0
ARG HELM_SHA256=1e4ab49e429626cf6c6958d914248b78c9730803c2751b87627e171dc800e7bb

# AWS CLI v2 pinned installer + SHA256. Azure CLI and Google Cloud CLI come from vendor apt repos.
ARG AWSCLI_VERSION=2.37.10
ARG AWSCLI_SHA256=1aaed142cb63294e41ef70431fe9c602dbb869f8a21b6b8fc9d5ffd53b5c9235
# AWS Session Manager plugin (.deb from AWS S3) — pinned version + SHA256 of the deb.
ARG SSM_PLUGIN_VERSION=1.2.835.0
ARG SSM_PLUGIN_SHA256=7c6dcad12518571cc7959a713e6a8ae1bdf6ed66fd9bee37dc189e39ca58ae03
# Amazon ECR Docker credential helper: release binary (apt ships an older one); SHA256 from the
# release's .sha256 file.
ARG ECR_HELPER_VERSION=0.12.0
ARG ECR_HELPER_SHA256=a22ab6d59dbac777b8fb31984709461da00a4c778b6ae14c8d3729e8d5ded1a6
# ssh.dev.azure.com RSA host key fingerprint as published in the Azure DevOps SSH docs.
ARG AZURE_DEVOPS_SSH_FP=SHA256:ohD8VZEXGWo6Ez8GSEJQ9WpafgLFsOfLOtGGQCQo6Og

# Browser drivers. geckodriver + Selenium server are pinned (SHA256); chromedriver/msedgedriver
# float to match the apt browser version (fetched by version at build, like the browsers themselves).
ARG GECKODRIVER_VERSION=0.37.1
ARG GECKODRIVER_SHA256=e815130ea95983e162ae91843b48d3a3ce991735635fce83a647afde21e09f7e
ARG SELENIUM_VERSION=4.50.0
ARG SELENIUM_SHA256=4664ef41d4bf5ee78cd6264ff8dca480ef80628ca91df95ca554c4d66f7831c1
# Chromium snapshot (as ubuntu-latest): the chromium-browser-snapshots build nearest at or below the
# Chrome stable revision at pin time. Snapshot objects are immutable; SHA256 computed on the pinned
# zip (cross-checked against the bucket's MD5). Bumped manually alongside a Chrome major.
ARG CHROMIUM_REVISION=1697588
ARG CHROMIUM_SHA256=b77317efe3b1fae1eb9f98b40ef4882e3769c9ff180996d4281a7cb647d5c15f

# DevOps tools — pinned binaries + SHA256 (Newman/Parcel via npm; Ansible/yamllint via pipx;
# Fastlane via gem; Podman/Buildah/Skopeo from apt).
ARG BAZELISK_VERSION=1.29.0
ARG BAZELISK_SHA256=5a408715e932c0250d28bd84555f12edbf70117de42f9181691c736eacc4a992
# Bazel version bazelisk falls back to without a .bazelversion (USE_BAZEL_FALLBACK_VERSION, as
# ubuntu-latest) — deterministic instead of "latest at run time".
ARG BAZEL_FALLBACK_VERSION=9.2.0
ARG KIND_VERSION=0.33.0
ARG KIND_SHA256=aee6151561422756b764a4ae28e7f44cda5af5a9eead3cc9985112b1de8d8e0d
ARG MINIKUBE_VERSION=1.39.0
ARG MINIKUBE_SHA256=b738496da01be06bbaf80c688f57ce25acd3849fbb518155f3a88e03ef555aa4
ARG KUSTOMIZE_VERSION=5.8.2
ARG KUSTOMIZE_SHA256=06af0a202c2b831207d0173f9c9cdb1b30abceca0747cb3fbb72792d26055c95
ARG PACKER_VERSION=1.16.1
ARG PACKER_SHA256=af38a9e93e4ed1b9ca68206ae969c64c300c82a3dde46a780dfa629f0867f651
ARG BICEP_VERSION=0.48.1
ARG BICEP_SHA256=b09ec25a9d376c1f8e33ede6ed22b587f915ad68488d5db77a6f9541748c7f6e
ARG AZCOPY_VERSION=10.32.8
ARG AZCOPY_SHA256=a95277dbc265912cefdddbaf251aa99ec648cb18ba657e8788066357a9022dc3
ARG CODEQL_VERSION=2.27.1
ARG CODEQL_SHA256=1d380f79896ededc654c7b21fafb3360136f1aeb678ad4df4df9af3910c6b815
ARG YARN_VERSION=1.22.22
ARG NEWMAN_VERSION=6.2.2
ARG PARCEL_VERSION=2.16.4
ARG LERNA_VERSION=10.0.1
ARG TYPESCRIPT_VERSION=7.0.2
ARG WEBPACK_VERSION=5.111.1
ARG WEBPACK_CLI_VERSION=7.2.3
ARG GRUNT_VERSION=1.6.3
ARG GULP_VERSION=5.0.1
ARG FASTLANE_VERSION=2.240.1
ARG MULTIJSON_VERSION=1.21.2

# JVM project-management tools — Maven/Gradle pinned (Ant is from apt).
ARG MAVEN_VERSION=3.9.16
ARG MAVEN_SHA512=831a8591fe20c8243b1dbe7d71e3244f31d1665b0804b2e825e38cbbe5ce0cafb8338851f90780735568773e0a6cd07bbec107cda0b896b008b861075358b6f6
ARG GRADLE_VERSION=9.8.0
ARG GRADLE_SHA256=bafd5ce9cfaea0fbccfdc8439a1ac42fbd4cd9c89dc9a988228d8a2639a58e6c

# Misc tools: Pulumi (pinned tarball), nvm (git tag), n (npm); Composer + PHPUnit (pinned phars).
# PHP series = ubuntu-latest toolset-2404.json php.versions.
ARG PHP_VERSION=8.3
ARG PULUMI_VERSION=3.267.0
ARG PULUMI_SHA256=527c1ce7c16cb38525a96d55422f221e819476e2b0743ae55c9862ad775ae10a
# OpenTofu (MPL-2.0, OSS) — Terraform-compatible IaC; ubuntu-latest dropped Terraform (BSL), so this
# is a deliberate OSS extra beyond strict parity.
ARG OPENTOFU_VERSION=1.13.1
ARG OPENTOFU_SHA256=8ccbc6f8ee21d2827715f3c6e08a9b3e0209b1e62057c05067ef117e047c1a80
ARG NVM_VERSION=0.40.8
ARG N_VERSION=10.2.0
ARG COMPOSER_VERSION=2.10.3
ARG COMPOSER_SHA256=7a2d379d5b8ffdaa028580ef26494c36d2feef4b178d3dd1473a4dbc5e17c8d6
ARG PHPUNIT_VERSION=8.5.56
ARG PHPUNIT_SHA256=765122cdaa75527967beaec77763c21eea59e908c5c751e95054f50195dd4939

# Language runtimes (Julia/Kotlin pinned binaries; PowerShell tarball; Haskell via ghcup).
ARG JULIA_VERSION=1.13.1
ARG JULIA_SHA256=0f2e18c8dea60a2c8711d089cd9612f7a8df394b89e5208096fe5867647e0908
ARG KOTLIN_VERSION=2.4.20
ARG KOTLIN_SHA256=59e9ca74c7904ef2c122b12114937673ccce68de820a663f0ed66ccf8799e0b7
ARG POWERSHELL_VERSION=7.6.6
ARG POWERSHELL_SHA256=ddbc4a2d113bbd46d283cfedcbcd117a70caefd7673f41f2b4e0000badf103bc
ARG GHCUP_VERSION=0.2.6.2
ARG GHCUP_SHA256=9ed5da5449b48043a0d17e767c05d2ef585e25a639bb934329496c6d2fad9cf8
# ghc/cabal/stack are installed through ghcup, so their versions are bounded by ghcup's
# metadata catalog, not upstream GitHub releases — bump only to a ghcup-available version
# (verified by the build). No Renovate manager for these; they track ubuntu-latest's pins.
ARG GHC_VERSION=9.14.1
ARG CABAL_VERSION=3.18.1.0
ARG STACK_VERSION=3.11.1
ARG SWIFT_VERSION=6.4.0
ARG SWIFT_SHA256=69f7b2b4dbce6090b6c92194b71149a057e16269093b5a9dded38afc4a05094e

# dotnet-install.sh pinned to a commit + SHA256 (not the rolling dot.net/v1 script); it drives the
# version-pinned SDK installs below. Bump commit + recompute SHA256 together (manual).
ARG DOTNET_INSTALL_COMMIT=6f559c420847ded38591392dafe785ad511f39f5
ARG DOTNET_INSTALL_SHA256=082f7685e156738a1b2e2ed8381a621870d4ce8e8c59278034556f05c186eb2e

# Android SDK (cmdline-tools pinned + SHA256); NDK versions match the ANDROID_NDK* env below.
# Manually bumped (no clean Renovate datasource): cmdline-tools build id, NDK/build-tools/platform.
ARG ANDROID_CMDLINE_VERSION=11076708
ARG ANDROID_CMDLINE_SHA256=2d2d50857e4eb553af5a6dc3ad507a17adf43d115264b1afc116f95c92e5e258
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
ARG HOMEBREW_VERSION=7.0.8
ARG VCPKG_VERSION=2026.07.29
ARG MINICONDA_VERSION=py314_26.7.1-1
ARG MINICONDA_SHA256=e8b25b92b262499141c5bd57a98d3c008024185fa951494b9cd9b6d94e72338b
ARG SAM_VERSION=1.166.2
ARG SAM_SHA256=4419ea4bb4ae1c69d2d41b346f77fdcd80099ae4ba9da7278e23427d54b05420

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
    ACCEPT_EULA=Y \
    CHROME_BIN=/usr/bin/google-chrome \
    GOROOT_1_25_X64=/opt/hostedtoolcache/go/${GO_125}/x64 \
    GOROOT_1_26_X64=/opt/hostedtoolcache/go/${GO_126}/x64 \
    HOMEBREW_NO_AUTO_UPDATE=1 \
    HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS=3650 \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    USE_BAZEL_FALLBACK_VERSION=silent:${BAZEL_FALLBACK_VERSION} \
    SWIFT_PATH=/opt/swift/usr/bin \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/opt/pipx_bin \
    DOTNET_ROOT=/usr/share/dotnet \
    DOTNET_NOLOGO=1 \
    DOTNET_CLI_TELEMETRY_OPTOUT=1 \
    DOTNET_MULTILEVEL_LOOKUP=0 \
    DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1 \
    ANT_HOME=/usr/share/ant \
    GRADLE_HOME=/opt/gradle-${GRADLE_VERSION} \
    # ~/.dotnet/tools: `dotnet tool install -g` target; ~/.local/bin: `pip install --user` target;
    # /opt/pipx_bin: pipx apps; ~/go/bin: `go install` target; /usr/local/go/bin: default `go`;
    # /home/linuxbrew/...: Homebrew; /opt/pulumi: Pulumi (parity with GitHub-hosted).
    PATH=/home/runner/.config/composer/vendor/bin:/home/runner/.dotnet/tools:/home/runner/.local/bin:/opt/pipx_bin:/home/runner/go/bin:/usr/local/go/bin:/usr/local/cargo/bin:/usr/local/.ghcup/bin:/home/linuxbrew/.linuxbrew/bin:/opt/pulumi:/opt/swift/usr/bin:/usr/local/lib/android/sdk/cmdline-tools/latest/bin:/usr/local/lib/android/sdk/platform-tools:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

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

# DL3008 (apt version pinning) is intentionally ignored on the Node/Docker/gh installs below: the
# image pulls fresh security patches (weekly rebuild), pinning every version is impractical.
# Also, as ubuntu-latest: libicu70 (pinned deb), clang 18 as the unversioned clang-format/clang-tidy/
# run-clang-tidy, and /etc/pip.conf allowing system pip installs (PEP 668 opt-out). The openssh-server
# host keys generated by the `ssh` package are removed so no private key ships in a public image;
# run `sudo ssh-keygen -A` before starting sshd.
COPY packages.txt /tmp/packages.txt
RUN apt-get-update-retry \
    && xargs -a /tmp/packages.txt apt-get install -y --no-install-recommends \
    && curl -fsSL https://archive.ubuntu.com/ubuntu/pool/main/i/icu/libicu70_70.1-2_amd64.deb -o /tmp/libicu70.deb \
    && echo "${LIBICU70_SHA512}  /tmp/libicu70.deb" | sha512sum -c - \
    && apt-get install -y --no-install-recommends /tmp/libicu70.deb \
    && for t in clang-format clang-tidy run-clang-tidy; do \
         update-alternatives --install "/usr/bin/${t}" "${t}" "/usr/bin/${t}-18" 100 || exit 1; \
       done \
    && rm -f /etc/ssh/ssh_host_* \
    && printf '[global]\nbreak-system-packages = true\n' > /etc/pip.conf \
    && rm -rf /var/lib/apt/lists/* /tmp/packages.txt /tmp/libicu70.deb

# Newer Git from the maintainers' PPA (Ubuntu ships an older point release) — version parity.
# add-apt-repository's single-shot Launchpad key fetch intermittently flakes
# (GPGKeyTemporarilyNotFoundError), so retry until it succeeds — a transient hiccup must not break the
# build. (A keyserver curl+dearmor was avoided: its ?op=get&search=0x… URL trips Dockle CIS-DI-0010.)
# hadolint ignore=DL3008
RUN i=0; until add-apt-repository -y ppa:git-core/ppa; do \
      i=$((i+1)); [ "$i" -ge 5 ] && exit 1; echo "add-apt-repository retry ${i}"; sleep 5; \
    done \
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends git \
    && git config --system --add safe.directory '*' \
    && rm -rf /var/lib/apt/lists/*

# System-wide SSH known hosts (as ubuntu-latest): github.com from GitHub's published host keys
# (api.github.com/meta, not a trust-on-first-use keyscan); ssh.dev.azure.com publishes only a
# fingerprint, so its keyscan result is accepted only if it matches the documented one.
RUN set -euo pipefail; \
    curl -fsSL --retry 5 --retry-all-errors https://api.github.com/meta | jq -r '.ssh_keys[] | "github.com " + .' > /etc/ssh/ssh_known_hosts; \
    [ "$(grep -c '^github.com ' /etc/ssh/ssh_known_hosts)" -ge 3 ]; \
    i=0; \
    until ssh-keyscan -T 10 -t rsa ssh.dev.azure.com 2>/dev/null | grep '^ssh.dev.azure.com ' > /tmp/azure.keys; do \
      i=$((i+1)); [ "$i" -lt 5 ] || exit 1; sleep 5; \
    done; \
    ssh-keygen -lf /tmp/azure.keys | grep -qF " ${AZURE_DEVOPS_SSH_FP} "; \
    cat /tmp/azure.keys >> /etc/ssh/ssh_known_hosts; \
    rm -f /tmp/azure.keys; \
    chmod 0644 /etc/ssh/ssh_known_hosts

# PHP from the Ubuntu archive with the ubuntu-latest extension set (install-php.sh; same source, no
# third-party PPA). -dev ships php-config: setup-php on self-hosted runners reuses the preinstalled
# PHP only when php-config reports the requested series, otherwise it reinstalls PHP on every run.
# hadolint ignore=DL3008
RUN apt-get-update-retry \
    && apt-get install -y --no-install-recommends php-pear snmp "php${PHP_VERSION}" \
         "php${PHP_VERSION}"-{amqp,apcu,bcmath,bz2,cgi,cli,common,curl,dba,dev,enchant,fpm,gd,gmp,igbinary,imagick} \
         "php${PHP_VERSION}"-{imap,interbase,intl,ldap,mbstring,memcache,memcached,mongodb,mysql,odbc,opcache,pcov} \
         "php${PHP_VERSION}"-{pgsql,phpdbg,pspell,readline,redis,snmp,soap,sqlite3,sybase,tidy,xdebug,xml,xsl,yaml,zip,zmq} \
    && phpdismod -v "${PHP_VERSION}" pcov \
    && mkdir -p /etc/skel/.config/composer \
    && rm -rf /var/lib/apt/lists/*

# pipx pinned via pip (apt pipx lags). --break-system-packages: install into the system interpreter
# on PEP 668; pipx then isolates every app it installs into its own venvs.
RUN python3 -m pip install --break-system-packages --no-cache-dir "pipx==${PIPX_VERSION}"

# Node.js via the NodeSource keyring repo (not `curl | bash`); npm upgraded in place to a pinned fresh
# version. The global prefix then moves to /usr/local (ubuntu-latest's layout) so the global npm CLIs
# below land there and `npm i -g` works as runner without sudo (ownership set with those CLIs).
# corepack provides only pnpm: yarn is the npm-installed 1.x classic, as on ubuntu-latest.
# hadolint ignore=DL3008
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key -o /etc/apt/keyrings/nodesource.asc \
    && chmod a+r /etc/apt/keyrings/nodesource.asc \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/nodesource.asc] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" \
       > /etc/apt/sources.list.d/nodesource.list \
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g "npm@${NPM_VERSION}" \
    && npm config set prefix /usr/local --location=global \
    && corepack enable pnpm \
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
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# GitHub CLI (workflows commonly call `gh`).
# hadolint ignore=DL3008
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /etc/apt/keyrings/githubcli.gpg \
    && chmod a+r /etc/apt/keyrings/githubcli.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${ECR_HELPER_VERSION}/linux-amd64/docker-credential-ecr-login" -o /usr/bin/docker-credential-ecr-login \
    && echo "${ECR_HELPER_SHA256}  /usr/bin/docker-credential-ecr-login" | sha256sum -c - \
    && chmod 0755 /usr/bin/docker-credential-ecr-login

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
    && apt-get-update-retry \
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
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends google-cloud-cli \
    && rm -rf /var/lib/apt/lists/*

# Eclipse Temurin JDKs 8/11/17/21/25 (matching ubuntu-latest) from the Adoptium apt repo; default 17.
# hadolint ignore=DL3008
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg \
    && chmod a+r /etc/apt/keyrings/adoptium.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb noble main" \
       > /etc/apt/sources.list.d/adoptium.list \
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends java-common temurin-8-jdk temurin-11-jdk temurin-17-jdk temurin-21-jdk temurin-25-jdk \
    && update-java-alternatives -s temurin-17-jdk-amd64 \
    && rm -rf /var/lib/apt/lists/*

# Java toolcache (as ubuntu-latest's install-java-tools.sh): Java_Temurin-Hotspot_jdk/<semver>/x64 links
# each installed JDK + an x64.complete marker, so actions/setup-java (distribution: temurin) gets a
# cache hit. The version is read from the JDK's release file, normalised to semver like upstream.
RUN for n in 8 11 17 21 25; do \
      jdk="/usr/lib/jvm/temurin-${n}-jdk-amd64"; \
      v="$(grep '^SEMANTIC' "${jdk}/release" | cut -d= -f2 | tr -d '"' | tr '+' '-')"; \
      if [ -z "$v" ]; then v="$("${jdk}/bin/java" -fullversion 2>&1 | tr -d '"' | tr '+' '-' | awk '{print $4}')"; fi; \
      if echo "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+'; then v="$(echo "$v" | sed -E 's/\.[0-9]+-/-/')"; fi; \
      if echo "$v" | grep -Eq '^[0-9]+-'; then v="$(echo "$v" | sed -E 's/-/.0-/')"; fi; \
      if echo "$v" | grep -Eq '^[0-9]+\.[0-9]+-'; then v="$(echo "$v" | sed -E 's/-/.0-/')"; fi; \
      echo "$v" | grep -Eq "^${n}\.[0-9]+\.[0-9]+-[0-9]+" || { echo "bad Java ${n} version: '${v}'" >&2; exit 1; }; \
      d="/opt/hostedtoolcache/Java_Temurin-Hotspot_jdk/${v}"; \
      mkdir -p "$d" && ln -s "$jdk" "$d/x64" && touch "$d/x64.complete" || exit 1; \
    done \
    && chown -R 1001:1001 /opt/hostedtoolcache
ENV JAVA_HOME=/usr/lib/jvm/temurin-17-jdk-amd64 \
    JAVA_HOME_8_X64=/usr/lib/jvm/temurin-8-jdk-amd64 \
    JAVA_HOME_11_X64=/usr/lib/jvm/temurin-11-jdk-amd64 \
    JAVA_HOME_17_X64=/usr/lib/jvm/temurin-17-jdk-amd64 \
    JAVA_HOME_21_X64=/usr/lib/jvm/temurin-21-jdk-amd64 \
    JAVA_HOME_25_X64=/usr/lib/jvm/temurin-25-jdk-amd64

# Databases: PostgreSQL 16 (PGDG repo) + MySQL 8.0 (Ubuntu) — clients and servers (parity). Neither
# server runs by default. MySQL root gets ubuntu-latest's documented password ("root", install-mysql.sh)
# via a debconf preseed, applied by the package while it initialises the data dir (no server needed).
# The postinst leaves /run/mysqld at 0700 (a systemd host recreates it at boot; a container image
# keeps it), which locks non-root clients out of the socket — reset it to the init script's 0755.
COPY <<'EOF' /tmp/mysql.preseed
mysql-server mysql-server/root_password password root
mysql-server mysql-server/root_password_again password root
EOF

# hadolint ignore=DL3008
RUN debconf-set-selections /tmp/mysql.preseed \
    && rm -f /tmp/mysql.preseed \
    && curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/keyrings/pgdg.gpg \
    && chmod a+r /etc/apt/keyrings/pgdg.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/pgdg.gpg] https://apt.postgresql.org/pub/repos/apt noble-pgdg main" \
       > /etc/apt/sources.list.d/pgdg.list \
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends postgresql-16 postgresql-client-16 mysql-server mysql-client \
    && install -d -m 0755 -o mysql -g root /run/mysqld \
    && rm -rf /var/lib/apt/lists/*

# Google Chrome + matching ChromeDriver (Chrome for Testing). Chrome floats to latest stable (apt);
# the driver is fetched to match the installed full version.
# hadolint ignore=DL3008
RUN curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /etc/apt/keyrings/google-chrome.gpg \
    && chmod a+r /etc/apt/keyrings/google-chrome.gpg \
    && echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/google-chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" \
       > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get-update-retry \
    && apt-get install -y --no-install-recommends google-chrome-stable \
    && CHROME_VER="$(google-chrome-stable --version | grep -oE '[0-9]+(\.[0-9]+){3}')" \
    && curl -fsSL "https://storage.googleapis.com/chrome-for-testing-public/${CHROME_VER}/linux64/chromedriver-linux64.zip" -o /tmp/chromedriver.zip \
    && unzip -q /tmp/chromedriver.zip -d /tmp \
    && mkdir -p /usr/local/share/chromedriver-linux64 \
    && install -m 0755 /tmp/chromedriver-linux64/chromedriver /usr/local/share/chromedriver-linux64/chromedriver \
    && ln -s /usr/local/share/chromedriver-linux64/chromedriver /usr/local/bin/chromedriver \
    && rm -rf /tmp/chromedriver.zip /tmp/chromedriver-linux64 /var/lib/apt/lists/*

# Chromium snapshot into /usr/local/share/chromium + chromium/chromium-browser links (as ubuntu-latest).
RUN curl -fsSL "https://www.googleapis.com/download/storage/v1/b/chromium-browser-snapshots/o/Linux_x64%2F${CHROMIUM_REVISION}%2Fchrome-linux.zip?alt=media" -o /tmp/chromium.zip \
    && echo "${CHROMIUM_SHA256}  /tmp/chromium.zip" | sha256sum -c - \
    && mkdir -p /usr/local/share/chromium \
    && unzip -q /tmp/chromium.zip -d /usr/local/share/chromium \
    && ln -s /usr/local/share/chromium/chrome-linux/chrome /usr/bin/chromium \
    && ln -s /usr/local/share/chromium/chrome-linux/chrome /usr/bin/chromium-browser \
    && rm -f /tmp/chromium.zip

# Microsoft Edge + matching msedgedriver (reuses the Microsoft keyring from the Azure CLI step).
# hadolint ignore=DL3008
RUN echo "deb [arch=${TARGETARCH} signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" \
       > /etc/apt/sources.list.d/microsoft-edge.list \
    && apt-get-update-retry \
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
    && apt-get-update-retry \
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

# Ansible + yamllint via pipx into the shared $PIPX_HOME/$PIPX_BIN_DIR (/opt/pipx, /opt/pipx_bin — as
# ubuntu-latest); Newman, Parcel, yarn & co. via npm into the /usr/local prefix; Fastlane via gem.
# The pipx and npm global dirs are handed to runner (uid 1001, created later) in this same layer, so
# `pipx install` / `npm i -g` work without sudo — chmod 777 as upstream would also open them to others.
# /usr/local/bin is first in sudo's secure_path and holds the root-owned systemctl shim; runner
# owning it is harmless only while runner has passwordless sudo anyway.
# DL3013: pipx installs apps (not pip libs); versions track latest via weekly rebuild, like apt/npm.
# hadolint ignore=DL3013
RUN pipx install --include-deps ansible \
    && pipx install yamllint \
    && npm install -g "newman@${NEWMAN_VERSION}" "parcel@${PARCEL_VERSION}" "lerna@${LERNA_VERSION}" "n@${N_VERSION}" \
         "typescript@${TYPESCRIPT_VERSION}" "webpack@${WEBPACK_VERSION}" "webpack-cli@${WEBPACK_CLI_VERSION}" \
         "grunt@${GRUNT_VERSION}" "gulp@${GULP_VERSION}" "yarn@${YARN_VERSION}" \
    && npm cache clean --force \
    && chown -R 1001:1001 "${PIPX_HOME}" "${PIPX_BIN_DIR}" /usr/local/lib/node_modules \
    && chown 1001:1001 /usr/local/bin \
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

RUN curl -fsSL "https://getcomposer.org/download/${COMPOSER_VERSION}/composer.phar" -o /usr/bin/composer \
    && echo "${COMPOSER_SHA256}  /usr/bin/composer" | sha256sum -c - && chmod 0755 /usr/bin/composer \
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

# Swift toolchain (pinned tarball + SHA256) into /opt/swift; bin on PATH and $SWIFT_PATH via ENV; the
# libsourcekitdInProc.so link in /usr/local/lib is what ubuntu-latest provides for SourceKit-LSP tooling.
RUN curl -fsSL "https://download.swift.org/swift-${SWIFT_VERSION}-release/ubuntu2404/swift-${SWIFT_VERSION}-RELEASE/swift-${SWIFT_VERSION}-RELEASE-ubuntu24.04.tar.gz" -o /tmp/swift.tar.gz \
    && echo "${SWIFT_SHA256}  /tmp/swift.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/swift \
    && tar -xzf /tmp/swift.tar.gz -C /opt/swift --strip-components=1 \
    && ln -s /opt/swift/usr/lib/libsourcekitdInProc.so /usr/local/lib/libsourcekitdInProc.so \
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
       Install-Module -Name Microsoft.Graph -RequiredVersion 2.40.0 -Scope AllUsers -Force; \
       Install-Module -Name Pester -RequiredVersion 5.9.0 -Scope AllUsers -Force; \
       Install-Module -Name PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope AllUsers -Force"

ENV GHCUP_INSTALL_BASE_PREFIX=/usr/local
RUN curl -fsSL "https://downloads.haskell.org/ghcup/${GHCUP_VERSION}/x86_64-linux-ghcup-${GHCUP_VERSION}" -o /usr/local/bin/ghcup \
    && echo "${GHCUP_SHA256}  /usr/local/bin/ghcup" | sha256sum -c - \
    && chmod 0755 /usr/local/bin/ghcup \
    && ghcup install ghc "${GHC_VERSION}" --set \
    && ghcup install cabal "${CABAL_VERSION}" --set \
    && ghcup install stack "${STACK_VERSION}" --set

# .NET SDKs into /usr/share/dotnet — DOTNET_ROOT and actions/setup-dotnet's default Linux install dir,
# so setup-dotnet finds the preinstalled SDKs and adds new ones next to them (dir owned by runner, uid
# 1001, in this same layer). /usr/lib/dotnet stays as a compat link. nbgv goes to /etc/skel/.dotnet/tools
# (copied to ~runner on user creation; on PATH), as ubuntu-latest does with its dotnet tools.
# The SDK patch list is bumped manually (no Renovate datasource for the exact-patch set).
RUN curl -fsSL "https://raw.githubusercontent.com/dotnet/install-scripts/${DOTNET_INSTALL_COMMIT}/src/dotnet-install.sh" -o /tmp/dotnet-install.sh \
    && echo "${DOTNET_INSTALL_SHA256}  /tmp/dotnet-install.sh" | sha256sum -c - \
    && chmod +x /tmp/dotnet-install.sh \
    && for v in 8.0.131 8.0.206 8.0.319 8.0.425 9.0.121 9.0.205 9.0.318 10.0.112 10.0.204 10.0.303 10.0.401; do \
         /tmp/dotnet-install.sh --version "${v}" --install-dir "${DOTNET_ROOT}" --no-path || exit 1; \
       done \
    && ln -s "${DOTNET_ROOT}/dotnet" /usr/local/bin/dotnet \
    && ln -s "${DOTNET_ROOT}" /usr/lib/dotnet \
    && "${DOTNET_ROOT}/dotnet" tool install --tool-path /etc/skel/.dotnet/tools nbgv \
    && chown -R 1001:1001 "${DOTNET_ROOT}" \
    && rm -rf /tmp/dotnet-install.sh /root/.dotnet /root/.nuget /tmp/NuGetScratch*

# Miniconda (batch install at $CONDA). As on ubuntu-latest, only `conda` itself is linked into
# /usr/bin; $CONDA/bin (its python, pip) stays off PATH so it doesn't shadow the system Python.
RUN curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" -o /tmp/miniconda.sh \
    && echo "${MINICONDA_SHA256}  /tmp/miniconda.sh" | sha256sum -c - \
    && bash /tmp/miniconda.sh -b -p /usr/share/miniconda \
    && ln -s /usr/share/miniconda/bin/conda /usr/bin/conda \
    && rm -f /tmp/miniconda.sh

RUN curl -fsSL "https://github.com/aws/aws-sam-cli/releases/download/v${SAM_VERSION}/aws-sam-cli-linux-x86_64.zip" -o /tmp/sam.zip \
    && echo "${SAM_SHA256}  /tmp/sam.zip" | sha256sum -c - \
    && unzip -q /tmp/sam.zip -d /tmp/sam-install \
    && /tmp/sam-install/install \
    && rm -rf /tmp/sam.zip /tmp/sam-install

# Unprivileged runner (+sudo for setup-* steps) and a toolcache writable by the runner user.
# UID pinned to 1001 (same as the official ARC runner image) — dind volume permissions rely on it.
# docker group pinned to gid 123 — the gid the ARC dind sidecar creates docker.sock with, so the
# runner user can reach the daemon socket instead of getting permission denied. GID pinned to 1001 too:
# earlier layers hand dirs (dotnet, npm/pipx globals, toolcache) to 1001:1001 before the user exists.
# /etc/skel/.config/configstore (as ubuntu-latest) exists for $XDG_CONFIG_HOME tools that expect it.
RUN mkdir -p /etc/skel/.config/configstore \
    && groupadd -g 1001 runner \
    && useradd -m -u 1001 -g 1001 -s /bin/bash runner \
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
         && curl -fsSL "https://downloads.python.org/pypy/${PYPY_FILE[${v}]}" -o "/tmp/pypy-${v}.tar" \
         && echo "${PYPY_SHA[${v}]}  /tmp/pypy-${v}.tar" | sha256sum -c - \
         && dest="/opt/hostedtoolcache/PyPy/${v}/x64" \
         && mkdir -p "${dest}" \
         && tar -xf "/tmp/pypy-${v}.tar" -C "${dest}" --strip-components=1 \
         && touch "/opt/hostedtoolcache/PyPy/${v}/x64.complete" \
         && rm -f "/tmp/pypy-${v}.tar" || exit 1; \
       done \
    && rm -rf /tmp/* \
    && chown -R runner:runner /opt/hostedtoolcache/PyPy

# CodeQL bundle into the toolcache (matches github/codeql-action offline lookup) + on PATH.
RUN curl -fsSL "https://github.com/github/codeql-action/releases/download/codeql-bundle-v${CODEQL_VERSION}/codeql-bundle-linux64.tar.gz" -o /tmp/codeql.tar.gz \
    && echo "${CODEQL_SHA256}  /tmp/codeql.tar.gz" | sha256sum -c - \
    && mkdir -p "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64" \
    && tar -xzf /tmp/codeql.tar.gz -C "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64" \
    && touch "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64.complete" \
    && touch "/opt/hostedtoolcache/CodeQL/${CODEQL_VERSION}/x64/pinned-version" \
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

# systemctl shim: the runner is a container without systemd as PID 1, so ubuntu-latest workflows
# (`sudo systemctl start mysql.service`) would fail. Map the service-control verbs to the SysV
# `service` scripts; everything else (and any host where systemd is PID 1) goes to the real systemctl.
# Installed last so no package maintainer script reaches it during the build.
COPY --chmod=0755 <<'EOF' /usr/local/bin/systemctl
#!/bin/bash
set -euo pipefail
real() {
  [ -x /usr/bin/systemctl ] && exec /usr/bin/systemctl "$@"
  echo "systemctl: '$*' needs systemd, which is not PID 1 in this container" >&2
  exit 1
}
[ "$(cat /proc/1/comm 2>/dev/null)" = systemd ] && real "$@"
quiet=0
args=()
for a in "$@"; do
  case "$a" in
    -q|--quiet) quiet=1 ;;
    --no-pager|--no-block) ;;
    -*) real "$@" ;;
    *) args+=("$a") ;;
  esac
done
verb="${args[0]:-}"
case "$verb" in start|stop|restart|reload|status|is-active) ;; *) real "$@" ;; esac
[ "${#args[@]}" -ge 2 ] || real "$@"
rc=0
for unit in "${args[@]:1}"; do
  svc="${unit%.service}"
  case "$verb" in
    is-active)
      if service "$svc" status >/dev/null 2>&1; then state=active; else state=inactive; rc=3; fi
      [ "$quiet" -eq 1 ] || echo "$state" ;;
    status) service "$svc" status || rc=$? ;;
    *) if [ "$quiet" -eq 1 ]; then service "$svc" "$verb" >/dev/null || rc=$?; else service "$svc" "$verb" || rc=$?; fi ;;
  esac
done
exit "$rc"
EOF

# Public image metadata in ubuntu-latest's imagedata.json format (configure-image-data.sh) plus a
# Runner line. The runner itself only reads .setup_info, which the pod entrypoint writes at runtime
# and may source from this file; the image deliberately ships no .setup_info.
ARG IMAGE_VERSION=dev
ARG IMAGE_REVISION=main
RUN install -d -m 0755 /imagegeneration \
    && IMAGE_VERSION="${IMAGE_VERSION}" IMAGE_REVISION="${IMAGE_REVISION}" RUNNER_VERSION="${RUNNER_VERSION}" \
       python3 -c 'import json, os, platform; e = os.environ; repo = "https://github.com/tempusbuild/runner-images"; \
os_name = platform.freedesktop_os_release()["PRETTY_NAME"].replace(" ", "\n"); \
detail = "\n".join([ \
    "Image: ubuntu-24.04", \
    "Version: " + e["IMAGE_VERSION"], \
    "Runner: " + e["RUNNER_VERSION"], \
    "Included Software: " + repo + "/blob/" + e["IMAGE_REVISION"] + "/ubuntu-24.04/README.md", \
    "Image Release: " + repo + "/pkgs/container/runner-ubuntu-24.04"]); \
print(json.dumps([{"group": "Operating System", "detail": os_name}, {"group": "Runner Image", "detail": detail}], indent=2))' \
       > /imagegeneration/imagedata.json \
    && chmod 0644 /imagegeneration/imagedata.json

# Static OCI metadata; dynamic labels (created/revision/version) are added by CI (docker/metadata-action).
LABEL org.opencontainers.image.title="runner-ubuntu-24.04" \
      org.opencontainers.image.description="Ubuntu 24.04 GitHub Actions runner image for tempus.build (ARC gha-runner-scale-set) — full ubuntu-latest toolset parity: languages + offline toolcaches, DevOps/cloud/Kubernetes CLIs, databases, browsers + drivers, and Android SDK/NDK" \
      org.opencontainers.image.source="https://github.com/tempusbuild/runner-images" \
      org.opencontainers.image.documentation="https://github.com/tempusbuild/runner-images/blob/main/ubuntu-24.04/README.md" \
      org.opencontainers.image.url="https://tempus.build" \
      org.opencontainers.image.vendor="tempus.build" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="docker.io/library/ubuntu:24.04"

# Per-user config dir (as ubuntu-latest); set last so root build steps never write into ~runner.
ENV XDG_CONFIG_HOME=/home/runner/.config

USER 1001

# ARC sets the command itself; CMD is just a default for manual runs.
CMD ["/home/runner/run.sh"]
