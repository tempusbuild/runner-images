#!/usr/bin/env bash
set -euo pipefail

# The minimal variant has no node/docker/python/unzip — the standard test_tools.sh (which needs unzip)
# does not fit it. Check only the base set that minimal actually contains.
for tool in ca-certificates curl git jq sudo tar; do
  case "$tool" in
    ca-certificates)
      [ -e /etc/ssl/certs/ca-certificates.crt ] || { echo "MISSING: ca-certificates bundle" >&2; exit 1; } ;;
    *)
      command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; exit 1; } ;;
  esac
  echo "ok: $tool"
done
echo "OK: minimal base tools present"
