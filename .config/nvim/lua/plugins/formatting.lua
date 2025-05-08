return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>lf",
				function()
					require("conform").format({ async = true, lsp_fallback = true })
				end,
				mode = { "n", "v" },
				desc = "[L]int [F]ormat buffer",
			},
		},
		config = function()
			local conform = require("conform")

			conform.setup({
				-- Map filetypes to formatters
				formatters_by_ft = {
					lua = { "stylua" },
					python = { "ruff" },

					-- Web languages - using prettierd w/ prettier fallback
					javascript = { "prettierd", "prettier" },
					typescript = { "prettierd", "prettier" },
					javascriptreact = { "prettierd", "prettier" },
					typescriptreact = { "prettierd", "prettier" },
					svelte = { "prettierd", "prettier" },
					vue = { "prettierd", "prettier" },
					html = { "prettierd", "prettier" }, -- Or "htmlbeautifier"
					css = { "prettierd", "prettier" },
					scss = { "prettierd", "prettier" },
					json = { "prettierd", "prettier" },
					yaml = { "prettierd", "prettier" }, -- Or "yamlfix"
					graphql = { "prettierd", "prettier" },
					markdown = { "prettierd", "prettier" },
					toml = { "taplo" },

					-- Shell / DevOps
					sh = { "shfmt" },
					bash = { "shfmt" }, -- Or beautysh
					dockerfile = { "shfmt" }, -- Or beautysh

					-- Other languages
					go = { "gofmt" },
					rust = { "rustfmt" },
					ruby = { "rubocop" },
					kotlin = { "ktlint" },
					java = { "google-java-format" },
					proto = { "buf" },
				},

				-- Specific formatter configs
				formatters = {
					shfmt = {
						args = { "-i", "4" },
					},
					ruff = {
						cmd = "ruff",
						args = {
							"check",
							"--select",
							"I",
							"--fix",
							"--stdin-filename",
							"%:p",
							"-",
						},
						stdin = true,
					},
					rubocop = {
						args = { "--auto-correct", "--format", "quiet", "--stdin", "%:p" },
						stdin = true,
					},
				},

				-- Enable format on save
				format_on_save = {
					timeout_ms = 1000,
					lsp_fallback = true,
				},
			})
		end,
	},
}
