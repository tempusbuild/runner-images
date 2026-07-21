#!/usr/bin/env bash
set -euo pipefail
fails=0

# Everything packages.txt promises as a CLI (gnupg ships the gpg binary; openssh-client ships ssh).
for tool in git git-lfs jq curl wget ssh rsync tar unzip zip zstd sqlite3 cmake clang gpg sudo; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
  echo "ok: $tool"
done

# Pinned/extra CLIs not from apt: yq (pinned binary), pipx (pip), corepack-managed JS managers.
for tool in yq yarn pnpm pipx; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
  echo "ok: $tool"
done

# Pinned-binary versions must match the Dockerfile pins (parity with ubuntu-latest).
cmake --version | grep -q '3.31.12' || { echo "cmake != 3.31.12: $(cmake --version | head -1)" >&2; fails=$((fails+1)); }
cmake4 --version | grep -q '4.3.3' || { echo "cmake4 != 4.3.3: $(cmake4 --version | head -1)" >&2; fails=$((fails+1)); }
git-lfs version | grep -q '3.7.1' || { echo "git-lfs != 3.7.1: $(git-lfs version)" >&2; fails=$((fails+1)); }
pipx --version | grep -q '1.16.1' || { echo "pipx != 1.16.1: $(pipx --version)" >&2; fails=$((fails+1)); }
kubectl version --client 2>/dev/null | grep -q 'v1.36.2' || { echo "kubectl != 1.36.2: $(kubectl version --client 2>/dev/null | head -1)" >&2; fails=$((fails+1)); }
helm version --short 2>/dev/null | grep -q 'v3.21.3' || { echo "helm != 3.21.3: $(helm version --short 2>/dev/null)" >&2; fails=$((fails+1)); }
echo "ok: cmake/git-lfs/pipx/kubectl/helm at pinned versions"

for cc in gcc-12 gcc-13 gcc-14 g++-12 g++-13 g++-14 clang-16 clang-17 clang-18 \
          clang-format-16 clang-format-17 clang-format-18 clang-tidy-16 clang-tidy-17 clang-tidy-18; do
  command -v "$cc" >/dev/null || { echo "MISSING: $cc" >&2; fails=$((fails+1)); }
done
zstd --version | grep -q 'v1.5.7' || { echo "zstd != 1.5.7: $(zstd --version)" >&2; fails=$((fails+1)); }
echo "ok: gcc 12/13/14, clang 16/17/18, zstd 1.5.7"

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
echo "ok: npm globals (tsc/webpack/webpack-cli/grunt/gulp)"

# PHP stack + misc tools (Pulumi, n, nvm, git-ftp, Sphinx search).
for tool in php composer phpunit git-ftp pulumi n; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; fails=$((fails+1)); }
done
php --version | grep -q 'PHP 8.3' || { echo "php != 8.3: $(php --version | head -1)" >&2; fails=$((fails+1)); }
# Xdebug + PCOV are both installed; only Xdebug is enabled (parity with ubuntu-latest):
# pcov stays in mods-available (installed) but is unlinked from conf.d (not loaded).
php -m | grep -qi xdebug || { echo "MISSING: xdebug not enabled" >&2; fails=$((fails+1)); }
[ -f /etc/php/8.3/mods-available/pcov.ini ] || { echo "MISSING: pcov not installed" >&2; fails=$((fails+1)); }
! php -m | grep -qi pcov || { echo "pcov should be installed but disabled" >&2; fails=$((fails+1)); }
{ command -v searchd >/dev/null || command -v indexer >/dev/null; } || { echo "MISSING sphinxsearch" >&2; fails=$((fails+1)); }
[ -s "${NVM_DIR:-/usr/local/nvm}/nvm.sh" ] || { echo "MISSING nvm at ${NVM_DIR:-unset}" >&2; fails=$((fails+1)); }
echo "ok: php 8.3 + composer/phpunit, git-ftp, pulumi, n, nvm, sphinxsearch"

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

[ "$fails" -eq 0 ] || { echo "SMOKE FAILURES (tools): $fails" >&2; exit 1; }
echo "OK: base tools present"
