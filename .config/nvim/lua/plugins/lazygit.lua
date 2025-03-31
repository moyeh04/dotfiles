return {
	{
		"kdheepak/lazygit.nvim",
		cmd = "LazyGit", -- Lazy-load the plugin when the LazyGit command is invoked

		keys = {

			{ "<leader>gg", "<cmd>LazyGit<CR>", desc = "Launch LazyGit" },
		},
		config = function()
			-- Optional configurations: customize the floating window appearance, etc.
			vim.g.lazygit_floating_window_winblend = 0
			vim.g.lazygit_floating_window_scaling_factor = 1
			vim.g.lazygit_floating_window_border_chars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" }
		end,
	},
}
