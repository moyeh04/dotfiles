return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },

		config = function()
			local lint = require("lint")

			-- Define linters per filetype

			lint.linters_by_ft = {
				-- Linters handled directly by nvim-lint
				make = { "checkmake" },
				sh = { "shellcheck" },
				ruby = { "rubocop" },
				java = { "checkstyle" }, -- Javadoc & naming conventions (betty-doc equivalent)

				-- Filetypes where LSP will provide diagnostics
				javascript = {}, -- biome
				typescript = {}, -- biome
				javascriptreact = {}, -- biome
				typescriptreact = {}, -- biome
				json = {}, -- jsonls
				vue = {}, -- volar
				svelte = {}, -- svelte-language-server
				astro = {}, -- astro-language-server
				python = {}, -- pylsp / ruff-lsp
				go = {}, -- gopls
				rust = {}, -- rust-analyzer
				lua = {}, -- lua_ls
				yaml = {}, -- yamlls
				html = {}, -- html-lsp
				css = {}, -- cssls
				scss = {}, -- cssls
				graphql = {}, -- graphql-language-service-cli
				toml = {}, -- taplo
				xml = {}, -- lemminx
				sql = {}, -- sqlls
				dockerfile = {}, -- dockerls
				bash = {}, -- bashls
				puppet = {}, -- puppet-editor-services
			}

			-- Autocommand group for linting
			local lint_augroup = vim.api.nvim_create_augroup("UserNvimLint", { clear = true })

			-- Trigger linting on save, read, and leaving insert mode
			vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
				group = lint_augroup,
				callback = function()
					lint.try_lint()
				end,
			})

			-- Keymap to manually trigger linting
			vim.keymap.set("n", "<leader>ll", function()
				lint.try_lint()
			end, { desc = "[L]int current file" })
		end,
	},
}
