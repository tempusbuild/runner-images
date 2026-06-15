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
for v in 3.10.20 3.11.15 3.12.13 3.13.14 3.14.6; do
  py="${RUNNER_TOOL_CACHE}/Python/${v}/x64/bin/python3"
  [ -x "$py" ] || { echo "MISSING python toolcache $v ($py)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/Python/${v}/x64.complete" ] || { echo "MISSING marker Python/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: python toolcache $("$py" --version)"
done

# 3.10/3.11 bundle setuptools — must be the CVE-fixed version upgraded in the Dockerfile.
for v in 3.10.20 3.11.15; do
  "${RUNNER_TOOL_CACHE}/Python/${v}/x64/bin/python3" -c 'import setuptools; raise SystemExit(0 if int(setuptools.__version__.split(".")[0]) >= 82 else 1)' \
    || { echo "setuptools not upgraded in toolcache ${v}" >&2; fails=$((fails+1)); }
  echo "ok: setuptools fixed in toolcache ${v}"
done

# Node toolcache (matches setup-node): each baked version runs and has a .complete marker.
for v in 22.22.3 24.16.0; do
  node_bin="${RUNNER_TOOL_CACHE}/node/${v}/x64/bin/node"
  [ -x "$node_bin" ] || { echo "MISSING node toolcache $v ($node_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/node/${v}/x64.complete" ] || { echo "MISSING marker node/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: node toolcache $("$node_bin" --version)"
done

# Go toolcache (matches setup-go): each baked version runs and has a .complete marker.
for v in 1.25.11 1.26.4; do
  go_bin="${RUNNER_TOOL_CACHE}/go/${v}/x64/bin/go"
  [ -x "$go_bin" ] || { echo "MISSING go toolcache $v ($go_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/go/${v}/x64.complete" ] || { echo "MISSING marker go/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: go toolcache $("$go_bin" version)"
done

# Minimal Go build — validates the toolchain is runnable (using the newest version).
GOTOOLCACHE_GO="${RUNNER_TOOL_CACHE}/go/1.26.4/x64/bin/go"
mkdir -p /tmp/gohello
printf 'package main\nimport "fmt"\nfunc main(){fmt.Println("ok")}\n' > /tmp/gohello/main.go
( cd /tmp/gohello \
  && GOCACHE=/tmp/gocache GOPATH=/tmp/gopath HOME=/tmp "$GOTOOLCACHE_GO" build -o hello main.go \
  && ./hello | grep -q ok )
echo "ok: go build hello"
rm -rf /tmp/gohello /tmp/gocache /tmp/gopath

# Ruby toolcache (matches ruby/setup-ruby): each baked version runs and has a .complete marker.
for v in 3.2.11 3.3.11 3.4.9 4.0.5; do
  ruby_bin="${RUNNER_TOOL_CACHE}/Ruby/${v}/x64/bin/ruby"
  [ -x "$ruby_bin" ] || { echo "MISSING ruby toolcache $v ($ruby_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/Ruby/${v}/x64.complete" ] || { echo "MISSING marker Ruby/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: ruby toolcache $("$ruby_bin" --version)"
done

# PyPy toolcache (matches actions/setup-pypy): each baked version runs and has a .complete marker.
for v in 3.9.19 3.10.16 3.11.15; do
  pypy_bin="${RUNNER_TOOL_CACHE}/PyPy/${v}/x64/bin/python3"
  [ -x "$pypy_bin" ] || { echo "MISSING pypy toolcache $v ($pypy_bin)" >&2; fails=$((fails+1)); }
  [ -f "${RUNNER_TOOL_CACHE}/PyPy/${v}/x64.complete" ] || { echo "MISSING marker PyPy/${v}/x64.complete" >&2; fails=$((fails+1)); }
  echo "ok: pypy toolcache $("$pypy_bin" --version 2>&1 | head -1)"
done

# Default Go on PATH (parity with ubuntu-latest): the newest baked version is the system `go`, so
# tools that assume a system Go (e.g. pre-commit golang hooks) do not try to download a toolchain.
command -v go >/dev/null || { echo "MISSING: go not on default PATH" >&2; fails=$((fails+1)); }
go version | grep -q 'go1.26.4 ' || { echo "default go != 1.26.4: $(go version)" >&2; fails=$((fails+1)); }
echo "ok: default go on PATH $(go version)"

rustc --version | grep -q '1.96.0' || { echo "rustc != 1.96.0: $(rustc --version)" >&2; fails=$((fails+1)); }
cargo --version >/dev/null
echo "ok: rust $(rustc --version), $(cargo --version)"

# Java: default Temurin 17 on PATH + every JDK reachable via JAVA_HOME_<v>_X64 (parity).
java -version 2>&1 | grep -q 'version "17\.' || { echo "default java != 17: $(java -version 2>&1 | head -1)" >&2; fails=$((fails+1)); }
for jh in JAVA_HOME_8_X64 JAVA_HOME_11_X64 JAVA_HOME_17_X64 JAVA_HOME_21_X64 JAVA_HOME_25_X64; do
  d="${!jh}"; [ -x "${d}/bin/javac" ] || { echo "MISSING $jh ($d)" >&2; fails=$((fails+1)); }
done
echo "ok: java default 17 + JDKs 8/11/17/21/25"

# Ruby (system default on PATH, parity with ubuntu-latest).
ruby --version | grep -q 'ruby 3.2' || { echo "ruby != 3.2: $(ruby --version)" >&2; fails=$((fails+1)); }
echo "ok: ruby $(ruby --version)"

swift --version >/dev/null 2>&1 || { echo "swift fails to run" >&2; fails=$((fails+1)); }
julia --version | grep -q '1.12' || { echo "julia != 1.12: $(julia --version)" >&2; fails=$((fails+1)); }
{ kotlinc -version 2>&1 | grep -q '2.4'; } || { echo "kotlin != 2.4" >&2; fails=$((fails+1)); }
ghc --version | grep -q '9.14' || { echo "ghc != 9.14: $(ghc --version)" >&2; fails=$((fails+1)); }
dotnet --list-sdks >/dev/null 2>&1 || { echo "dotnet fails to run" >&2; fails=$((fails+1)); }
pwsh --version | grep -q '7.4' || { echo "pwsh != 7.4: $(pwsh --version)" >&2; fails=$((fails+1)); }
echo "ok: swift/julia/kotlin/haskell(ghc)/dotnet/powershell"

[ "$fails" -eq 0 ] || { echo "SMOKE FAILURES (languages): $fails" >&2; exit 1; }
echo "OK: languages present, venv+pip+native-build, Python/Go/Node/Ruby/PyPy toolcache, Rust, Java, Swift/Julia/Kotlin/Haskell/.NET/PowerShell working"
