# umple.nvim

Neovim plugin for the [Umple](https://www.umple.org) modeling language. Provides diagnostics, code completion, go-to-definition, and syntax highlighting for `.ump` files.

## Requirements

- [Neovim](https://neovim.io/) 0.9+ (0.10+ recommended)
- [Node.js](https://nodejs.org/) 18+ (for running the LSP server)
- A C compiler (`cc` or `gcc`) for compiling the tree-sitter parser
- [Java](https://adoptium.net/) 11+ (optional — only needed for diagnostics)
- A plugin manager — this guide uses [lazy.nvim](https://github.com/folke/lazy.nvim)

### Installing prerequisites

**macOS** (via [Homebrew](https://brew.sh/)):
```bash
brew install neovim node
brew install openjdk  # optional, for diagnostics
```

**Ubuntu/Debian**:
```bash
sudo apt install neovim nodejs npm build-essential
sudo apt install default-jdk  # optional, for diagnostics
```

### Setting up lazy.nvim

If you don't have a plugin manager yet, follow the [lazy.nvim installation guide](https://lazy.folke.io/installation).

## Installation

Add this to your lazy.nvim plugin list:

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

The build script downloads the LSP server from npm and fetches the tree-sitter grammar. The tree-sitter parser is compiled automatically on first load — no manual steps needed.

### Auto-completion (recommended)

For auto-popup completion, install a completion plugin such as [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) with [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp). Without one, the LSP server still provides completions but you won't see them automatically.

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

- **Diagnostics**: Real-time error and warning detection (requires Java)
- **Go-to-definition**: Jump to classes, interfaces, traits, enums, attributes, methods, state machines, states, associations, mixsets, requirements, and `use` statements
- **Code completion**: Context-aware keyword and symbol completion
- **Syntax highlighting**: Via [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar (compiled automatically)

## Updating

```vim
:Lazy update umple.nvim
```

This pulls the latest plugin code and re-runs the build script (which updates the LSP server and tree-sitter grammar).

## Troubleshooting

### No syntax highlighting

The plugin compiles the tree-sitter parser on first load. If it fails:

1. Make sure you have a C compiler: `cc --version` or `gcc --version`
2. Delete the cached parser and restart Neovim to recompile:
   ```bash
   rm -f ~/.local/share/nvim/site/parser/umple.so
   rm -rf ~/.local/share/nvim/site/queries/umple
   ```

### No diagnostics

Diagnostics require Java 11+. Verify: `java -version`

### LSP not starting

1. Check that Node.js is installed: `node --version`
2. Run `:LspLog` in Neovim to see server errors
3. Rebuild the plugin: `:Lazy build umple.nvim`

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
npm run compile       # Server-only changes
npm run build-grammar # After grammar.js changes (regenerates parser + WASM + compiles)
```

Then in Neovim: `:LspRestart`

After grammar changes, also delete the cached native parser so Neovim recompiles it:

```bash
rm -f ~/.local/share/nvim/site/parser/umple.so
rm -rf ~/.local/share/nvim/site/queries/umple
```

## How it works

The build script installs the pre-compiled [umple-lsp-server](https://www.npmjs.com/package/umple-lsp-server) from npm, downloads `umplesync.jar` for diagnostics, and extracts the tree-sitter grammar (`src/parser.c` + `queries/`) from the [umple-lsp](https://github.com/umple/umple-lsp) repo. The plugin compiles the tree-sitter parser automatically on first load (into `~/.local/share/nvim/site/parser/umple.so`) and points Neovim's LSP client at the npm-installed server.
