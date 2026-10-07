#!/usr/bin/env bash
set -euo pipefail
fails=0

# Everything packages.txt promises as a CLI (gnupg ships the gpg binary; openssh-client ships ssh).
for tool in git git-lfs jq curl wget ssh rsync tar unzip zip zstd sqlite3 cmake clang gpg sudo; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
  echo "ok: $tool"
done

# Pinned/extra CLIs not from apt: yq (pinned binary), pipx (pip), yarn 1.x (npm), pnpm (corepack).
for tool in yq yarn pnpm pipx; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
  echo "ok: $tool"
done

# Pinned-binary versions must match the Dockerfile pins (parity with ubuntu-latest).
cmake --version | grep -q '3.31.12' || { echo "cmake != 3.31.12: $(cmake --version | head -1)" >&2; fails=$((fails+1)); }
cmake4 --version | grep -q '4.4.4' || { echo "cmake4 != 4.4.4: $(cmake4 --version | head -1)" >&2; fails=$((fails+1)); }
git-lfs version | grep -q '3.8.0' || { echo "git-lfs != 3.8.0: $(git-lfs version)" >&2; fails=$((fails+1)); }
pipx --version | grep -q '1.16.7' || { echo "pipx != 1.16.7: $(pipx --version)" >&2; fails=$((fails+1)); }
kubectl version --client 2>/dev/null | grep -q 'v1.37.1' || { echo "kubectl != 1.37.1: $(kubectl version --client 2>/dev/null | head -1)" >&2; fails=$((fails+1)); }
helm version --short 2>/dev/null | grep -q 'v3.22.0' || { echo "helm != 3.22.0: $(helm version --short 2>/dev/null)" >&2; fails=$((fails+1)); }
echo "ok: cmake/git-lfs/pipx/kubectl/helm at pinned versions"

for cc in gcc-12 gcc-13 gcc-14 g++-12 g++-13 g++-14 clang-16 clang-17 clang-18 \
          clang-format-16 clang-format-17 clang-format-18 clang-tidy-16 clang-tidy-17 clang-tidy-18; do
  command -v "$cc" >/dev/null || { echo "MISSING: $cc" >&2; fails=$((fails+1)); }
done
zstd --version | grep -q 'v1.5.7' || { echo "zstd != 1.5.7: $(zstd --version)" >&2; fails=$((fails+1)); }
if [ "$(command -v ninja)" != /usr/local/bin/ninja ] || ! ninja --version | grep -q '^1\.13\.'; then
  echo "ninja not the pinned 1.13.x release: $(command -v ninja) $(ninja --version)" >&2; fails=$((fails+1))
fi
echo "ok: gcc 12/13/14, clang 16/17/18, zstd 1.5.7, ninja 1.13"

for tool in bazel bazelisk kind minikube kustomize packer bicep azcopy azcopy10 tofu \
            podman buildah skopeo docker-credential-ecr-login \
            session-manager-plugin ansible yamllint newman parcel fastlane codeql; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
echo "ok: devops tools present (bazel/kind/minikube/kustomize/packer/bicep/azcopy/ecr-cred-helper/ssm-plugin/podman/buildah/skopeo/ansible/yamllint/newman/parcel/fastlane/codeql)"

for tool in brew vcpkg sam; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
[ -x "${CONDA:-/usr/share/miniconda}/bin/conda" ] || { echo "MISSING: conda at ${CONDA:-/usr/share/miniconda}" >&2; fails=$((fails+1)); }
echo "ok: homebrew, vcpkg, aws-sam, miniconda (\$CONDA)"

for tool in mvn gradle ant lerna; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
echo "ok: maven/gradle/ant/lerna"

# Global npm CLIs (parity with ubuntu-latest's node_modules set).
for tool in tsc webpack webpack-cli grunt gulp; do
  command -v "$tool" >/dev/null || { echo "MISSING npm global: $tool" >&2; fails=$((fails+1)); }
done
# TypeScript 7 runs a native compiler from a platform-specific optional package; -v fails without it.
tsc -v 2>/dev/null | grep -q '^Version 7\.' || { echo "tsc not runnable or != 7.x: $(tsc -v 2>&1 | head -1)" >&2; fails=$((fails+1)); }
echo "ok: npm globals (tsc/webpack/webpack-cli/grunt/gulp)"

# Misc tools (Pulumi, n, nvm, git-ftp, Sphinx search); the PHP stack is covered by test_php.sh.
for tool in git-ftp pulumi n; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
{ command -v searchd >/dev/null || command -v indexer >/dev/null; } || { echo "MISSING sphinxsearch" >&2; fails=$((fails+1)); }
[ -s "${NVM_DIR:-/usr/local/nvm}/nvm.sh" ] || { echo "MISSING nvm at ${NVM_DIR:-unset}" >&2; fails=$((fails+1)); }
echo "ok: git-ftp, pulumi, n, nvm, sphinxsearch"

for tool in apache2 nginx; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
echo "ok: apache2, nginx"

[ -d "${ANDROID_HOME:-/usr/local/lib/android/sdk}" ] || { echo "MISSING ANDROID_HOME" >&2; fails=$((fails+1)); }
for tool in sdkmanager adb; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
[ -d "${ANDROID_NDK_HOME}" ] || { echo "MISSING NDK at ${ANDROID_NDK_HOME:-unset}" >&2; fails=$((fails+1)); }
[ -d "${ANDROID_NDK_LATEST_HOME}" ] || { echo "MISSING NDK latest at ${ANDROID_NDK_LATEST_HOME:-unset}" >&2; fails=$((fails+1)); }
# Full matrix (parity with ubuntu-latest): 3 NDKs (27/28/29), multiple platforms + build-tools,
# the m2repository/play-services extras, and the sdkmanager CMake builds — counts, since the exact
# set tracks whatever was available at build time.
ah="${ANDROID_HOME:-/usr/local/lib/android/sdk}"
[ "$(find "$ah/ndk" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)" -ge 3 ] || { echo "Android: expected >=3 NDKs" >&2; fails=$((fails+1)); }
[ "$(find "$ah/platforms" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)" -ge 4 ] || { echo "Android: expected >=4 platforms" >&2; fails=$((fails+1)); }
[ "$(find "$ah/build-tools" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l)" -ge 4 ] || { echo "Android: expected >=4 build-tools" >&2; fails=$((fails+1)); }
[ -d "$ah/cmake" ] || { echo "Android: missing sdkmanager CMake" >&2; fails=$((fails+1)); }
[ -d "$ah/extras/google/m2repository" ] || { echo "Android: missing google m2repository extra" >&2; fails=$((fails+1)); }
# Minor/preview platforms (android-NN.N, android-NN.N-betaN) are part of ubuntu-latest's set too.
compgen -G "$ah/platforms/android-[0-9]*.[0-9]*" >/dev/null || { echo "Android: no minor platform (android-NN.N) installed" >&2; fails=$((fails+1)); }
echo "ok: android sdk full matrix (ndk 27/28/29, platforms+build-tools >=34, extras, cmake)"

for tool in aws az gcloud; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
  echo "ok: $tool"
done

# Databases: clients on PATH + servers present (PostgreSQL 16, MySQL 8.0).
psql --version | grep -q ' 16\.' || { echo "psql != 16: $(psql --version)" >&2; fails=$((fails+1)); }
mysql --version | grep -q '8\.0' || { echo "mysql != 8.0: $(mysql --version)" >&2; fails=$((fails+1)); }
[ -x /usr/lib/postgresql/16/bin/postgres ] || { echo "MISSING postgres server" >&2; fails=$((fails+1)); }
[ -x /usr/sbin/mysqld ] || { echo "MISSING mysqld server" >&2; fails=$((fails+1)); }
echo "ok: postgresql 16 + mysql 8 (client+server)"

# Browsers + drivers + Selenium (run --version to confirm each launches with its runtime deps).
for tool in google-chrome-stable chromedriver microsoft-edge-stable msedgedriver firefox geckodriver selenium-server; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
google-chrome-stable --version >/dev/null || { echo "google-chrome fails to launch" >&2; fails=$((fails+1)); }
microsoft-edge-stable --version >/dev/null || { echo "microsoft-edge fails to launch" >&2; fails=$((fails+1)); }
firefox --version >/dev/null || { echo "firefox fails to launch" >&2; fails=$((fails+1)); }
for d in chromedriver msedgedriver geckodriver; do
  "$d" --version >/dev/null || { echo "$d fails to launch" >&2; fails=$((fails+1)); }
done
[ -f "${SELENIUM_JAR_PATH:-/usr/share/java/selenium-server.jar}" ] || { echo "MISSING selenium jar at ${SELENIUM_JAR_PATH:-?}" >&2; fails=$((fails+1)); }
# Driver env vars must point at a dir containing the driver (parity with ubuntu-latest).
[ -x "${CHROMEWEBDRIVER}/chromedriver" ] || { echo "CHROMEWEBDRIVER bad: ${CHROMEWEBDRIVER:-unset}" >&2; fails=$((fails+1)); }
[ -x "${EDGEWEBDRIVER}/msedgedriver" ] || { echo "EDGEWEBDRIVER bad: ${EDGEWEBDRIVER:-unset}" >&2; fails=$((fails+1)); }
[ -x "${GECKOWEBDRIVER}/geckodriver" ] || { echo "GECKOWEBDRIVER bad: ${GECKOWEBDRIVER:-unset}" >&2; fails=$((fails+1)); }
echo "ok: browsers (chrome/edge/firefox) + drivers + selenium present, launch, and driver env vars set"

# Build toolchain: unversioned gcc/cc/g++/make from build-essential + autotools (./configure chain).
for tool in gcc cc g++ make ninja autoconf automake libtoolize m4 bison flex swig patchelf fakeroot rpm; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
[ -f /usr/include/sqlite3.h ] || { echo "MISSING: libsqlite3-dev headers" >&2; fails=$((fails+1)); }
echo "ok: build toolchain + autotools"

# Dev headers for common native extensions (pylibmc, mysqlclient, python-ldap, pycurl, pysasl…).
# Compile-check via gcc so multiarch include dirs (curl/gmp) are covered like a real build.
for hdr in libmemcached/memcached.h ldap.h sasl/sasl.h krb5.h gmp.h curl/curl.h; do
  echo "#include <$hdr>" | gcc -fsyntax-only -xc - 2>/dev/null \
    || { echo "MISSING dev header: $hdr" >&2; fails=$((fails+1)); }
done
mycfg=$(command -v mariadb_config || command -v mysql_config || true)
if [ -n "$mycfg" ]; then
  read -ra myinc <<< "$("$mycfg" --include)"
  echo '#include <mysql.h>' | gcc -fsyntax-only -xc - "${myinc[@]}" 2>/dev/null \
    || { echo "MISSING dev header: mysql.h (default-libmysqlclient-dev)" >&2; fails=$((fails+1)); }
else
  echo "MISSING: mariadb_config/mysql_config" >&2; fails=$((fails+1))
fi
echo "ok: native-extension dev headers (memcached/mysql/ldap/sasl/krb5/gmp/curl)"

# More native-build dev headers (imaging, crypto, compression, DB/ODBC, systemd, kafka) + build tools.
for hdr in sodium.h magic.h snappy-c.h sql.h systemd/sd-bus.h librdkafka/rdkafka.h lcms2.h \
           webp/decode.h tiff.h gdbm.h zstd.h lz4.h bzlib.h lzma.h readline/readline.h uuid/uuid.h; do
  echo "#include <$hdr>" | gcc -fsyntax-only -xc - 2>/dev/null \
    || { echo "MISSING dev header: $hdr" >&2; fails=$((fails+1)); }
done
for tool in protoc ccache meson; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
echo "ok: extra dev headers (sodium/magic/snappy/odbc/systemd/rdkafka/imaging/compression) + protoc/ccache/meson"

for tool in shellcheck parallel hg python perl file tree brotli pigz lz4 xz zsync \
            mediainfo makeinfo sshpass pollinate aria2c upx certutil; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
{ command -v 7z >/dev/null || command -v 7za >/dev/null; } || { echo "MISSING: 7z/7za" >&2; fails=$((fails+1)); }
[ -x /usr/bin/time ] || { echo "MISSING: /usr/bin/time" >&2; fails=$((fails+1)); }
command -v locale-gen >/dev/null || { echo "MISSING: locale-gen" >&2; fails=$((fails+1)); }
{ command -v haveged >/dev/null || [ -x /usr/sbin/haveged ]; } || { echo "MISSING: haveged" >&2; fails=$((fails+1)); }
echo "ok: utilities (shellcheck/7z/parallel/hg/python/perl/...) present"

command -v Xvfb >/dev/null || { echo "MISSING: Xvfb" >&2; fails=$((fails+1)); }
for tool in dig nc telnet ping netstat ifconfig getfacl ftp wish; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
[ -f /usr/share/fonts/truetype/noto/NotoColorEmoji.ttf ] || { echo "MISSING: noto color emoji font" >&2; fails=$((fails+1)); }
echo "ok: xvfb + network diagnostics + acl/ftp/tk/emoji-font"

# Action archive cache (full image only, parity with ubuntu-latest install-actions-cache.sh):
# env var set + prebaked action bundles so the runner resolves the default actions offline.
[ "${ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE:-}" = /opt/actionarchivecache ] \
  || { echo "ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE unset/wrong: ${ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE:-}" >&2; fails=$((fails+1)); }
shopt -s nullglob
archive_bundles=(/opt/actionarchivecache/actions_cache/*.tar.gz)
[ "${#archive_bundles[@]}" -gt 0 ] || { echo "action archive cache empty at /opt/actionarchivecache" >&2; fails=$((fails+1)); }
echo "ok: action archive cache (${#archive_bundles[@]} bundles)"

# ubuntu-latest parity extras.
yarn --version | grep -qx '1.22.22' || { echo "yarn != 1.22.22: $(yarn --version)" >&2; fails=$((fails+1)); }
[ "$(npm config get prefix)" = /usr/local ] || { echo "npm prefix != /usr/local: $(npm config get prefix)" >&2; fails=$((fails+1)); }
# `npm i -g` as runner without sudo: install a local package offline, run its bin, remove it.
npmt="$(mktemp -d)"
printf '{"name":"tempus-npm-smoke","version":"1.0.0","bin":{"tempus-npm-smoke":"cli.js"}}\n' > "$npmt/package.json"
printf '#!/usr/bin/env node\nconsole.log("ok");\n' > "$npmt/cli.js"
if npm install -g --offline --no-audit --no-fund "$npmt" >/dev/null 2>&1 && [ "$(tempus-npm-smoke)" = ok ]; then
  echo "ok: npm -g as $(id -un) without sudo"
else
  echo "npm -g as $(id -un) failed" >&2; fails=$((fails+1))
fi
npm uninstall -g tempus-npm-smoke >/dev/null 2>&1 || true
rm -rf "$npmt"

[ -w "${PIPX_HOME:-/nonexistent}" ] && [ -w "${PIPX_BIN_DIR:-/nonexistent}" ] \
  || { echo "PIPX_HOME/PIPX_BIN_DIR unset or not writable: ${PIPX_HOME:-} ${PIPX_BIN_DIR:-}" >&2; fails=$((fails+1)); }
[ "$(command -v ansible)" = "${PIPX_BIN_DIR:-}/ansible" ] || { echo "ansible not from PIPX_BIN_DIR: $(command -v ansible)" >&2; fails=$((fails+1)); }
echo "ok: pipx shared home/bin (${PIPX_HOME:-}, ${PIPX_BIN_DIR:-}) writable"

for t in clang-format clang-tidy run-clang-tidy; do
  readlink -f "$(command -v "$t")" | grep -q -- '-18' || { echo "$t is not clang 18: $(readlink -f "$(command -v "$t")")" >&2; fails=$((fails+1)); }
done
# lldb only for 18: noble's python3-lldb-N packages conflict with each other (ubuntu-latest's
# sequential installs leave only the last one, 18, too).
for tool in lldb-18 ld.lld-16 ld.lld-17 ld.lld-18; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
echo "ok: clang 18 default for clang-format/clang-tidy/run-clang-tidy; lldb 18; lld 16/17/18"

for pkg in gnupg2 libicu70 ssh ant-optional; do
  dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q 'install ok installed' || { echo "MISSING package: $pkg" >&2; fails=$((fails+1)); }
done
[ -x /usr/sbin/sshd ] || { echo "MISSING: sshd" >&2; fails=$((fails+1)); }
compgen -G '/etc/ssh/ssh_host_*_key' >/dev/null && { echo "SSH host private keys baked into the image" >&2; fails=$((fails+1)); }
[ "$(command -v conda)" = /usr/bin/conda ] || { echo "conda not at /usr/bin/conda: $(command -v conda)" >&2; fails=$((fails+1)); }
echo "ok: gnupg2, libicu70, ssh (no host keys), ant-optional, conda symlink"

grep -q '^github.com ssh-ed25519 ' /etc/ssh/ssh_known_hosts || { echo "MISSING github.com in ssh_known_hosts" >&2; fails=$((fails+1)); }
grep -q '^ssh.dev.azure.com ssh-rsa ' /etc/ssh/ssh_known_hosts || { echo "MISSING ssh.dev.azure.com in ssh_known_hosts" >&2; fails=$((fails+1)); }
git config --system --get-all safe.directory | grep -qx '\*' || { echo "git safe.directory=* not set" >&2; fails=$((fails+1)); }
echo "ok: system ssh_known_hosts (github.com, ssh.dev.azure.com) + git safe.directory"

[ "$(command -v docker-credential-ecr-login)" = /usr/bin/docker-credential-ecr-login ] \
  || { echo "ecr helper not at /usr/bin: $(command -v docker-credential-ecr-login)" >&2; fails=$((fails+1)); }
docker-credential-ecr-login version 2>&1 | grep -q '0.12.0' || { echo "ecr helper != 0.12.0: $(docker-credential-ecr-login version 2>&1)" >&2; fails=$((fails+1)); }
echo "ok: amazon-ecr-credential-helper 0.12.0"

for b in chromium chromium-browser; do
  [ "$(readlink -f "$(command -v "$b")")" = /usr/local/share/chromium/chrome-linux/chrome ] || { echo "$b link bad" >&2; fails=$((fails+1)); }
done
chromium --version >/dev/null || { echo "chromium fails to launch" >&2; fails=$((fails+1)); }
[ -x "${CHROME_BIN:-/nonexistent}" ] || { echo "CHROME_BIN bad: ${CHROME_BIN:-unset}" >&2; fails=$((fails+1)); }
echo "ok: chromium snapshot + CHROME_BIN"

# Env contract (ubuntu-latest /etc/environment).
for v in 1_25 1_26; do
  var="GOROOT_${v}_X64"; [ -x "${!var:-/nonexistent}/bin/go" ] || { echo "$var bad: ${!var:-unset}" >&2; fails=$((fails+1)); }
done
[ "${ACCEPT_EULA:-}" = Y ] || { echo "ACCEPT_EULA != Y" >&2; fails=$((fails+1)); }
[ "${HOMEBREW_NO_AUTO_UPDATE:-}" = 1 ] && [ "${HOMEBREW_CLEANUP_PERIODIC_FULL_DAYS:-}" = 3650 ] || { echo "HOMEBREW_* env unset" >&2; fails=$((fails+1)); }
[ "${BOOTSTRAP_HASKELL_NONINTERACTIVE:-}" = 1 ] || { echo "BOOTSTRAP_HASKELL_NONINTERACTIVE unset" >&2; fails=$((fails+1)); }
[[ "${USE_BAZEL_FALLBACK_VERSION:-}" == silent:* ]] || { echo "USE_BAZEL_FALLBACK_VERSION bad: ${USE_BAZEL_FALLBACK_VERSION:-unset}" >&2; fails=$((fails+1)); }
[ -x "${SWIFT_PATH:-/nonexistent}/swift" ] || { echo "SWIFT_PATH bad: ${SWIFT_PATH:-unset}" >&2; fails=$((fails+1)); }
[ -e /usr/local/lib/libsourcekitdInProc.so ] || { echo "MISSING /usr/local/lib/libsourcekitdInProc.so" >&2; fails=$((fails+1)); }
[ "${XDG_CONFIG_HOME:-}" = "$HOME/.config" ] && [ -w "$XDG_CONFIG_HOME" ] && [ -d "$XDG_CONFIG_HOME/configstore" ] \
  || { echo "XDG_CONFIG_HOME bad: ${XDG_CONFIG_HOME:-unset}" >&2; fails=$((fails+1)); }
compgen -G "${RUNNER_TOOL_CACHE}/CodeQL/*/x64/pinned-version" >/dev/null || { echo "MISSING CodeQL pinned-version marker" >&2; fails=$((fails+1)); }
echo "ok: env contract (GOROOT_*_X64, ACCEPT_EULA, HOMEBREW_*, SWIFT_PATH, XDG_CONFIG_HOME, bazel fallback) + CodeQL marker"

[ "$fails" -eq 0 ] || { echo "SMOKE FAILURES (tools): $fails" >&2; exit 1; }
echo "OK: base tools present"
