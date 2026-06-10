#!/usr/bin/env bash
set -euo pipefail

# Everything packages.txt promises as a CLI (gnupg ships the gpg binary).
for tool in git jq curl wget tar unzip zip zstd gpg sudo; do
  command -v "$tool" >/dev/null || { echo "MISSING: $tool" >&2; exit 1; }
  echo "ok: $tool"
done
echo "OK: base tools present"
