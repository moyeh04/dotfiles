-- plugins/lualine.lua
return {
	"nvim-lualine/lualine.nvim",
	config = function()
		local mode = {
			"mode",
			fmt = function(str)
				return "" .. str
			end,
		}

		local filename = {
			"filename",

			file_status = true,
			path = 0,
		}

		local hide_in_width = function()
			return vim.fn.winwidth(0) > 50
		end

		local diagnostics = {
			"diagnostics",
			sources = { "nvim_diagnostic" },
			sections = { "error", "warn" },

			symbols = {
				error = " ",
				warn = " ",
				info = " ",
				hint = " ",
			},
			colored = true,
			update_in_insert = false,
			always_visible = false,
			cond = hide_in_width,
		}

		local diff = {
			"diff",
			colored = true,
			symbols = { added = "+", modified = "~", removed = "-" },
			cond = hide_in_width,
		}

		-- Add recorder components
		local recorder_status = require("recorder").recordingStatus
		local recorder_slots = require("recorder").displaySlots

		require("lualine").setup({
			options = {
				theme = "auto",
				section_separators = { left = "", right = "" },
				component_separators = { left = "", right = "" },
				globalstatus = true,
				icons_enabled = true,
				disabled_filetypes = { "alpha", "neo-tree" },
				always_divide_middle = true,
			},

			sections = {
				lualine_a = { mode },
				lualine_b = { "branch", diagnostics, diff },
				lualine_c = {},
				lualine_x = { { "encoding" }, { "filetype" }, filename },
				lualine_y = { "location", recorder_slots }, -- Add recorder_slots here
				lualine_z = { "progress", recorder_status }, -- Add recorder_status here
			},
			inactive_sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { { "filename", path = 1 } },
				lualine_x = { { "location", padding = 0 } },
				lualine_y = {},
				lualine_z = {},
			},
			tabline = {},
			extensions = { "fugitive", { sections = { lualine_b = { "filetype" } }, filetypes = { "NvimTree" } } },
		})
	end,
	dependencies = {
		"chrisgrieser/nvim-recorder", -- Add this dependency to ensure proper loading order
	},
}
