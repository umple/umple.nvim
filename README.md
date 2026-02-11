# umple.nvim

Neovim plugin for the [Umple](https://www.umple.org) modeling language. Provides diagnostics, code completion, go-to-definition, and syntax highlighting for `.ump` files.

## Requirements

- Node.js 18+
- Java 11+ (optional — only needed for diagnostics)
- git

## Installation (lazy.nvim)

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

## Development

To test local changes to the LSP server:

1. Clone both repos side by side:

```
workspace/
├── umple-lsp/       # LSP server monorepo
└── umple.nvim/      # This plugin
```

2. Build the server:

```bash
cd umple-lsp
npm install
npm run compile
npm run download-jar
```

3. Symlink the server into the plugin directory:

```bash
cd umple.nvim
rm -rf umple-lsp
ln -s ../umple-lsp umple-lsp
```

4. Point your Neovim config at the local clone. With lazy.nvim, use `dir` instead of the GitHub repo:

```lua
{
  dir = '/path/to/umple.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require("umple-lsp").setup()
  end,
}
```

Without lazy.nvim, add to your `init.lua`:

```lua
vim.opt.runtimepath:prepend("/path/to/umple.nvim")
require("umple-lsp").setup()
```

Then run `:TSInstall umple` if you haven't already.

5. After making changes to the server, recompile and restart:

```bash
cd umple-lsp
npm run compile
```

Then in Neovim: `:LspRestart`

## How it works

The build script clones the [umple-lsp](https://github.com/DraftTin/umple-lsp) monorepo into the plugin directory and compiles the LSP server. The plugin then points Neovim's LSP client at the compiled server.
