return {
	"chrisgrieser/nvim-recorder",

	dependencies = "rcarriga/nvim-notify", -- you already have this installed
	opts = {
		-- Default configuration
		slots = { "a", "b" },

		mapping = {
			startStopRecording = "q",
			playMacro = "Q",
			switchSlot = "<C-q>",
			editMacro = "cq",
			deleteAllMacros = "dq",
			yankMacro = "yq",

			addBreakPoint = "##",
		},
		clear = false,
		logLevel = vim.log.levels.INFO,
		lessNotifications = false,
		useNerdfontIcons = true,
	},
}
