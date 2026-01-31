return {
	"akinsho/bufferline.nvim",
	dependencies = {
		"moll/vim-bbye",
		"nvim-tree/nvim-web-devicons",
	},
	vim.keymap.set("n", "<leader><left>", "<Cmd>BufferLineMovePrev<CR>"),
	vim.keymap.set("n", "<leader><right>", "<Cmd>BufferLineMoveNext<CR>"),
	vim.keymap.set("n", "<Tab>", "<Cmd>BufferLineCycleNext<CR>"),
	vim.keymap.set("n", "<S-Tab>", "<Cmd>BufferLineCyclePrev<CR>"),

	config = function()
		-- Function to get color from current colorscheme
		local function get_hl_color(group, attr)
			local hl = vim.api.nvim_get_hl(0, { name = group })
			if hl and hl[attr] then
				return string.format("#%06x", hl[attr])
			end
			return nil
		end

		require("bufferline").setup({
			options = {
				mode = "buffers",
				themable = true,
				close_command = "Bdelete! %d",
				offsets = {
					{
						filetype = "neo-tree",
						separator = true,
						text_align = "left",
					},
				},
				buffer_close_icon = "✗",
				close_icon = "✗",

				modified_icon = "●",
				max_name_length = 30,
				tab_size = 21,
				color_icons = true,
				show_buffer_close_icons = true,
				separator_style = { "│", "│" },
				always_show_bufferline = true,
				indicator = {
					style = "none",
				},
				sort_by = "insert_at_end",
			},
			highlights = {
				buffer_selected = {
					bg = get_hl_color("Normal", "bg") or "#11121D",
					fg = get_hl_color("Normal", "fg") or "#CBCED7",
					bold = true,
					italic = false,
				},
				background = {
					bg = get_hl_color("Normal", "bg") or "#11121D",
					fg = get_hl_color("Comment", "fg") or "#A0A8CD",
				},
				modified = {
					fg = get_hl_color("WarningMsg", "fg") or "#F6955B",
				},
				modified_selected = {
					fg = get_hl_color("WarningMsg", "fg") or "#F6955B",
				},
				close_button = {
					bg = get_hl_color("Normal", "bg") or "#11121D",
					fg = get_hl_color("ErrorMsg", "fg") or "#EE6D85",
				},
				close_button_selected = {
					bg = get_hl_color("Normal", "bg") or "#11121D",

					fg = get_hl_color("ErrorMsg", "fg") or "#EE6D85",
				},
				fill = {
					bg = get_hl_color("Normal", "bg") or "#11121D",
				},
				tab = {

					bg = get_hl_color("Normal", "bg") or "#11121D",
					fg = get_hl_color("Comment", "fg") or "#A0A8CD",
				},
				tab_selected = {
					bg = get_hl_color("Normal", "bg") or "#11121D",
					fg = get_hl_color("Normal", "fg") or "#A0A8CD",
				},
				separator = {
					bg = get_hl_color("Normal", "bg") or "#11121D",
					fg = get_hl_color("Comment", "fg") or "#434C5E",
				},
				separator_selected = {
					bg = get_hl_color("Normal", "bg") or "#11121D",

					fg = get_hl_color("Comment", "fg") or "#4A5057",
				},
				tab_close = {
					bg = get_hl_color("Normal", "bg") or "#11121D",
					fg = get_hl_color("Comment", "fg") or "#434C5E",
				},
			},
		})
	end,
}
