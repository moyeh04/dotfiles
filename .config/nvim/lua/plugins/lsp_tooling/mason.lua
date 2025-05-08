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
			})
			-- Trigger event for mason-tool-installer *after* Mason core is setup
			vim.defer_fn(function()
				vim.cmd("doautocmd User MasonToolsStarting")
			end, 100) -- Defer slightly to ensure setup completes
		end,
	},

	-- ## Mason Tool Installer ##
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",

		dependencies = { "mason-org/mason.nvim" },
		event = "User MasonToolsStarting", -- Wait for Mason setup signal
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

				-- DAP Servers:
				"delve", -- Go
				"debugpy", -- Python
			}

			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed_tools,
				run_on_start = true,
			})
		end,
	},
}
