return {
	"Shatur/neovim-ayu",

	lazy = false,
	priority = 1000,
	config = function()
		require("ayu").setup({
			mirage = false, -- Set to true for mirage variant
			overrides = {
				-- Add any specific overrides here
			},
		})
		vim.cmd([[colorscheme ayu-dark]])
	end,
}
