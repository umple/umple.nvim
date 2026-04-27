# umple.nvim

Neovim plugin for the [Umple](https://www.umple.org) modeling language. Provides diagnostics, code completion, go-to-definition, find references, rename, hover, formatting, and syntax highlighting for `.ump` files.

## Requirements

- [Neovim](https://neovim.io/) 0.9+ (0.10+ recommended)
- [Node.js](https://nodejs.org/) 20+ (for running the LSP server; tested on 20 and 23)
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
  on_attach = function(client, bufnr)
    -- your custom keybindings
  end,
})
```

> Earlier versions of this plugin documented a `port = 5556` option (passed to the server as `umpleSyncPort`). The current LSP server doesn't read it — diagnostics now spawn `umplesync.jar` as a subprocess per request, no socket. The option is harmlessly ignored if you set it.

### Keybindings

No keybindings are set by default — use `on_attach` to configure your own. Example:

```lua
require("umple-lsp").setup({
  on_attach = function(client, bufnr)
    local opts = { buffer = bufnr }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>f", vim.lsp.buf.format, opts)
    vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, opts)
    vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
    vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
  end,
})
```

## Features

- **Diagnostics**: Real-time error and warning detection (requires Java)
- **Go-to-definition**: Jump to classes, interfaces, traits, enums, attributes, methods, state machines, states, associations, mixsets, requirements, and `use` statements
- **Find references**: Semantic reference search across all reachable files
- **Rename**: Safe symbol rename across all references
- **Hover**: Contextual information for symbols
- **Code completion**: Context-aware keyword and symbol completion
- **Document symbols**: Hierarchical outline (accessible via `:Telescope lsp_document_symbols` or similar)
- **Formatting**: AST-driven indent correction, arrow spacing, blank-line normalization
- **Syntax highlighting**: Via [tree-sitter](https://tree-sitter.github.io/tree-sitter/) grammar (compiled automatically)
- **Cross-file support**: Transitive `use` statement resolution and cross-file diagnostics

## Updating

```vim
:Lazy update umple.nvim
```

This pulls the latest plugin code and re-runs the build script (which updates the LSP server and tree-sitter grammar).

## Troubleshooting

### Parser, highlighting, and diagnostics

Neovim uses two separate Umple checks:

- Tree-sitter parser + queries: syntax highlighting, `:InspectTree`, and local parse shape. The cached native parser is `~/.local/share/nvim/site/parser/umple.so`; query files are linked at `~/.local/share/nvim/site/queries/umple`.
- LSP diagnostics: compiler errors and warnings from `umplesync.jar`. These are the pink/red diagnostics such as `E1502`.

A file can highlight and parse correctly in tree-sitter while still showing an `umplesync.jar` compiler diagnostic. In that case the LSP is working; the compiler is rejecting the Umple program.

### No syntax highlighting

The plugin compiles the tree-sitter parser on first load. If it fails:

1. Make sure you have a C compiler: `cc --version` or `gcc --version`
2. Check that the query symlink points to this plugin:
   ```bash
   readlink ~/.local/share/nvim/site/queries/umple
   ```
3. Delete the cached parser and restart Neovim to recompile:
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

After grammar changes, also delete the cached native parser so Neovim recompiles it. The plugin repairs stale query symlinks on startup, but deleting the query path is still a useful reset when debugging local setup:

```bash
rm -f ~/.local/share/nvim/site/parser/umple.so
rm -rf ~/.local/share/nvim/site/queries/umple
```

## How it works

The build script installs the pre-compiled [umple-lsp-server](https://www.npmjs.com/package/umple-lsp-server) from npm, downloads `umplesync.jar` for diagnostics, and extracts the tree-sitter grammar (`src/parser.c` + `queries/`) from the [umple-lsp](https://github.com/umple/umple-lsp) repo. The plugin compiles the tree-sitter parser automatically on first load (into `~/.local/share/nvim/site/parser/umple.so`), links query files into `~/.local/share/nvim/site/queries/umple`, and points Neovim's LSP client at the npm-installed server.
