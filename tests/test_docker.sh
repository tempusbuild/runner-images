#!/usr/bin/env bash
set -euo pipefail

# The image ships only the Docker CLI; the daemon is provided by the ARC dind sidecar. Check the CLI is present.
command -v docker >/dev/null || { echo "MISSING: docker CLI" >&2; exit 1; }
docker --version
docker buildx version
docker compose version

# runner must be in the docker group at gid 123 — the ARC dind sidecar creates docker.sock with that
# gid, so a mismatch means permission denied talking to the daemon.
getent group docker | grep -q ':123:' || { echo "docker group not at gid 123: $(getent group docker)" >&2; exit 1; }
id -nG runner | tr ' ' '\n' | grep -qx docker || { echo "runner not in docker group: $(id runner)" >&2; exit 1; }
echo "ok: runner in docker group (gid 123)"

echo "OK: docker CLI, buildx and compose plugins present"
