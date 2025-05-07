return {

	"nvim-neo-tree/neo-tree.nvim",
	dependencies = {

		"nvim-lua/plenary.nvim",
		"nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
		"MunifTanjim/nui.nvim",
		-- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
	},
	config = function()
		-- If you want icons for diagnostic errors, you'll need to define them somewhere:
		-- The old method of defining diagnostic signs (DiagnosticSignError, etc.) was removed from here.
		-- Those signs are now globally defined/configured via vim.diagnostic.config() in lua/core/snippets.lua.

		require("neo-tree").setup({
			close_if_last_window = true, -- Close Neo-tree if it is the last window left in the tab
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,
			window = {
				position = "left",
				width = 25,
				mapping_options = {
					noremap = true,
					nowait = true,
				},
				mappings = {
					["J"] = function(state)
						local tree = state.tree
						local node = tree:get_node()
						local siblings = tree:get_nodes(node:get_parent_id())
						local renderer = require("neo-tree.ui.renderer")
						renderer.focus_node(state, siblings[#siblings]:get_id())
					end,
					["K"] = function(state)
						local tree = state.tree
						local node = tree:get_node()
						local siblings = tree:get_nodes(node:get_parent_id())
						local renderer = require("neo-tree.ui.renderer")
						renderer.focus_node(state, siblings[1]:get_id())
					end,
				},
				buffers = { follow_current_file = { enabled = true } },
			},
			filesystem = {
				follow_current_file = { enabled = true }, -- Always follow the current file
				hijack_netrw_behavior = "open_default", -- Optional: Override netrw to open Neo-tree by default

				-- Auto-expand the directory when revealing the current file
				use_libuv_file_watcher = true, -- Updates Neo-tree when changes are detected
			},
		})

		vim.api.nvim_set_keymap(
			"n",
			"<leader>cn",
			":cd %:p:h<CR> :Neotree reveal<CR>",
			{ noremap = true, silent = true }
		)
		vim.keymap.set("n", "<C-n>", ":Neotree filesystem toggle left<CR>", {})
	end,
}
