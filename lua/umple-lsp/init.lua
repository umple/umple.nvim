-- Umple LSP plugin for Neovim
-- Automatically configures the Umple language server and tree-sitter parser.

local M = {}

function M.setup(opts)
	opts = opts or {}

	-- Resolve the plugin's install directory
	-- This file is at <plugin_dir>/lua/umple-lsp/init.lua
	local plugin_dir = opts.plugin_dir
	if not plugin_dir then
		local source = debug.getinfo(1, "S").source:sub(2)
		plugin_dir = vim.fn.fnamemodify(source, ":h:h:h")
	end

	-- Server from npm, jar next to server package, tree-sitter extracted by build script
	local server_dir = plugin_dir .. "/node_modules/umple-lsp-server"
	local server_js = server_dir .. "/out/server.js"
	local jar_path = server_dir .. "/umplesync.jar"
	local treesitter_dir = plugin_dir .. "/tree-sitter-umple"

	-- Check that the build step has run
	if vim.fn.filereadable(server_js) == 0 then
		vim.notify(
			"umple-lsp.nvim: server not found. Run :Lazy build umple-lsp.nvim",
			vim.log.levels.ERROR
		)
		return
	end

	-- ------------------------------------------------------------------
	-- 1. LSP server
	-- ------------------------------------------------------------------
	local lspconfig = require("lspconfig")
	local configs = require("lspconfig.configs")

	if not configs.umple then
		configs.umple = {
			default_config = {
				cmd = {
					"node",
					server_js,
					"--stdio",
				},
				filetypes = { "umple" },
				root_dir = function(fname)
					local util = require("lspconfig.util")
					return util.root_pattern(".git")(fname) or vim.fn.fnamemodify(fname, ":h")
				end,
				single_file_support = true,
				init_options = {
					umpleSyncJarPath = jar_path,
					umpleSyncPort = opts.port or 5556,
				},
			},
		}
	end

	lspconfig.umple.setup({
		on_attach = opts.on_attach or function(client, bufnr)
			local kopts = { buffer = bufnr, noremap = true, silent = true }
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, kopts)
			vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, kopts)
			vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, kopts)
			vim.keymap.set("n", "]d", vim.diagnostic.goto_next, kopts)
		end,
	})

	-- ------------------------------------------------------------------
	-- 2. Tree-sitter parser registration
	-- ------------------------------------------------------------------
	local ts_ok, parser_config = pcall(function()
		return require("nvim-treesitter.parsers").get_parser_configs()
	end)

	if ts_ok then
		parser_config.umple = {
			install_info = {
				url = treesitter_dir,
				files = { "src/parser.c" },
			},
			filetype = "umple",
		}
	end

	-- ------------------------------------------------------------------
	-- 3. Symlink queries automatically if not already present
	-- ------------------------------------------------------------------
	local queries_src = treesitter_dir .. "/queries"
	if vim.fn.isdirectory(queries_src) == 1 then
		-- lazy.nvim treesitter location
		local lazy_queries = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/queries/umple"
		local lazy_parent = vim.fn.fnamemodify(lazy_queries, ":h")
		if vim.fn.isdirectory(lazy_parent) == 1 and vim.fn.isdirectory(lazy_queries) == 0 then
			vim.fn.system({ "ln", "-s", queries_src, lazy_queries })
		end

		-- Standard neovim queries location
		local std_queries = vim.fn.stdpath("data") .. "/queries/umple"
		local std_parent = vim.fn.fnamemodify(std_queries, ":h")
		if vim.fn.isdirectory(std_parent) == 1 and vim.fn.isdirectory(std_queries) == 0 then
			vim.fn.system({ "ln", "-s", queries_src, std_queries })
		end
	end
end

return M
