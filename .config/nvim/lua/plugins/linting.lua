return {
	{
		"mfussenegger/nvim-lint",

		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {

				-- Linters handled directly by nvim-lint
				make = { "checkmake" },
				sh = { "shellcheck" },
				markdown = { "markdownlint" },
				ruby = { "rubocop" },
				kotlin = { "ktlint" },
				terraform = { "tflint" },

				-- TODO: Add custom linter definition for 'betty' for C files if desired.
				-- c = { "betty" },

				-- Filetypes where LSPs (configured in lsp.lua) will be the primary linters:
				javascript = {}, -- biome
				typescript = {}, -- biome
				javascriptreact = {}, -- biome
				typescriptreact = {}, -- biome
				json = {}, -- biome (or jsonls)
				vue = {}, -- vue-language-server / volar
				svelte = {}, -- svelte-language-server (if installed)
				astro = {}, -- astro-language-server
				python = {}, -- ruff-lsp (+ pyright)
				go = {}, -- gopls
				rust = {}, -- rust-analyzer
				lua = {}, -- lua-language-server (lua_ls)
				java = {}, -- jdtls (needs separate config)
				yaml = {}, -- yaml-language-server (yamlls)
				html = {}, -- html-lsp (html)
				css = {}, -- css-lsp (cssls)
				scss = {}, -- css-lsp (cssls)
				graphql = {}, -- graphql-language-service-cli (graphql)
				toml = {}, -- taplo (LSP component)
				xml = {}, -- lemminx (XML Language Server - if installed)
				sql = {}, -- sql-language-server (sqlls)
				dockerfile = {}, -- dockerfile-language-server (dockerls)
				bash = {}, -- bash-language-server (bashls)
				puppet = {}, -- puppet-editor-services (puppet_ls)
				-- terraform = {},    -- terraform-ls (but tflint added above for specific linting)
			}

			-- Autocommand to trigger linting
			local lint_augroup = vim.api.nvim_create_augroup("UserNvimLint", { clear = true })
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					require("lint").try_lint()
				end,
			})

			-- Optional: Add manual trigger keymap (like example config)
			vim.keymap.set("n", "<leader>ll", function()
				lint.try_lint()
			end, { desc = "[L]int current file" })
		end,
	},
}
