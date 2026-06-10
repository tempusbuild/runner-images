#!/usr/bin/env bash
set -euo pipefail

# The image ships only the Docker CLI; the daemon is provided by the ARC dind sidecar. Check the CLI is present.
command -v docker >/dev/null || { echo "MISSING: docker CLI" >&2; exit 1; }
docker --version
docker buildx version
docker compose version
echo "OK: docker CLI, buildx and compose plugins present"
