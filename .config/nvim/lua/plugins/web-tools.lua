return {
	{
		"ray-x/web-tools.nvim",
		dependencies = {
			"ray-x/guihua.lua", -- Optional: needed only if you enable floating windows
		},
		-- We load the plugin when any of these commands are called.
		cmd = {
			"BrowserSync",
			"BrowserOpen",
			"BrowserPreview",
			"BrowserRestart",
			"BrowserStop",
			"TagRename",
			"HurlRun",
		},

		opts = {
			keymaps = {

				rename = nil, -- Keep the default behavior for tag renaming
				repeat_rename = ".", -- Use the dot (.) key to repeat the tag renaming action
			},
			hurl = {
				floating = true, -- Use a split instead of a floating window for Hurl output
				json5 = false, -- Set to true if you have Treesitter JSON5 support (usually false by default)
				formatters = {
					json = { "jq" }, -- Formatter for JSON responses (install jq)
					html = { "prettier", "--parser", "html" }, -- Formatter for HTML responses (install prettier)
				},
			},
		},
		config = function(_, opts)
			require("web-tools").setup(opts)
		end,
	},

	-- Minimal key mapping for opening the browser-sync preview:
	vim.api.nvim_set_keymap(
		"n",
		"<leader>bso",
		":BrowserOpen --port 5555 --ui-port 5556<CR>",
		{ noremap = true, silent = false }
	),

	-- Minimal key mapping for tag renaming (you type the new tag after triggering the command): (Look into it later)
	-- vim.api.nvim_set_keymap("n", "<leader>tr", ":TagRename ", { noremap = true, silent = false }),
}
