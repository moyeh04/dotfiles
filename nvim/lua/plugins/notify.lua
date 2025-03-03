return {
	"rcarriga/nvim-notify",
	config = function()
		local notify = require("notify")

		notify.setup({
			-- Set rendering style to compact with line wrapping
			render = "wrapped-compact",

			-- Define maximum width for notifications
			max_width = 50,

			-- Set display time in milliseconds
			timeout = 3000,

			-- Set background color; this can be a highlight group or hex value
			background_colour = "#1e1e1e",
		})

		-- Assign custom notify as the default notification handler
		vim.notify = notify
	end,
}
