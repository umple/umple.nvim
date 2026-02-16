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
	-- 2. Tree-sitter parser: compile and install the .so if needed
	-- ------------------------------------------------------------------
	local parser_src = treesitter_dir .. "/src/parser.c"
	local install_dir = vim.fn.stdpath("data") .. "/site"
	local parser_dest = install_dir .. "/parser/umple.so"

	if vim.fn.filereadable(parser_src) == 1 and vim.fn.filereadable(parser_dest) == 0 then
		-- Ensure parser directory exists
		vim.fn.mkdir(install_dir .. "/parser", "p")

		-- Compile parser.c into a shared library
		local cc = vim.fn.exepath("cc") ~= "" and "cc" or "gcc"
		local compile_cmd = string.format(
			'%s -o "%s" -shared -fPIC -Os -I "%s/src" "%s"',
			cc,
			parser_dest,
			treesitter_dir,
			parser_src
		)
		local result = vim.fn.system(compile_cmd)
		if vim.v.shell_error ~= 0 then
			vim.notify("umple-lsp.nvim: failed to compile parser: " .. result, vim.log.levels.WARN)
		end
	end

	-- Register umple filetype with treesitter
	pcall(vim.treesitter.language.register, "umple", "umple")

	-- ------------------------------------------------------------------
	-- 3. Symlink queries to the site directory
	-- ------------------------------------------------------------------
	local queries_src = treesitter_dir .. "/queries"
	local site_queries = install_dir .. "/queries/umple"

	if vim.fn.isdirectory(queries_src) == 1 and vim.fn.isdirectory(site_queries) == 0 then
		vim.fn.mkdir(install_dir .. "/queries", "p")
		vim.fn.system({ "ln", "-s", queries_src, site_queries })
	end
end

return M
