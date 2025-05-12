return {
	"akinsho/bufferline.nvim",
	dependencies = {
		"moll/vim-bbye",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("bufferline").setup({
			options = {
				mode = "buffers", -- set to "tabs" to only show tabpages instead
				themable = true, -- allows highlight groups to be overriden i.e. sets highlights as default
				numbers = "none", -- | "ordinal" | "buffer_id" | "both" | function({ ordinal, id, lower, raise }): string,
				close_command = "Bdelete! %d", -- can be a string | function, see "Mouse actions"
				offsets = {
					{
						filetype = "neo-tree",
						separator = true,
						text_align = "left",
					},
				},
				buffer_close_icon = "✗",
				close_icon = "✗",
				path_components = 1, -- Show only the file name without the directory
				modified_icon = "●",
				left_trunc_marker = "",
				right_trunc_marker = "",
				max_name_length = 30,
				max_prefix_length = 30, -- prefix used when a buffer is de-duplicated
				tab_size = 21,
				diagnostics = false,
				diagnostics_update_in_insert = false,
				color_icons = true,
				show_buffer_icons = true,
				show_buffer_close_icons = true,
				show_close_icon = true,
				persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
				separator_style = { "│", "│" }, -- | "thick" | "thin" | { 'any', 'any' },
				enforce_regular_tabs = true,
				always_show_bufferline = true,

				show_tab_indicators = false,
				indicator = {
					-- icon = '▎', -- this should be omitted if indicator style is not 'icon'
					style = "none", -- Options: 'icon', 'underline', 'none'
				},
				icon_pinned = "󰐃",
				minimum_padding = 1,
				maximum_padding = 5,
				maximum_length = 15,
				sort_by = "insert_at_end",
			},
			highlights = {
				-- ACTIVE BUFFER
				buffer_selected = {
					bg = "#11121D",
					fg = "#CBCED7",
					bold = true,
					italic = false,
				},
				-- INACTIVE BUFFERS
				background = {
					bg = "#11121D",
					fg = "#A0A8CD",
				},
				-- MODIFIED BUFFERS
				modified = {
					fg = "#F6955B",
				},
				modified_selected = {
					fg = "#F6955B",
				},
				-- CLOSE BUTTONS
				close_button = {
					bg = "#11121D",
					fg = "#EE6D85",
				},
				close_button_selected = {
					bg = "#11121D",
					fg = "#EE6D85",
				},
				-- BUFFERLINE BACKGROUND
				fill = {
					bg = "#11121D",
				},
				-- TAB PAGES
				tab = {
					bg = "#11121D",
					fg = "#A0A8CD",
				},
				tab_selected = {
					bg = "#11121D",
					fg = "#A0A8CD",
				},
				-- SEPARATORS
				separator = {
					bg = "#11121D",
					fg = "#434C5E",
				},
				separator_selected = {
					bg = "#11121D",
					fg = "#4A5057",
				},
			},
			-- separator = {
			--
			--   fg = '#434C5E',
			-- },
			-- buffer_selected = {
			--   bold = true,
			--   italic = false,
			-- },

			-- separator_selected = {},
			-- tab_selected = {},
			-- background = {},
			-- indicator_selected = {},
			-- fill = {},
			-- },
		})
	end,
}
