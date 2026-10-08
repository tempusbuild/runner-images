#!/usr/bin/env bash
set -euo pipefail
fails=0
fail() { echo "$1" >&2; fails=$((fails+1)); }

# apt/dpkg defaults as on ubuntu-latest (configure-apt.sh, configure-dpkg.sh).
aptconf=$(apt-config dump)
for line in 'APT::Get::Assume-Yes "true";' 'APT::Get::AutomaticRemove "0";' 'APT::Get::HideAutoRemove "1";' \
            'DPkg::Options:: "--force-confdef";' 'DPkg::Options:: "--force-confold";' \
            'DPkg::Options:: "--force-unsafe-io";' 'Acquire::GzipIndexes "true";'; do
  grep -qixF "$line" <<<"$aptconf" || fail "apt config missing: $line"
done
# docker-clean is gone, so apt keeps downloaded .debs (cacheable /var/cache/apt/archives).
[ ! -e /etc/apt/apt.conf.d/docker-clean ] || fail "docker-clean still present"
! grep -qF '/var/cache/apt/archives/*.deb' <<<"$aptconf" || fail "apt still deletes downloaded .debs"
echo "ok: apt/dpkg defaults (assume-yes, confold, unsafe-io, kept .debs, compressed indexes)"

# Package lists are kept, so `apt-get install` works without an `apt-get update` first.
compgen -G '/var/lib/apt/lists/*_noble_main_binary-amd64_Packages*' >/dev/null || fail "Ubuntu package lists missing"
compgen -G '/var/lib/apt/lists/packages.microsoft.com_ubuntu_24.04_prod_*Packages*' >/dev/null \
  || fail "Microsoft prod package list missing"
redis_policy=$(apt-cache policy redis-server)
grep -q 'Candidate: [0-9]' <<<"$redis_policy" || fail "apt has no candidate for redis-server (lists empty?)"
echo "ok: apt package lists present ($(sudo du -sh /var/lib/apt/lists | cut -f1))"

# /etc/environment mirrors the image ENV (literal values, no per-session or build-only vars) and
# reaches sudo sessions through pam_env.
[ "$(stat -c '%U %a' /etc/environment)" = "root 644" ] || fail "/etc/environment owner/mode: $(stat -c '%U %a' /etc/environment)"
grep -Eq '^(HOME|HOSTNAME|PWD|IMAGE_VERSION|RUNNER_VERSION)=|_SHA(256|512)=' /etc/environment && fail "/etc/environment has session/build-only vars"
grep -qF '$' /etc/environment && fail "/etc/environment has unexpanded references"
for v in ImageOS ImageVersion PATH LANG JAVA_HOME ANDROID_HOME AGENT_TOOLSDIRECTORY XDG_CONFIG_HOME; do
  grep -qxF "${v}=${!v-}" /etc/environment || fail "/etc/environment: ${v} missing or != image ENV"
done
while IFS='=' read -r k v; do
  [ "${!k-}" = "$v" ] || fail "/etc/environment ${k} differs from the image ENV"
done < /etc/environment
sudo_env=$(sudo env)
for v in ImageOS ImageVersion ANDROID_HOME JAVA_HOME_17_X64 HOMEBREW_NO_AUTO_UPDATE; do
  grep -qxF "${v}=${!v-}" <<<"$sudo_env" || fail "sudo env lacks ${v} (pam_env)"
done
echo "ok: /etc/environment = image ENV ($(wc -l < /etc/environment) vars), applied to sudo"

[ "${ImageOS:-}" = ubuntu24 ] || fail "ImageOS != ubuntu24: ${ImageOS:-unset}"
[[ "${ImageVersion:-}" =~ ^(v[0-9]{8}|dev)$ ]] || fail "ImageVersion not the build version: ${ImageVersion:-unset}"
echo "ok: ImageOS=${ImageOS} ImageVersion=${ImageVersion}"

# UTF-8 locale for the image and for sudo/login sessions.
shell_locale=$(locale)
grep -qx 'LANG=C.UTF-8' <<<"$shell_locale" || fail "LANG != C.UTF-8: ${shell_locale%%$'\n'*}"
grep -qx 'LANG=C.UTF-8' /etc/default/locale || fail "/etc/default/locale lacks LANG=C.UTF-8"
sudo_locale=$(sudo locale)
grep -qx 'LANG=C.UTF-8' <<<"$sudo_locale" || fail "sudo LANG != C.UTF-8"
[ "$(ruby -e 'print Encoding.default_external')" = UTF-8 ] || fail "ruby default_external != UTF-8"
java_props=$(java -XshowSettings:properties -version 2>&1)
grep -q 'file.encoding = UTF-8' <<<"$java_props" || fail "java file.encoding != UTF-8"
echo "ok: C.UTF-8 locale (shell, sudo, ruby, java)"

# Podman short names resolve via docker.io/quay.io; Ubuntu's registries.conf.d stays intact.
grep -qxF 'unqualified-search-registries = ["docker.io", "quay.io"]' /etc/containers/registries.conf \
  || fail "registries.conf lacks unqualified-search-registries"
[ -s /etc/containers/registries.conf.d/shortnames.conf ] || fail "registries.conf.d/shortnames.conf missing"
echo "ok: containers registries.conf"

# /usr/local/bin is world-writable without +t, as on ubuntu-latest; the shim itself stays root 0755.
[ "$(stat -c '%U:%G %a' /usr/local/bin)" = "root:root 777" ] || fail "/usr/local/bin: $(stat -c '%U:%G %a' /usr/local/bin)"
[ "$(stat -c '%U %a' /usr/local/bin/systemctl)" = "root 755" ] || fail "systemctl shim: $(stat -c '%U %a' /usr/local/bin/systemctl)"
[ "$(stat -c '%u' /usr/local/lib/node_modules)" = 1001 ] || fail "/usr/local/lib/node_modules not owned by runner"
echo "ok: /usr/local/bin 0777, systemctl shim root 0755"

[ "$fails" -eq 0 ] || { echo "SMOKE FAILURES (system): $fails" >&2; exit 1; }
echo "OK: system config (apt/dpkg, package lists, /etc/environment, locale, registries, /usr/local/bin)"
