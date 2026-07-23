#!/usr/bin/env bash
#
# install_claude.sh — install Claude Code (no sudo, no curl, no wget).
#
# The upstream one-liner is `curl -fsSL https://claude.ai/install.sh | bash`,
# which needs curl. This script does the same work using python3 (or Rscript)
# as the downloader, so it runs on a machine that has neither curl nor wget.
#
# It installs the native Claude Code binary under ~/.claude and sets up the
# launcher at ~/.local/bin/claude. No root is required.
#
#   bash install_claude.sh
#   source ~/.bashrc      # then `claude` is on PATH
#
# After installing, authenticate once with:  claude   (follow the login prompt)
#
set -euo pipefail

BASE_URL="https://downloads.claude.ai/claude-code-releases"
DL_DIR="${HOME}/.claude/downloads"

# --- 0. If it is already installed, do nothing ------------------------------
if command -v claude >/dev/null 2>&1; then
  echo "claude already on PATH: $(claude --version 2>/dev/null || echo present)"
  exit 0
fi

# --- 1. A downloader that needs neither curl nor wget -----------------------
# fetch <url> <output-path>.  Tries python3, then Rscript.
fetch() {
  url="$1"; out="$2"
  if   command -v python3 >/dev/null 2>&1; then
    python3 -c "import urllib.request,sys; urllib.request.urlretrieve(sys.argv[1], sys.argv[2])" "$url" "$out"
  elif command -v Rscript >/dev/null 2>&1; then
    Rscript -e 'a<-commandArgs(TRUE); download.file(a[1], a[2], mode="wb", quiet=TRUE)' "$url" "$out"
  else
    echo "No downloader found (python3, Rscript both missing)." >&2
    exit 1
  fi
}

# --- 2. Work out this machine's platform string -----------------------------
os="$(uname -s)"
arch="$(uname -m)"

case "$os" in
  Linux)  plat_os="linux" ;;
  Darwin) plat_os="darwin" ;;
  *) echo "Unsupported OS: $os" >&2; exit 1 ;;
esac

case "$arch" in
  x86_64|amd64)  plat_arch="x64" ;;
  aarch64|arm64) plat_arch="arm64" ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

platform="${plat_os}-${plat_arch}"

# Linux built against musl (e.g. Alpine) needs the -musl variant. Ubuntu is
# glibc, so this branch is skipped there.
if [ "$plat_os" = "linux" ] && ldd --version 2>&1 | grep -qi musl; then
  platform="${platform}-musl"
fi

# --- 3. Download the binary for the latest version --------------------------
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

echo "Looking up the latest Claude Code version ..."
fetch "${BASE_URL}/latest" "${tmp}/latest"
version="$(tr -d '[:space:]' < "${tmp}/latest")"
echo "Latest version: ${version}  (platform: ${platform})"

echo "Downloading the release manifest ..."
fetch "${BASE_URL}/${version}/manifest.json" "${tmp}/manifest.json"

# Pull this platform's expected SHA256 out of the manifest without needing jq.
# Read the manifest by path (not via stdin) so it works regardless of shell
# redirection.
expected="$(python3 -c '
import json, sys
path, plat = sys.argv[1], sys.argv[2]
with open(path) as f:
    m = json.load(f)
try:
    print(m["platforms"][plat]["checksum"])
except KeyError:
    sys.exit(f"Platform {plat} not in manifest")
' "${tmp}/manifest.json" "$platform")"

mkdir -p "$DL_DIR"
bin="${DL_DIR}/claude-${version}-${platform}"
echo "Downloading the claude binary ..."
fetch "${BASE_URL}/${version}/${platform}/claude" "$bin"
chmod 0755 "$bin"

# --- 4. Verify the checksum before running anything -------------------------
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$bin" | cut -d' ' -f1)"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "$bin" | cut -d' ' -f1)"
else
  echo "No sha256 tool found; cannot verify the download." >&2
  exit 1
fi

if [ "$actual" != "$expected" ]; then
  echo "Checksum mismatch for ${bin}" >&2
  echo "  expected: ${expected}" >&2
  echo "  actual:   ${actual}" >&2
  exit 1
fi
echo "Checksum OK."

# --- 5. Let the binary install its launcher and shell integration -----------
# This writes the ~/.local/bin/claude launcher and adds it to PATH in ~/.bashrc.
echo "Installing ..."
"$bin" install

echo
echo "Done. Open a new shell or run:  source ~/.bashrc"
echo "Then start Claude Code with:     claude"
echo "The first run walks you through signing in."
