-- Handles Mason core setup and installation of tools via mason-tool-installer
return {
	-- ## Mason Core ##
	{
		"mason-org/mason.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
				log_level = vim.log.levels.DEBUG,
			})
		end,
	},

	-- ## Mason Tool Installer ##
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			-- Excludes Python LSPs (ruff-lsp, pylsp). Includes Python DAP (debugpy).
			local ensure_installed_tools = {

				-- Linters (for nvim-lint):
				"checkmake",
				"shellcheck",
				"markdownlint-cli2",
				"rubocop",

				-- Formatters (for conform.nvim):
				"prettierd",
				"stylua",
				"shfmt",
				"rustfmt",
				"taplo",
				"goimports-reviser",
				"golines",

				-- LSPs (excluding Python):
				"lua-language-server",
				"gopls",
				"rust-analyzer",
				"biome",
				"bash-language-server",
				"dockerfile-language-server",
				"tailwindcss-language-server",
				"graphql-language-service-cli",
				"html-lsp",
				"css-lsp",
				"json-lsp",
				"yaml-language-server",
				"sqlls",
				"marksman",
				"puppet-editor-services",
				"ruff",
				"pylsp",

				-- DAP Servers:
				"delve", -- Go
				"debugpy", -- Python
			}

			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed_tools,
				-- Run MasonToolsInstall manually for better performance
				run_on_start = false,
			})
		end,
	},
}
