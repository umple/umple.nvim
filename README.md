# umple.nvim

Neovim plugin for the [Umple](https://www.umple.org) modeling language. Provides diagnostics, code completion, go-to-definition, and syntax highlighting for `.ump` files.

## Requirements

- Node.js 18+
- Java 11+ (optional — only needed for diagnostics)

## Installation (lazy.nvim)

```lua
{
  'umple/umple.nvim',
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

The tree-sitter parser for syntax highlighting is compiled automatically on first load.


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

This pulls the latest plugin code and re-runs the build script (which updates the LSP server and tree-sitter grammar).

## Development

To test local changes to the LSP server:

1. Clone both repos side by side:

```
workspace/
├── umple-lsp/       # LSP server monorepo
└── umple.nvim/      # This plugin
```

2. Build the server locally:

```bash
cd umple-lsp
npm install
npm run compile
npm run download-jar
```

3. Override the plugin's paths to use your local build:

```lua
{
  dir = '/path/to/umple.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
    'nvim-treesitter/nvim-treesitter',
  },
  config = function()
    require("umple-lsp").setup({
      plugin_dir = '/path/to/umple.nvim',
    })
  end,
}
```

Then symlink the local server into the plugin's expected locations:

```bash
cd umple.nvim
# Symlink tree-sitter grammar
ln -sf ../umple-lsp/packages/tree-sitter-umple tree-sitter-umple
# Symlink local server into node_modules (jar is already inside packages/server/)
mkdir -p node_modules
ln -sf ../../umple-lsp/packages/server node_modules/umple-lsp-server
```

After making changes to the server, recompile and restart:

```bash
cd umple-lsp
npm run compile
```

Then in Neovim: `:LspRestart`

To recompile the tree-sitter parser after grammar changes, delete the cached `.so` and restart Neovim:

```bash
rm -f ~/.local/share/nvim/site/parser/umple.so
rm -rf ~/.local/share/nvim/site/queries/umple
```

## How it works

The build script installs the pre-compiled [umple-lsp-server](https://www.npmjs.com/package/umple-lsp-server) from npm, downloads `umplesync.jar` for diagnostics, and extracts the tree-sitter grammar (`src/parser.c` + `queries/`) from the [umple-lsp](https://github.com/umple/umple-lsp) repo. The plugin compiles the tree-sitter parser automatically on first load (into `~/.local/share/nvim/site/parser/umple.so`) and points Neovim's LSP client at the npm-installed server.
