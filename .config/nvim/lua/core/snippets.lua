-- Custom code snippets for different purposes

-- Appearance of diagnostics
vim.diagnostic.config({
	-- virtual_text = {
	-- 	prefix = "●",
	-- 	format = function(diagnostic)
	-- 		local code = diagnostic.code and string.format("[%s]", diagnostic.code) or ""
	-- 		return string.format("%s %s", code, diagnostic.message)
	-- 	end,
	-- },
	virtual_lines = { enabled = true },
	-- signs = true, -- Simply enable them with 'true' for defaults
	-- Custom signs:
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "", -- Error icon
			[vim.diagnostic.severity.WARN] = "", -- Warning icon
			[vim.diagnostic.severity.INFO] = "", -- Info icon
			[vim.diagnostic.severity.HINT] = "󰌵", -- Hint icon
		},
	},
	underline = false,
	update_in_insert = true,
	severity_sort = true,
	float = {
		source = "if_many",
	},
})

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {

	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = "*",
})
