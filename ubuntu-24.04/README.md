# runner-ubuntu-24.04 (full)

Full runner image for ARC `gha-runner-scale-set`, label `tempus-ubuntu-24.04-4core`.

## Contents

| Component                     | Version                                                                                                                                                                                           | Source (verify before bumping)                                                        |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------- |
| Base                          | Ubuntu 24.04 (noble), pinned by digest `sha256:786a8b55…`                                                                                                                                         | hub.docker.com/\_/ubuntu — bump digest on weekly rebuild                              |
| Actions runner                | `2.335.1` (ARG `RUNNER_VERSION`)                                                                                                                                                                  | github.com/actions/runner/releases                                                    |
| Node.js                       | LTS, major `22` (ARG `NODE_MAJOR`)                                                                                                                                                                | nodejs.org/en/about/previous-releases                                                 |
| Python (system)               | 3.12 (system on 24.04) + `pip`, `venv`, dev headers (`python3-dev`)                                                                                                                               | packages.ubuntu.com                                                                   |
| Python (toolcache, prebake)   | `3.10.20`, `3.11.15`, `3.12.13`, `3.13.13`, `3.14.5` in `/opt/hostedtoolcache/Python/<v>/x64` (ARG `PYTHON_31x`)                                                                                  | actions/python-versions `versions-manifest.json` — same builds `setup-python` fetches |
| Go (toolcache, prebake)       | `1.25.11`, `1.26.4` — supported minors (1.25 / 1.26) in `/opt/hostedtoolcache/go/<v>/x64` (ARG `GO_125`/`GO_126`)                                                                                 | go.dev/dl — SHA256 from `?mode=json&include=all`; `setup-go` layout (cache hit)       |
| Rust (rustup)                 | toolchain `1.95.0` (rustup `1.29.0`), default profile = rustc+cargo+rust-std+rustfmt+clippy; `RUSTUP_HOME=/usr/local/rustup`, `CARGO_HOME=/usr/local/cargo` (ARG `RUST_VERSION`/`RUSTUP_VERSION`) | static.rust-lang.org — pinned `rustup-init` + SHA256                                  |
| pipx                          | from apt (`packages.txt`) — isolated installs of Python CLI tools                                                                                                                                 | packages.ubuntu.com                                                                   |
| GitHub CLI (`gh`)             | from the cli.github.com repo (workflows commonly call `gh`)                                                                                                                                       | cli.github.com                                                                        |
| Docker CLI + buildx + compose | from the download.docker.com repo                                                                                                                                                                 | docs.docker.com                                                                       |
| Base tools                    | see `packages.txt` (incl. `zstd` — speeds up `actions/cache`)                                                                                                                                     | —                                                                                     |

The Docker daemon is not included — it is provided by the ARC dind sidecar (`containerMode: dind`).
The image ships the CLI only.

The Python toolcache is prebaked so that `actions/setup-python` with
`python-version: "3.10|3.11|3.12|3.13|3.14"` gets an offline cache hit (the `<v>/x64.complete` marker
exists) instead of downloading a runtime on every run. Versions are pinned in the Dockerfile
(ARG `PYTHON_310…PYTHON_314`) — the exact latest stable patch from the `actions/python-versions`
manifest for `linux/24.04/x64` at build time. Verify the manifest on bump.

## Build / checks

```bash
just build   # docker build -t tempusbuild/runner-ubuntu-24.04:dev ubuntu-24.04
just test    # smoke tests from ../tests inside the image
just scan    # trivy: HIGH/CRITICAL, ignore-unfixed, --ignorefile .trivyignore.yaml
```

## Usage

Consumed via ARC: `ghcr.io/tempusbuild/runner-ubuntu-24.04:<tag>`.
After publishing to ghcr, pin `tag@sha256:` on the consumer side.

## Languages (parity vs ubuntu-latest)

Included:

- system `python3` (3.12) + `pip` + `venv` + dev headers (`python3-dev`), build toolchain
  (`build-essential`, `pkg-config`) and dev libraries (`libffi-dev`, `libssl-dev`, `libpq-dev`,
  `libxml2-dev`, `libxslt1-dev`, `zlib1g-dev`, `libjpeg-dev`) — building native wheels works;
- `pipx` for isolated CLI tools;
- toolcache Python 3.10 / 3.11 / 3.12 / 3.13 / 3.14 → `setup-python` resolves offline (cache hit);
- toolcache Go 1.25 / 1.26 → `actions/setup-go` resolves offline (cache hit) — versions and layout
  in the table above;
- Rust via `rustup` (versions in the table above); `cargo`/`rustup` on `PATH`, usable by `runner`;
  native crates build (`build-essential`, `pkg-config`, `libssl-dev` present).

Not included (deliberately; added on real workflow demand, we do not copy GitHub's ~90 GB image wholesale):

- `gfortran` — a heavy scientific-stack toolchain, not in demand so far;
- `conda` / `poetry` — environment managers; installed per workflow (`setup-python` + `pip`/`pipx`),
  not worth keeping in the image;
- **EOL Go minors (1.22–1.24) are deliberately NOT baked** (security): Go patches only the last two
  minors, EOL releases get no stdlib fixes, so a baked toolcache for them would carry image-unfixable
  HIGH/CRITICAL CVEs. We bake only supported 1.25/1.26 (patch-current). Anyone needing an older minor
  installs it via `actions/setup-go` from the network (no cache hit);
- Python minors outside 3.10–3.14 / Go outside 1.25–1.26 — `setup-python`/`setup-go` install them
  from the network (no cache hit); other Rust toolchains — `rustup toolchain install <v>`.

**PEP 668 (externally managed):** the system `python3` is marked externally managed, so a global
`pip install <pkg>` fails by design. The standard path is `python -m venv` (inside a venv the
restriction is lifted) or `actions/setup-python` (its toolcache runtimes are not externally managed).
For CLI tools — `pipx`. This matches ubuntu-latest behaviour.

## Notes

- Lean set (Node/Python/Docker CLI + base) vs GitHub's ~90 GB image. Anything a specific workflow
  is missing is added to `packages.txt`/Dockerfile (on real demand).
- The `minimal` variant (`../ubuntu-24.04-minimal/`) — no Node/Docker, just runner + base.
