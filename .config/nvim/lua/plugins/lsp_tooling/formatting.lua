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
					python = { "ruff_format", "ruff_organize_imports" },

					--C Languages
					cpp = { "clang-format" },

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
					-- TODO: Install yamlfix manually if Prettier formatting is insufficient
					graphql = { "prettierd", "prettier" },
					markdown = { "prettierd", "prettier" },
					toml = { "taplo" },

					-- Shell / DevOps
					sh = { "shfmt" },
					bash = { "shfmt" }, -- Or beautysh
					dockerfile = { "shfmt" }, -- Or beautysh

					-- Other languages
					go = { "goimports-reviser", "golines", "gofmt" },
					rust = { "rustfmt" },
					ruby = { "rubocop" },
					java = { "google-java-format" },
				},

				-- Specific formatter configs
				formatters = {
					shfmt = {
						args = { "-i", "4" },
					},
					ruff_format = {
						cmd = "ruff",
						args = {
							"format",
							"--stdin-filename",
							"%",
							"-",
						},
						stdin = true,
					},
					ruff_organize_imports = {
						cmd = "ruff",
						args = {
							"check",
							"--select",
							"I",
							"--fix",
							"--exit-zero",
							"force-exclude",
							"no-cache",
							"--stdin-filename",
							"%",
							"-",
						},
						stdin = true,
					},
					rubocop = {
						args = { "--auto-correct", "--format", "quiet", "--stdin", "%:p" },
						stdin = true,
					},
					["clang-format"] = {
						prepend_args = function(self, ctx)
							-- Check if .clang-format exists in project
							local config_file = vim.fs.find(".clang-format", {

								upward = true,
								path = ctx.dirname,
							})[1]

							if config_file then
								-- Use project's .clang-format file
								return { "--style=file" }
							else
								-- Fallback to Betty style
								return {
									"--style={BasedOnStyle: LLVM, IndentWidth: 4, AccessModifierOffset: -4, UseTab: Never, ColumnLimit: 80, BreakBeforeBraces: Attach, AllowShortFunctionsOnASingleLine: Empty, IndentAccessModifiers: false}",
								}
							end
						end,

						args = { "--assume-filename", "$FILENAME" },
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
