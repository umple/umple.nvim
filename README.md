# umple.nvim

Neovim plugin for the [Umple](https://www.umple.org) modeling language. Provides diagnostics, code completion, go-to-definition, and syntax highlighting for `.ump` files.

## Installation

### lazy.nvim

```lua
{
  'DraftTin/umple.nvim',
  build = './scripts/build.sh',
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require("umple-lsp").setup()
  end,
}
```

After installation, run `:TSInstall umple` to compile the tree-sitter parser for syntax highlighting.

### Requirements

- Node.js 18+
- Java 11+ (for diagnostics via umplesync.jar)
- git

## Configuration

```lua
require("umple-lsp").setup({
  port = 5556,  -- UmpleSync port (default: 5556)
  on_attach = function(client, bufnr)
    -- your custom keybindings
  end,
})
```

### Default keybindings

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `<leader>e` | Show diagnostics float |
| `[d` | Previous diagnostic |
| `]d` | Next diagnostic |

## Manual Setup (without lazy.nvim)

If you don't use lazy.nvim, you can configure Neovim manually:

### 1. Build the LSP server

```bash
git clone https://github.com/DraftTin/umple-lsp.git
cd umple-lsp
npm install
npm run compile
npm run download-jar
```

### 2. Add to your init.lua

```lua
dofile('/path/to/umple-lsp/editors/neovim/umple.lua')
```

Update `UMPLE_LSP_PATH` at the top of `umple.lua` to your actual path.

### 3. Install tree-sitter parser and queries

```bash
ln -s /path/to/umple-lsp/packages/tree-sitter-umple/queries ~/.local/share/nvim/queries/umple
```

Then in Neovim:

```vim
:TSInstall umple
```

## Features

- **Diagnostics**: Real-time error and warning detection
- **Go-to-definition**: Jump to class, attribute, state definitions
- **Code completion**: Context-aware keyword and symbol completion
- **Syntax highlighting**: Via tree-sitter grammar

## Updating

```vim
:Lazy update umple.nvim
```

This pulls the latest plugin code and re-runs the build script (which updates the LSP server).

## How it works

The build script clones the [umple-lsp](https://github.com/DraftTin/umple-lsp) monorepo into the plugin directory and compiles the LSP server. The plugin then points Neovim's LSP client at the compiled server.
