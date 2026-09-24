#!/usr/bin/env bash
set -euo pipefail

# "Set up job" image info (full image only): /imagegeneration/imagedata.json in the ubuntu-latest
# format — exactly the OS and Runner Image groups, with the runner line matching the baked agent.
f=/imagegeneration/imagedata.json
[ -r "$f" ] || { echo "MISSING/unreadable: $f" >&2; exit 1; }

# The image sets ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT (ARC), which prefixes --version with trace logs.
runner_version="$(env -u ACTIONS_RUNNER_PRINT_LOG_TO_STDOUT /home/runner/bin/Runner.Listener --version | tail -n1)"
[[ "$runner_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo "unexpected runner --version output: ${runner_version}" >&2; exit 1; }

IMAGEDATA="$f" RUNNER_VERSION="$runner_version" python3 - <<'EOF'
import json, os, re, sys

with open(os.environ["IMAGEDATA"]) as fh:
    data = json.load(fh)

errors = []
groups = [entry.get("group") for entry in data] if isinstance(data, list) else None
if groups != ["Operating System", "Runner Image"]:
    errors.append(f"groups != [Operating System, Runner Image]: {groups}")
else:
    os_detail, image_detail = data[0]["detail"], data[1]["detail"]
    if not os_detail.startswith("Ubuntu\n24.04"):
        errors.append(f"unexpected OS detail: {os_detail!r}")
    lines = image_detail.split("\n")
    keys = [line.split(": ", 1)[0] for line in lines]
    if keys != ["Image", "Version", "Runner", "Included Software", "Image Release"]:
        errors.append(f"unexpected Runner Image lines: {lines}")
    version = lines[1].split(": ", 1)[-1]
    if not re.fullmatch(r"v\d{8}|dev", version):
        errors.append(f"Version must be vYYYYMMDD (CI) or dev (local): {version!r}")
    if "Image: ubuntu-24.04" not in lines:
        errors.append("missing 'Image: ubuntu-24.04'")
    if f"Runner: {os.environ['RUNNER_VERSION']}" not in lines:
        errors.append(f"Runner line != baked agent {os.environ['RUNNER_VERSION']}: {lines}")

for e in errors:
    print(e, file=sys.stderr)
sys.exit(1 if errors else 0)
EOF
echo "ok: $f valid (OS + Runner Image, runner ${runner_version})"

[ "$(stat -c '%U %a' "$f")" = "root 644" ] || { echo "unexpected owner/mode: $(stat -c '%U %a' "$f")" >&2; exit 1; }

# .setup_info is written by the infra at runtime; the image must not ship one.
[ ! -e /home/runner/.setup_info ] || { echo "UNEXPECTED: /home/runner/.setup_info baked into the image" >&2; exit 1; }

echo "OK: image data present and consistent, no baked .setup_info"
