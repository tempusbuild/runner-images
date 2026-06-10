set shell := ["bash", "-euo", "pipefail", "-c"]

image := "tempusbuild/runner-ubuntu-24.04:dev"
image_minimal := "tempusbuild/runner-ubuntu-24.04-minimal:dev"
trivy_flags := "--severity HIGH,CRITICAL --ignore-unfixed --ignorefile .trivyignore.yaml --skip-version-check"

[private]
default:
    @just --list

# lint the whole repo (pre-commit, same set as in CI)
[group('lint')]
lint:
    pre-commit run --all-files

# install the pre-commit git hook (once after clone)
[group('lint')]
hooks:
    pre-commit install

# update pinned hook revisions
[group('lint')]
hooks-update:
    pre-commit autoupdate

# build the full ubuntu-24.04 image
[group('full')]
build:
    docker build -t {{ image }} ubuntu-24.04

# smoke tests inside the full image
[group('full')]
test: build
    docker run --rm -v "$PWD/tests:/tests:ro" {{ image }} bash -c 'for t in /tests/*.sh; do echo "== $t =="; bash "$t"; done'

# vulnerability scan of the full image (exceptions in .trivyignore.yaml)
[group('full')]
scan: build
    trivy image {{ trivy_flags }} {{ image }}

# build the minimal image
[group('minimal')]
build-minimal:
    docker build -t {{ image_minimal }} ubuntu-24.04-minimal

# smoke tests inside the minimal image (runner + base subset, same as CI)
[group('minimal')]
test-minimal: build-minimal
    docker run --rm -v "$PWD/tests:/tests:ro" {{ image_minimal }} bash -c 'for t in /tests/test_runner.sh /tests/test_minimal_base.sh; do echo "== $t =="; bash "$t"; done'

# vulnerability scan of the minimal image
[group('minimal')]
scan-minimal: build-minimal
    trivy image {{ trivy_flags }} {{ image_minimal }}

# everything CI runs, locally (each build happens once per invocation)
ci: lint test scan test-minimal scan-minimal
