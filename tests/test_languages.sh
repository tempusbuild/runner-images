#!/usr/bin/env bash
set -euo pipefail
fails=0

echo "node:   $(node --version)"
echo "npm:    $(npm --version)"
echo "python: $(python3 --version)"
echo "pip:    $(pip3 --version)"
echo "pipx:   $(pipx --version)"
echo "gh:     $(gh --version | head -1)"
echo "rustc:  $(rustc --version)"
echo "cargo:  $(cargo --version)"

node --version >/dev/null
python3 --version >/dev/null

# Env expected by setup-* actions: without ImageOS, setup-python/-node/-go fail on a self-hosted runner.
[ -n "${ImageOS:-}" ] || { echo "MISSING env ImageOS" >&2; fails=$((fails+1)); }
[ -d "${RUNNER_TOOL_CACHE:-/nonexistent}" ] || { echo "MISSING dir RUNNER_TOOL_CACHE" >&2; fails=$((fails+1)); }
[ -w "${RUNNER_TOOL_CACHE}" ] || { echo "RUNNER_TOOL_CACHE not writable by user $(id -un)" >&2; fails=$((fails+1)); }
echo "ok: ImageOS=$ImageOS RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE (writable)"

# pipx installs CLIs into ~/.local/bin — it must be on PATH (parity with GitHub-hosted runners).
[[ ":$PATH:" == *":/home/runner/.local/bin:"* ]] || { echo "MISSING /home/runner/.local/bin in PATH" >&2; fails=$((fails+1)); }
echo "ok: /home/runner/.local/bin on PATH"

# /etc/pip.conf opts system pip out of PEP 668 (as ubuntu-latest).
python3 -m pip config list 2>/dev/null | grep -qx "global.break-system-packages='true'" \
  || { echo "/etc/pip.conf break-system-packages not set" >&2; fails=$((fails+1)); }
echo "ok: system pip break-system-packages"

# venv + pip (PEP 668: inside a venv it is not externally-managed) — a typical Python CI path.
python3 -m venv /tmp/venv
/tmp/venv/bin/pip install --quiet --upgrade pip
/tmp/venv/bin/pip install --quiet requests
/tmp/venv/bin/python -c "import requests; print('ok: venv pip install requests', requests.__version__)"

# Build a native wheel from source — validates build-essential + python3-dev + libffi-dev.
/tmp/venv/bin/pip install --quiet --no-binary :all: cffi
/tmp/venv/bin/python -c "import cffi; print('ok: native build cffi', cffi.__version__)"
rm -rf /tmp/venv

# Python toolcache (matches setup-python): each baked version runs and has a .complete marker.
for v in 3.10.22 3.11.17 3.12.15 3.13.16 3.14.8; do
  py="${RUNNER_TOOL_CACHE}/Python/${v}/x64/bin/python3"
  [ -x "$py" ] || { echo "MISSING python toolcache $v ($py)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/Python/${v}/x64.complete" ] || { echo "MISSING marker Python/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: python toolcache $("$py" --version)"
done

# 3.10/3.11 bundle setuptools — must be the CVE-fixed version upgraded in the Dockerfile.
for v in 3.10.22 3.11.17; do
  "${RUNNER_TOOL_CACHE}/Python/${v}/x64/bin/python3" -c 'import setuptools; raise SystemExit(0 if int(setuptools.__version__.split(".")[0]) >= 82 else 1)' \
    || { echo "setuptools not upgraded in toolcache ${v}" >&2; fails=$((fails+1)); }
  echo "ok: setuptools fixed in toolcache ${v}"
done

# Node toolcache (matches setup-node): each baked version runs and has a .complete marker.
for v in 22.23.3 24.21.0; do
  node_bin="${RUNNER_TOOL_CACHE}/node/${v}/x64/bin/node"
  [ -x "$node_bin" ] || { echo "MISSING node toolcache $v ($node_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/node/${v}/x64.complete" ] || { echo "MISSING marker node/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: node toolcache $("$node_bin" --version)"
done

# Go toolcache (matches setup-go): each baked version runs and has a .complete marker.
for v in 1.25.14 1.26.8; do
  go_bin="${RUNNER_TOOL_CACHE}/go/${v}/x64/bin/go"
  [ -x "$go_bin" ] || { echo "MISSING go toolcache $v ($go_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/go/${v}/x64.complete" ] || { echo "MISSING marker go/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: go toolcache $("$go_bin" version)"
done

# Minimal Go build — validates the toolchain is runnable (using the newest version).
GOTOOLCACHE_GO="${RUNNER_TOOL_CACHE}/go/1.26.8/x64/bin/go"
mkdir -p /tmp/gohello
printf 'package main\nimport "fmt"\nfunc main(){fmt.Println("ok")}\n' > /tmp/gohello/main.go
( cd /tmp/gohello \
  && GOCACHE=/tmp/gocache GOPATH=/tmp/gopath HOME=/tmp "$GOTOOLCACHE_GO" build -o hello main.go \
  && ./hello | grep -q ok )
echo "ok: go build hello"
rm -rf /tmp/gohello /tmp/gocache /tmp/gopath

# Ruby toolcache (matches ruby/setup-ruby): each baked version runs and has a .complete marker.
for v in 3.2.11 3.3.12 3.4.11 4.0.7; do
  ruby_bin="${RUNNER_TOOL_CACHE}/Ruby/${v}/x64/bin/ruby"
  [ -x "$ruby_bin" ] || { echo "MISSING ruby toolcache $v ($ruby_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/Ruby/${v}/x64.complete" ] || { echo "MISSING marker Ruby/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: ruby toolcache $("$ruby_bin" --version)"
done

# PyPy toolcache (matches actions/setup-pypy): each baked version runs and has a .complete marker.
for v in 3.9.19 3.10.16 3.11.16; do
  pypy_bin="${RUNNER_TOOL_CACHE}/PyPy/${v}/x64/bin/python3"
  [ -x "$pypy_bin" ] || { echo "MISSING pypy toolcache $v ($pypy_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/PyPy/${v}/x64.complete" ] || { echo "MISSING marker PyPy/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: pypy toolcache $("$pypy_bin" --version 2>&1 | head -1)"
done

# Default Go on PATH (parity with ubuntu-latest): the newest baked version is the system `go`, so
# tools that assume a system Go (e.g. pre-commit golang hooks) do not try to download a toolchain.
command -v go >/dev/null || { echo "MISSING: go not on default PATH" >&2; fails=$((fails+1)); }
go version | grep -q 'go1.26.8 ' || { echo "default go != 1.26.8: $(go version)" >&2; fails=$((fails+1)); }
echo "ok: default go on PATH $(go version)"

rustc --version | grep -q '1.99.0' || { echo "rustc != 1.99.0: $(rustc --version)" >&2; fails=$((fails+1)); }
cargo --version >/dev/null
# rustup/cargo use their default homes (RUSTUP_HOME/CARGO_HOME unset, as ubuntu-latest): ~/.rustup and
# ~/.cargo link to the shared, runner-owned install, so crates and toolchains land there.
[ -z "${RUSTUP_HOME:-}" ] && [ -z "${CARGO_HOME:-}" ] || { echo "RUSTUP_HOME/CARGO_HOME set" >&2; fails=$((fails+1)); }
[ "$(command -v cargo)" = "$HOME/.cargo/bin/cargo" ] || { echo "cargo not from ~/.cargo/bin: $(command -v cargo)" >&2; fails=$((fails+1)); }
[ "$(readlink -f "$HOME/.cargo/registry")" = /usr/local/cargo/registry ] && [ -w "$HOME/.cargo" ] \
  || { echo "\$HOME/.cargo does not resolve to a writable /usr/local/cargo" >&2; fails=$((fails+1)); }
[ "$(readlink -f "$HOME/.rustup")" = /usr/local/rustup ] || { echo "\$HOME/.rustup does not resolve to /usr/local/rustup" >&2; fails=$((fails+1)); }
rust_toolchain=$(rustup show active-toolchain 2>/dev/null || true)
[[ "$rust_toolchain" == 1.99.0* ]] || { echo "rustup active toolchain != 1.99.0: ${rust_toolchain}" >&2; fails=$((fails+1)); }
cargo install --list >/dev/null || { echo "cargo install --list failed" >&2; fails=$((fails+1)); }
echo "ok: rust $(rustc --version), $(cargo --version)"

# Java: default Temurin 17 on PATH + every JDK reachable via JAVA_HOME_<v>_X64 (parity).
java -version 2>&1 | grep -q 'version "17\.' || { echo "default java != 17: $(java -version 2>&1 | head -1)" >&2; fails=$((fails+1)); }
for jh in JAVA_HOME_8_X64 JAVA_HOME_11_X64 JAVA_HOME_17_X64 JAVA_HOME_21_X64 JAVA_HOME_25_X64; do
  d="${!jh-}"; [ -x "${d}/bin/javac" ] || { echo "MISSING $jh ($d)" >&2; fails=$((fails+1)); }
done
echo "ok: java default 17 + JDKs 8/11/17/21/25"

# Java toolcache (matches setup-java, distribution temurin): each JDK linked + .complete marker.
for n in 8 11 17 21 25; do
  jh="JAVA_HOME_${n}_X64"; found=0
  for d in "${RUNNER_TOOL_CACHE}/Java_Temurin-Hotspot_jdk/${n}".*; do
    [ "$(readlink -f "$d/x64")" = "${!jh-}" ] && [ -f "$d/x64.complete" ] && found=1
  done
  [ "$found" -eq 1 ] || { echo "MISSING Java ${n} toolcache entry" >&2; fails=$((fails+1)); }
done
for t in javac jar keytool; do
  readlink -f "$(command -v "$t")" | grep -q 'temurin-17-jdk' || { echo "$t not Temurin 17 (update-java-alternatives)" >&2; fails=$((fails+1)); }
done
[ -e "${ANT_HOME:-/nonexistent}/lib/ant-junit.jar" ] || { echo "ANT_HOME/ant-optional bad: ${ANT_HOME:-unset}" >&2; fails=$((fails+1)); }
[ -x "${GRADLE_HOME:-/nonexistent}/bin/gradle" ] || { echo "GRADLE_HOME bad: ${GRADLE_HOME:-unset}" >&2; fails=$((fails+1)); }
echo "ok: Java toolcache 8/11/17/21/25, alternatives on 17, ANT_HOME, GRADLE_HOME"

# JDK trees are runner-owned (ubuntu-latest makes them world-writable), so a JDK can be modified
# without sudo. cacerts stays root-owned: it links to the shared adoptium-ca-certificates store.
for jh in JAVA_HOME_8_X64 JAVA_HOME_11_X64 JAVA_HOME_17_X64 JAVA_HOME_21_X64 JAVA_HOME_25_X64; do
  [ -w "$(readlink -f "${!jh-}")/lib" ] || [ -w "$(readlink -f "${!jh-}")/jre/lib" ] \
    || { echo "$jh not writable by $(id -un)" >&2; fails=$((fails+1)); }
done

# Ruby (system default on PATH, parity with ubuntu-latest).
ruby --version | grep -q 'ruby 3.2' || { echo "ruby != 3.2: $(ruby --version)" >&2; fails=$((fails+1)); }
echo "ok: ruby $(ruby --version)"

swift --version >/dev/null 2>&1 || { echo "swift fails to run" >&2; fails=$((fails+1)); }
julia --version | grep -q '1.13' || { echo "julia != 1.13: $(julia --version)" >&2; fails=$((fails+1)); }
{ kotlinc -version 2>&1 | grep -q '2.4'; } || { echo "kotlin != 2.4" >&2; fails=$((fails+1)); }
ghc --version | grep -q '9.14' || { echo "ghc != 9.14: $(ghc --version)" >&2; fails=$((fails+1)); }
# ghcup's tree is runner-writable and ~/.ghcup links to it (as ubuntu-latest).
[ "${GHCUP_INSTALL_BASE_PREFIX:-}" = /usr/local ] && [ -w /usr/local/.ghcup ] && [ "$(readlink -f "$HOME/.ghcup")" = /usr/local/.ghcup ] \
  || { echo "ghcup home not shared/writable (GHCUP_INSTALL_BASE_PREFIX=${GHCUP_INSTALL_BASE_PREFIX:-unset})" >&2; fails=$((fails+1)); }
ghcup --offline set cabal "$(cabal --numeric-version)" >/dev/null 2>&1 || { echo "ghcup set fails as $(id -un)" >&2; fails=$((fails+1)); }
dotnet --list-sdks >/dev/null 2>&1 || { echo "dotnet fails to run" >&2; fails=$((fails+1)); }
# .NET at setup-dotnet's default dir, writable by runner, global tools dir on PATH.
[ "${DOTNET_ROOT:-}" = /usr/share/dotnet ] && [ "$(readlink -f "$(command -v dotnet)")" = /usr/share/dotnet/dotnet ] \
  || { echo "dotnet not at /usr/share/dotnet (DOTNET_ROOT=${DOTNET_ROOT:-unset})" >&2; fails=$((fails+1)); }
[ -w /usr/share/dotnet ] || { echo "/usr/share/dotnet not writable by $(id -un)" >&2; fails=$((fails+1)); }
[ "$(dotnet --list-sdks | wc -l)" -ge 11 ] || { echo "expected >=11 .NET SDKs: $(dotnet --list-sdks | wc -l)" >&2; fails=$((fails+1)); }
[ "$(command -v nbgv)" = "$HOME/.dotnet/tools/nbgv" ] || { echo "nbgv not in ~/.dotnet/tools: $(command -v nbgv)" >&2; fails=$((fails+1)); }
[ "${DOTNET_MULTILEVEL_LOOKUP:-}" = 0 ] && [ "${DOTNET_SKIP_FIRST_TIME_EXPERIENCE:-}" = 1 ] \
  || { echo "DOTNET_MULTILEVEL_LOOKUP/DOTNET_SKIP_FIRST_TIME_EXPERIENCE unset" >&2; fails=$((fails+1)); }
pwsh --version | grep -q '7.6' || { echo "pwsh != 7.6: $(pwsh --version)" >&2; fails=$((fails+1)); }
echo "ok: swift/julia/kotlin/haskell(ghc)/dotnet/powershell"

[ "$fails" -eq 0 ] || { echo "SMOKE FAILURES (languages): $fails" >&2; exit 1; }
echo "OK: languages present, venv+pip+native-build, Python/Go/Node/Ruby/PyPy toolcache, Rust, Java, Swift/Julia/Kotlin/Haskell/.NET/PowerShell working"
