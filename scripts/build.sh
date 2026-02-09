#!/bin/sh
# Clone or update the umple-lsp monorepo, then compile and download JAR.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LSP_DIR="$PLUGIN_DIR/umple-lsp"

if [ -d "$LSP_DIR/.git" ]; then
  echo "umple-lsp.nvim: updating umple-lsp..."
  cd "$LSP_DIR"
  git pull
else
  echo "umple-lsp.nvim: cloning umple-lsp..."
  git clone https://github.com/DraftTin/umple-lsp.git "$LSP_DIR"
  cd "$LSP_DIR"
fi

echo "umple-lsp.nvim: installing dependencies..."
npm install

echo "umple-lsp.nvim: compiling..."
npm run compile

echo "umple-lsp.nvim: downloading umplesync.jar..."
npm run download-jar

echo "umple-lsp.nvim: build complete"
