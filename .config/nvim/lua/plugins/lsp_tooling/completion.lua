return {
	-- Snippet Engine: LuaSnip
	{
		"L3MON4D3/LuaSnip",

		event = { "InsertEnter", "CmdlineEnter" },
		build = "make install_jsregexp",
		dependencies = {
			-- Snippet Collection
			"rafamadriz/friendly-snippets", -- If you want a good base set of snippets
		},
		config = function()
			-- You can add LuaSnip specific settings here if needed in the future.
			-- For now, loading vscode snippets is often done just before cmp.setup.
		end,
	},

	-- Autocompletion Engine: nvim-cmp
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- Source for LSP completions
			"hrsh7th/cmp-buffer", -- Source for buffer words
			"hrsh7th/cmp-path", -- Source for file system paths
			"hrsh7th/cmp-cmdline", -- Source for command-line completion
			"L3MON4D3/LuaSnip", -- Integration with LuaSnip
			"saadparwaiz1/cmp_luasnip", -- LuaSnip completion source for nvim-cmp
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Load VSCode-style snippets
			-- It's common to do this here so LuaSnip is ready when cmp initializes
			require("luasnip.loaders.from_vscode").lazy_load()

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body) -- Expand snippets through LuaSnip
					end,
				},
				sources = cmp.config.sources({
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "buffer" },
					{ name = "path" },
				}),
				mapping = cmp.mapping.preset.insert({
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
					["<CR>"] = cmp.mapping.confirm({ select = true }),

					["<C-Space>"] = cmp.mapping.complete(),
					-- Snippet navigation
					["<C-f>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(1) then
							luasnip.jump(1)
						else
							fallback()
						end
					end, { "i", "s" }),
					["<C-b>"] = cmp.mapping(function(fallback)
						if luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				-- experimental = { -- Example: if you want to enable ghost text
				--   ghost_text = true,
				-- },
			})

			-- Command-line completion
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" }, -- Completions from search history or buffer
				},
			})
			cmp.setup.cmdline(":", {

				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" }, -- Filesystem paths
				}, {

					{ name = "cmdline" }, -- Vim commands
				}),
			})
		end,
	},

	-- This is explicitly listed in your original dependencies,
	-- though LuaSnip often pulls it in. Listing it ensures it's managed.
	{
		"rafamadriz/friendly-snippets",
	},
}
