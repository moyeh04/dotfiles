-- Custom code snippets for different purposes

-- Prevent LSP from overwriting treesitter color settings
-- https://github.com/NvChad/NvChad/issues/1907
vim.highlight.priorities.semantic_tokens = 95 -- Or any number lower than 100, treesitter's priority level

-- Appearance of diagnostics
vim.diagnostic.config({
	virtual_text = {
		prefix = "●",
		format = function(diagnostic)
			local code = diagnostic.code and string.format("[%s]", diagnostic.code) or ""
			return string.format("%s %s", code, diagnostic.message)
		end,
	},
	signs = true, -- You can simply enable them with 'true' for defaults
	-- Or, for more control (optional, if you want to customize beyond defaults):
	-- signs = {
	--   active = true, -- Redundant if 'signs = true'
	--   values = {
	--     { name = "DiagnosticSignError", text = "", texthl = "DiagnosticError" },
	--     { name = "DiagnosticSignWarn",  text = "", texthl = "DiagnosticWarn" },
	--     { name = "DiagnosticSignInfo",  text = "", texthl = "DiagnosticInfo" },
	--     { name = "DiagnosticSignHint",  text = "󰌵", texthl = "DiagnosticHint" },
	--   }
	-- },
	underline = false,
	update_in_insert = true,
	float = {
		source = "if_many",
	},

	-- Make diagnostic background transparent
	on_ready = function()
		vim.cmd("highlight DiagnosticVirtualText guibg=NONE")
	end,
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
