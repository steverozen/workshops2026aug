#!/usr/bin/env bash
#
# install_pixi.sh — install pixi (no sudo) and build this repo's Python env.
#
# Ubuntu 24 / x86_64. Installs the pixi binary under ~/.pixi/bin, then runs
# `pixi install` at the repo root so the staging scripts find the Python they
# need at <repo_root>/.pixi/envs/default/bin/python.
#
# The repo already carries pixi.toml and pixi.lock, so this only rebuilds the
# environment from those pins. It does not create or modify pixi.toml.
#
#   bash install_pixi.sh
#   source ~/.bashrc      # then pixi is on PATH
#
set -euo pipefail

PIXI_VERSION="v0.73.0"
ASSET="pixi-x86_64-unknown-linux-musl.tar.gz"   # static musl build, runs on Ubuntu glibc
URL="https://github.com/prefix-dev/pixi/releases/download/${PIXI_VERSION}/${ASSET}"
BIN_DIR="${HOME}/.pixi/bin"

# This script lives at the repo top level, next to pixi.toml.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Refuse to run on the wrong architecture.
arch="$(uname -m)"
if [ "$arch" != "x86_64" ]; then
  echo "This script is for x86_64, but uname -m says: $arch" >&2
  exit 1
fi

# --- 1. Install the pixi binary, unless it is already present ---------------
if command -v pixi >/dev/null 2>&1; then
  echo "pixi already on PATH: $(pixi --version)"
elif [ -x "${BIN_DIR}/pixi" ]; then
  echo "pixi already installed at ${BIN_DIR}/pixi: $("${BIN_DIR}/pixi" --version)"
else
  mkdir -p "$BIN_DIR"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  tgz="${tmp}/${ASSET}"

  echo "Downloading pixi ${PIXI_VERSION} ..."
  if   command -v curl    >/dev/null 2>&1; then curl -fSL "$URL" -o "$tgz"
  elif command -v wget    >/dev/null 2>&1; then wget -O "$tgz" "$URL"
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c "import urllib.request,sys; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])" "$URL" "$tgz"
  elif command -v Rscript >/dev/null 2>&1; then
    Rscript -e 'a<-commandArgs(TRUE); download.file(a[1], a[2], mode="wb")' "$URL" "$tgz"
  else
    echo "No downloader found (curl, wget, python3, Rscript all missing)." >&2
    exit 1
  fi

  tar -xzf "$tgz" -C "$BIN_DIR"
  chmod 0755 "${BIN_DIR}/pixi"
  echo "Installed: $("${BIN_DIR}/pixi" --version)"
fi

# --- 2. Put pixi on PATH for this shell and future ones ---------------------
export PATH="${BIN_DIR}:${PATH}"

line='export PATH="$HOME/.pixi/bin:$PATH"'
if ! grep -qxF "$line" "${HOME}/.bashrc" 2>/dev/null; then
  printf '\n# pixi\n%s\n' "$line" >> "${HOME}/.bashrc"
  echo "Added pixi to PATH in ~/.bashrc"
fi

# --- 3. Build the repo's Python environment from pixi.toml / pixi.lock ------
if [ ! -f "${REPO_ROOT}/pixi.toml" ]; then
  echo "No pixi.toml at ${REPO_ROOT}; is this script at the repo top level?" >&2
  exit 1
fi

echo "Building the pixi environment at ${REPO_ROOT} ..."
( cd "$REPO_ROOT" && pixi install )

PY="${REPO_ROOT}/.pixi/envs/default/bin/python"
echo
echo "Done. Python for the staging scripts is:"
echo "  ${PY}"
"${PY}" -c "import anndata, scipy, pandas; print('modules OK:', anndata.__version__)"
echo
echo "Open a new shell or run:  source ~/.bashrc"
echo "The staging scripts find this Python automatically; no need to set RETICULATE_PYTHON."
