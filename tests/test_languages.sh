#!/usr/bin/env bash
set -euo pipefail

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
[ -n "${ImageOS:-}" ] || { echo "MISSING env ImageOS" >&2; exit 1; }
[ -d "${RUNNER_TOOL_CACHE:-/nonexistent}" ] || { echo "MISSING dir RUNNER_TOOL_CACHE" >&2; exit 1; }
[ -w "${RUNNER_TOOL_CACHE}" ] || { echo "RUNNER_TOOL_CACHE not writable by user $(id -un)" >&2; exit 1; }
echo "ok: ImageOS=$ImageOS RUNNER_TOOL_CACHE=$RUNNER_TOOL_CACHE (writable)"

# pipx installs CLIs into ~/.local/bin — it must be on PATH (parity with GitHub-hosted runners).
[[ ":$PATH:" == *":/home/runner/.local/bin:"* ]] || { echo "MISSING /home/runner/.local/bin in PATH" >&2; exit 1; }
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
  [ -x "$py" ] || { echo "MISSING python toolcache $v ($py)" >&2; exit 1; }
  [ -f "${RUNNER_TOOL_CACHE}/Python/${v}/x64.complete" ] || { echo "MISSING marker Python/${v}/x64.complete" >&2; exit 1; }
  echo "ok: python toolcache $("$py" --version)"
done

# 3.10/3.11 bundle setuptools — must be the CVE-fixed version upgraded in the Dockerfile.
for v in 3.10.20 3.11.15; do
  "${RUNNER_TOOL_CACHE}/Python/${v}/x64/bin/python3" -c 'import setuptools; raise SystemExit(0 if int(setuptools.__version__.split(".")[0]) >= 82 else 1)' \
    || { echo "setuptools not upgraded in toolcache ${v}" >&2; exit 1; }
  echo "ok: setuptools fixed in toolcache ${v}"
done

# Go toolcache (matches setup-go): each baked version runs and has a .complete marker.
for v in 1.25.11 1.26.4; do
  go_bin="${RUNNER_TOOL_CACHE}/go/${v}/x64/bin/go"
  [ -x "$go_bin" ] || { echo "MISSING go toolcache $v ($go_bin)" >&2; exit 1; }
  [ -f "${RUNNER_TOOL_CACHE}/go/${v}/x64.complete" ] || { echo "MISSING marker go/${v}/x64.complete" >&2; exit 1; }
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

rustc --version | grep -q '1.95.0' || { echo "rustc != 1.95.0: $(rustc --version)" >&2; exit 1; }
cargo --version >/dev/null
echo "ok: rust $(rustc --version), $(cargo --version)"

echo "OK: languages present, venv+pip+native-build, Python and Go toolcache, Rust working"
