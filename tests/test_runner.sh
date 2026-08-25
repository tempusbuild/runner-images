#!/usr/bin/env bash
set -euo pipefail

# Identity contract: unprivileged runner, uid 1001 (ARC dind volumes), passwordless sudo.
[ "$(id -un)" = "runner" ] || { echo "NOT runner user: $(id -un)" >&2; exit 1; }
[ "$(id -u)" = "1001" ] || { echo "runner uid != 1001: $(id -u)" >&2; exit 1; }
sudo -n true || { echo "passwordless sudo broken" >&2; exit 1; }
echo "ok: user runner (uid 1001), passwordless sudo"

# runner-agent is required for gha-runner-scale-set (ARC needs it).
# Smoke tests for the rest of the toolchain do not cover it — assert explicitly that the agent is present and works.
for f in /home/runner/run.sh /home/runner/config.sh; do
  [ -x "$f" ] || { echo "MISSING/not executable: $f" >&2; exit 1; }
  echo "ok: $f"
done
[ -e /home/runner/bin/Runner.Listener ] || { echo "MISSING: Runner.Listener" >&2; exit 1; }
echo "ok: /home/runner/bin/Runner.Listener"

# The runner's node runtimes must run (using: node20 / node24), but without bundled npm
# (stripped in the Dockerfile — the runner does not need it and it pulled CVEs).
for v in node20 node24; do
  ver=$("/home/runner/externals/$v/bin/node" --version) || { echo "MISSING runtime: $v" >&2; exit 1; }
  echo "ok: $v runtime $ver"
  [ -e "/home/runner/externals/$v/bin/npm" ] && { echo "UNEXPECTED: bundled npm in $v not stripped" >&2; exit 1; }
done

echo "OK: runner-agent present, node20/node24 runtimes work, externals npm removed"
