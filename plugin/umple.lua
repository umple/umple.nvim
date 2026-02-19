-- Register .ump filetype (runs automatically when plugin loads)
vim.filetype.add({
	extension = {
		ump = "umple",
	},
})

-- Default indentation for Umple files
vim.api.nvim_create_autocmd("FileType", {
	pattern = "umple",
	callback = function()
		vim.bo.shiftwidth = 2
		vim.bo.tabstop = 2
		vim.bo.softtabstop = 2
		vim.bo.expandtab = true
	end,
})
