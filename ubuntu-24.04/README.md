# runner-ubuntu-24.04 (full)

Full runner image for ARC `gha-runner-scale-set`, label `tempus-ubuntu-24.04-4core`.

## Contents

| Component                     | Version                                                                                                                                                                                           | Source (verify before bumping)                                                        |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Base                          | Ubuntu 24.04 (noble), pinned by digest `sha256:786a8b55…`                                                                                                                                         | hub.docker.com/\_/ubuntu — bump digest on weekly rebuild                              |
| Actions runner                | `2.335.1` (ARG `RUNNER_VERSION`)                                                                                                                                                                  | github.com/actions/runner/releases                                                    |
| Node.js                       | LTS, major `22` (ARG `NODE_MAJOR`)                                                                                                                                                                | nodejs.org/en/about/previous-releases                                                 |
| Python (system)               | 3.12 (system on 24.04) + `pip`, `venv`, dev headers (`python3-dev`)                                                                                                                               | packages.ubuntu.com                                                                   |
| Python (toolcache, prebake)   | `3.10.20`, `3.11.15`, `3.12.13`, `3.13.14`, `3.14.6` in `/opt/hostedtoolcache/Python/<v>/x64` (ARG `PYTHON_31x`)                                                                                  | actions/python-versions `versions-manifest.json` — same builds `setup-python` fetches |
| Go (toolcache, prebake)       | `1.25.11`, `1.26.4` — supported minors (1.25 / 1.26) in `/opt/hostedtoolcache/go/<v>/x64` (ARG `GO_125`/`GO_126`)                                                                                 | go.dev/dl — SHA256 from `?mode=json&include=all`; `setup-go` layout (cache hit)       |
| Rust (rustup)                 | toolchain `1.96.0` (rustup `1.29.0`), default profile = rustc+cargo+rust-std+rustfmt+clippy; `RUSTUP_HOME=/usr/local/rustup`, `CARGO_HOME=/usr/local/cargo` (ARG `RUST_VERSION`/`RUSTUP_VERSION`) | static.rust-lang.org — pinned `rustup-init` + SHA256                                  |
| pipx                          | `1.14.0`, pinned via `pip` (ARG `PIPX_VERSION`) — isolated installs of Python CLI tools                                                                                                           | PyPI                                                                                  |
| CMake / Git LFS               | `3.31.12` (+ `4.3.3` as `cmake4`) / `3.7.1` — pinned binaries + SHA256 (ARG `CMAKE_VERSION`/`CMAKE4_VERSION`/`GITLFS_VERSION`)                                                                    | github.com/Kitware/CMake, github.com/git-lfs/git-lfs releases                         |
| yq (mikefarah)                | `4.53.3` — pinned binary + SHA256 (ARG `YQ_VERSION`)                                                                                                                                              | github.com/mikefarah/yq releases                                                      |
| GitHub CLI (`gh`)             | from the cli.github.com repo (workflows commonly call `gh`)                                                                                                                                       | cli.github.com                                                                        |
| Docker CLI + buildx + compose | from the download.docker.com repo                                                                                                                                                                 | docs.docker.com                                                                       |
| Base tools                    | see `packages.txt` (incl. `zstd` — speeds up `actions/cache`)                                                                                                                                     | —                                                                                     |

The table above lists the core pinned components; the **full ubuntu-latest-parity toolset** (all
languages, toolcaches, DevOps/cloud/DB/browser/mobile tooling) is in
[Toolset](#toolset-full-parity-with-ubuntu-latest) below.

The Docker daemon is not included — it is provided by the ARC dind sidecar (`containerMode: dind`).
The image ships the Docker CLI only.

The Python toolcache is prebaked so that `actions/setup-python` with
`python-version: "3.10|3.11|3.12|3.13|3.14"` gets an offline cache hit (the `<v>/x64.complete` marker
exists) instead of downloading a runtime on every run. Versions are pinned in the Dockerfile
(ARG `PYTHON_310…PYTHON_314`) — the exact latest stable patch from the `actions/python-versions`
manifest for `linux/24.04/x64` at build time. Verify the manifest on bump.

## Build / checks

```bash
just build   # docker build -t tempusbuild/runner-ubuntu-24.04:dev ubuntu-24.04
just test    # smoke tests from ../tests inside the image
just scan    # trivy: HIGH/CRITICAL, ignore-unfixed, --ignorefile .trivyignore.yaml
```

## Usage

Consumed via ARC: `ghcr.io/tempusbuild/runner-ubuntu-24.04:<tag>`.
After publishing to ghcr, pin `tag@sha256:` on the consumer side.

## Toolset (full parity with ubuntu-latest)

Included:

- system `python3` (3.12) + `pip` + `venv` + dev headers (`python3-dev`), build toolchain
  (`build-essential`, `pkg-config`, `ninja-build`) and dev libraries (`libffi-dev`, `libssl-dev`,
  `libpq-dev`, `libxml2-dev`, `libxslt1-dev`, `zlib1g-dev`, `libjpeg-dev`) plus a curated set of
  headers for common native extensions beyond the ubuntu-latest set (`libmemcached-dev`,
  `default-libmysqlclient-dev`, `libldap-dev`, `libsasl2-dev`, `libkrb5-dev`, `libcurl4-openssl-dev`,
  `libgmp-dev`) — building native wheels (`pylibmc`, `mysqlclient`, `python-ldap`, `pycurl`…) works;
- `pipx` for isolated CLI tools;
- toolcache Python 3.10 / 3.11 / 3.12 / 3.13 / 3.14 → `setup-python` resolves offline (cache hit);
- toolcache Go 1.25 / 1.26 → `actions/setup-go` resolves offline (cache hit); the newest (1.26) is
  also the default `go` on `PATH` (parity with ubuntu-latest), so tools expecting a system Go work
  without downloading a toolchain — versions and layout in the table above;
- toolcache Node 22 / 24 → `actions/setup-node` resolves offline (cache hit);
- toolcache Ruby 3.2 / 3.3 / 3.4 / 4.0 → `ruby/setup-ruby` resolves offline (ruby-builder builds);
- toolcache PyPy 3.9 / 3.10 / 3.11 → `actions/setup-pypy` resolves offline (cache hit);
- Rust via `rustup` (versions in the table above); `cargo`/`rustup` on `PATH`, usable by `runner`;
  native crates build (`build-essential`, `pkg-config`, `libssl-dev` present);
- common CLIs on `PATH`: `git`/`git-lfs`, `gh`, `ssh` (openssh-client), `rsync`, `jq`/`yq`,
  `sqlite3`, `cmake`, `clang`, `kubectl`, `helm`, `zstd`/`zip`/`unzip`, plus `yarn`/`pnpm` via
  `corepack`;
- cloud CLIs on `PATH`: `aws` (AWS CLI v2), `az` (Azure CLI, with the `azure-devops` extension),
  `gcloud` (Google Cloud CLI);
- Java: Eclipse Temurin JDK 8 / 11 / 17 / 21 / 25 (default 17; `JAVA_HOME` + `JAVA_HOME_<v>_X64` set);
- compilers: GCC 12 / 13 / 14 (+ `gfortran`), Clang/LLVM 16 / 17 / 18 (+ `clang-format`, `clang-tidy`);
  the unversioned `gcc`/`cc`/`g++`/`make` (build-essential) plus the autotools chain (`autoconf`,
  `automake`, `libtool`, `m4`, `bison`, `flex`, `swig`, `patchelf`, `dpkg-dev`, `fakeroot`, `rpm`);
- base apt utilities (parity with ubuntu-latest): `shellcheck`, `p7zip-full` (`7z`), `parallel`,
  `mercurial` (`hg`), `python-is-python3` (`python` → `python3`), `perl`, `xvfb` (headless display
  for the browsers above), `libnss3-tools` (`certutil`), `file`, `tree`, `time`, `locales`,
  compression (`brotli`, `pigz`, `lz4`, `xz-utils`, `zsync`), network diagnostics (`net-tools`,
  `bind9-dnsutils`, `iproute2`, `iputils-ping`, `netcat-openbsd`, `inetutils-telnet`), and
  `aria2`/`upx`/`mediainfo`/`haveged`/`texinfo`/`sshpass`/`pollinate`;
- Ruby 3.2 (system) on `PATH`; `zstd` 1.5.7 (built from source);
- databases: PostgreSQL 16 (PGDG) and MySQL 8.0 — clients and servers;
- browsers + drivers: Google Chrome + ChromeDriver, Microsoft Edge + msedgedriver, Firefox (from the
  Mozilla apt repo, not snap) + geckodriver, and Selenium Server (`selenium-server`, runs on Temurin);
- DevOps: Ansible, Bazel/Bazelisk, Podman/Buildah/Skopeo, Kind, Minikube, Kustomize, Packer, Bicep,
  AzCopy (`azcopy`/`azcopy10`), Newman, Parcel, Fastlane, yamllint, the CodeQL bundle (in the
  toolcache + on `PATH`), the Amazon ECR credential helper (`docker-credential-ecr-login`) and the
  AWS Session Manager plugin (`session-manager-plugin`); plus OpenTofu (`tofu`, MPL-2.0) — the OSS
  Terraform-compatible IaC tool (ubuntu-latest dropped Terraform under its BSL license);
- environment managers + AWS SAM: Homebrew (`brew`), Miniconda (reachable via `$CONDA`), vcpkg
  (`$VCPKG_INSTALLATION_ROOT`), and `sam`;
- JVM build tools: Maven, Gradle, Ant; global npm CLIs `lerna`, `typescript` (`tsc`), `webpack` +
  `webpack-cli`, `grunt`, `gulp`;
- webdriver env vars set as on ubuntu-latest: `CHROMEWEBDRIVER`, `EDGEWEBDRIVER`, `GECKOWEBDRIVER`,
  `SELENIUM_JAR_PATH`;
- PHP 8.3 + extensions (incl. `memcache`/`memcached`; Xdebug enabled, PCOV installed-but-disabled —
  parity with ubuntu-latest), Composer, PHPUnit; Pulumi; `n` and `nvm` (`$NVM_DIR`); `git-ftp`;
  Sphinx search server;
- more languages: Swift 6.3, Julia 1.12, Kotlin 2.4, Haskell (GHC 9.14 / Cabal / Stack via `ghcup`),
  .NET SDK 8/9/10 (+ `nbgv`), PowerShell 7.6 (+ Az / Microsoft.Graph / Pester / PSScriptAnalyzer);
- web servers: Apache2 and Nginx;
- Android: full ubuntu-latest matrix via `sdkmanager` — cmdline-tools, platform-tools, every
  `platforms;android-*` and `build-tools` ≥ 34 (incl. the `-ext` platform variants), NDK 27 / 28 / 29,
  the `m2repository` / Google Play services extras, and two CMake builds (3.31 / 4.1), with
  `ANDROID_HOME`/`ANDROID_NDK*` env (default NDK 27, latest 29).

## Inclusion policy

The image provides **full drop-in parity** with the documented toolset of GitHub-hosted
`ubuntu-latest` — the official
[Ubuntu2404 readme](https://github.com/actions/runner-images/blob/main/images/ubuntu/Ubuntu2404-Readme.md)
is the contract. That covers the languages/runtimes, the prebaked toolcaches that `setup-*` actions
resolve offline, DevOps/cloud/Kubernetes tooling, databases, browsers + drivers, environment
managers, and the env contract `setup-*`/builds expect (`ImageOS`, `RUNNER_TOOL_CACHE`,
`JAVA_HOME_<v>_X64`, `ANDROID_*`, `CHROMEWEBDRIVER`, …). Every downloaded artifact is pinned
(exact version + SHA256/512, or a key-verified apt repo) — the image's supply-chain bar.

Deliberate exceptions:

- **EOL Go minors (1.22–1.24) are NOT baked** (security): Go patches only the last two minors, so a
  baked toolcache for an EOL minor would carry image-unfixable HIGH/CRITICAL stdlib CVEs. Supported
  1.25/1.26 are baked patch-current; older minors install via `actions/setup-go` from the network.
- **Patch-currency and the long tail track the newest pinned set**: toolcache patches
  (Python/Go/Node/Ruby/PyPy) are pinned to a current set; versions outside it install on demand via
  `setup-*` (no cache hit). The Android matrix is resolved at build (every platform/build-tools ≥ the
  pinned minimum, like ubuntu-latest); components published after a build install via `sdkmanager`.
- **`systemd-coredump` is NOT installed**: the runner executes as a container under ARC (no `systemd`
  as PID 1), so it would be inert and only adds `systemd` surface. Everything else in the documented
  ubuntu-latest apt set is present.
- **A small curated superset beyond ubuntu-latest** (batteries-included): dev headers for common
  native extensions (`libmemcached-dev`, `default-libmysqlclient-dev`, `libldap-dev`, `libsasl2-dev`,
  `libkrb5-dev`, `libcurl4-openssl-dev`, `libgmp-dev`) are preinstalled so native extensions such as
  `pylibmc`, `mysqlclient`, `python-ldap` and `pycurl` compile without a per-workflow `apt-get` step.
  These are NOT on ubuntu-latest — workflows relying on them are not portable back to GitHub-hosted
  runners.

**PEP 668 (externally managed):** the system `python3` is marked externally managed, so a global
`pip install <pkg>` fails by design. The standard path is `python -m venv` (inside a venv the
restriction is lifted) or `actions/setup-python` (its toolcache runtimes are not externally managed).
For CLI tools — `pipx`. This matches ubuntu-latest behaviour.

## Notes

- Full ubuntu-latest toolset parity (see the inclusion policy above); the long tail (extra toolcache
  patches, Android components published after the build) installs on demand via `setup-*` / `sdkmanager`.
- The `minimal` variant (`../ubuntu-24.04-minimal/`) — no Node/Docker, just runner + base.
