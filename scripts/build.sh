#!/bin/sh
# Install the Umple LSP server from npm, download umplesync.jar,
# and fetch the tree-sitter grammar files for :TSInstall.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TS_DIR="$PLUGIN_DIR/tree-sitter-umple"

# 1. Install the pre-compiled LSP server from npm
echo "umple-lsp.nvim: installing umple-lsp-server from npm..."
npm install --prefix "$PLUGIN_DIR" umple-lsp-server

# 2. Download umplesync.jar (needed for diagnostics) into server package
download_with_retry() {
  local url="$1"
  local dest="$2"
  for i in 1 2 3; do
    if curl -fSL -o "$dest" "$url"; then
      return 0
    fi
    echo "umple-lsp.nvim: attempt $i/3 failed, retrying..."
    sleep 2
  done
  echo "umple-lsp.nvim: failed to download $url after 3 attempts" >&2
  return 1
}

echo "umple-lsp.nvim: downloading umplesync.jar..."
download_with_retry https://try.umple.org/scripts/umplesync.jar \
  "$PLUGIN_DIR/node_modules/umple-lsp-server/umplesync.jar"

# 3. Fetch tree-sitter grammar (src/parser.c + queries/) for :TSInstall
echo "umple-lsp.nvim: fetching tree-sitter grammar..."
rm -rf "$TS_DIR"
git clone --depth 1 https://github.com/umple/umple-lsp.git "$PLUGIN_DIR/_umple-lsp-tmp"
mv "$PLUGIN_DIR/_umple-lsp-tmp/packages/tree-sitter-umple" "$TS_DIR"
rm -rf "$PLUGIN_DIR/_umple-lsp-tmp"

echo "umple-lsp.nvim: build complete"
