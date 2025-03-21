return {
	"lewis6991/gitsigns.nvim",
	config = function()
		require("gitsigns").setup({})
	end,
	opts = {

		signs = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },

			changedelete = { text = "~" },
		},
		signs_staged = {
			add = { text = "+" },
			change = { text = "~" },
			delete = { text = "_" },
			topdelete = { text = "‾" },
			changedelete = { text = "~" },
		},
	},
	vim.api.nvim_set_keymap("n", "<leader>gh", ":Gitsigns preview_hunk<CR>", { noremap = true, silent = true }),
	vim.api.nvim_set_keymap(
		"n",
		"<leader>gb",
		":Gitsigns toggle_current_line_blame<CR>",
		{ noremap = true, silent = true }
	),
}
