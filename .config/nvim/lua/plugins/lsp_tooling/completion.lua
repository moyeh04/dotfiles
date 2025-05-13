return {
	-- Snippet Engine: LuaSnip
	{
		"L3MON4D3/LuaSnip",
		event = { "InsertEnter", "CmdlineEnter" },
		-- Conditionally build LuaSnip with jsregexp for full regex support in snippets,
		-- skipping on Windows or if 'make' is not available.
		build = (function()
			if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
				vim.notify("LuaSnip: 'make' not found or on Windows. Skipping jsregexp build.", vim.log.levels.WARN)
				return
			end
			return "make install_jsregexp"
		end)(),
		dependencies = {
			-- Base set of snippets
			"rafamadriz/friendly-snippets",
		},

		config = function()
			-- Initialize LuaSnip
			require("luasnip").config.setup({})
			-- Load snippets from VSCode-style snippet collections
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},

	-- Autocompletion Engine: nvim-cmp
	{
		"hrsh7th/nvim-cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = {
			"hrsh7th/cmp-nvim-lsp", -- Source for LSP (Language Server Protocol) completions
			"hrsh7th/cmp-buffer", -- Source for completions from words in the current buffer
			"hrsh7th/cmp-path", -- Source for file system path completions
			"hrsh7th/cmp-cmdline", -- Source for command-line completions
			"saadparwaiz1/cmp_luasnip", -- Integration for LuaSnip snippets within nvim-cmp
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- Defines icons to be used for different completion item kinds
			local kind_icons = {
				Text = "󰉿",

				Method = "m",
				Function = "󰊕",
				Constructor = "",
				Field = "",
				Variable = "󰆧",
				Class = "󰌗",
				Interface = "",
				Module = "",
				Property = "",
				Unit = "",
				Value = "󰎠",
				Enum = "",
				Keyword = "󰌋",
				Snippet = "",

				Color = "󰏘",
				File = "󰈙",
				Reference = "",
				Folder = "󰉋",

				EnumMember = "",

				Constant = "󰇽",
				Struct = "",

				Event = "",
				Operator = "󰆕",

				TypeParameter = "󰊄",
			}

			cmp.setup({
				snippet = {
					-- Configure nvim-cmp to use LuaSnip for snippet expansion

					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				-- Completion behavior options
				completion = {

					completeopt = "menu,menuone,noinsert", -- Show menu, select first item, don't auto-insert
				},
				-- Define completion sources
				sources = cmp.config.sources({
					{ name = "nvim_lsp" }, -- Language server suggestions
					{ name = "luasnip" }, -- Snippet suggestions
					{ name = "buffer" }, -- Suggestions from current buffer text
					{ name = "path" }, -- File path suggestions

					-- { name = "lazydev", group_index = 0 }, -- For Neovim plugin development with lazy.nvim
				}),
				-- Key mappings for the completion menu
				mapping = {
					-- Select previous item in completion menu
					["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
					-- Select next item in completion menu
					["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
					-- Confirm selected completion
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					-- Manually trigger completion

					["<C-Space>"] = cmp.mapping.complete(),

					-- Scroll documentation window backwards
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					-- Scroll documentation window forwards

					["<C-f>"] = cmp.mapping.scroll_docs(4),

					-- Snippet navigation: Jump forward or expand snippet

					["<C-l>"] = cmp.mapping(function(fallback)
						if luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }), -- Works in insert and select mode for snippets
					-- Snippet navigation: Jump backward in snippet
					["<C-h>"] = cmp.mapping(function(fallback)
						if luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }), -- Works in insert and select mode for snippets

					-- Tab navigation: Select next in completion OR jump/expand snippet
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_locally_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s" }),
					-- Shift-Tab navigation: Select previous in completion OR jump backward in snippet
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.locally_jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s" }),
				},
				-- Configure bordered windows for completion and documentation
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				-- Custom formatting for completion items, including icons and source menu
				formatting = {
					fields = { "kind", "abbr", "menu" }, -- Elements to display in the completion menu
					format = function(entry, vim_item)
						-- Prepend kind icon if available

						if kind_icons[vim_item.kind] then
							vim_item.kind = kind_icons[vim_item.kind] .. " " .. vim_item.kind
						end
						-- Add a menu hint for the source of the completion
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",

							path = "[Path]",
							lazydev = "[LazyDev]", -- For Neovim plugin development completions
						})[entry.source.name]
						return vim_item
					end,
				},

				-- experimental = {
				--    ghost_text = true, -- Display completion suggestion as ghost text
				-- },
			})

			-- Setup nvim-cmp for command-line search
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" }, -- Completions from search history or buffer content
				},
			})
			-- Setup nvim-cmp for command-line commands
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" }, -- File system path completions
				}, {
					{ name = "cmdline" }, -- Vim command completions
				}),
			})
		end,
	},

	-- friendly-snippets is generally best handled as a dependency of LuaSnip.
	-- If it's listed in LuaSnip's dependencies, a separate top-level entry isn't strictly necessary
	-- unless specific configuration for friendly-snippets itself is needed here.
	-- {
	--    "rafamadriz/friendly-snippets",
	-- },
}
