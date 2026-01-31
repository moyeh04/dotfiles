return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"mason-org/mason-lspconfig.nvim",
		"j-hui/fidget.nvim",
		"hrsh7th/cmp-nvim-lsp", -- For capabilities
	},

	config = function()
		local lspconfig_util = require("lspconfig.util") -- For root_dir patterns
		local cmp_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_lsp.default_capabilities()

		-- LspAttach Autocommand (keymaps)
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
			callback = function(event)
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
				end
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
				map("K", vim.lsp.buf.hover, "Hover Documentation")
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")
				map("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
				map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
				map("<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, "[W]orkspace [L]ist Folders")
				local client = vim.lsp.get_client_by_id(event.data.client_id)
				if client and client.server_capabilities.documentHighlightProvider then
					vim.api.nvim_create_autocmd(
						{ "CursorHold", "CursorHoldI" },
						{ buffer = event.buf, callback = vim.lsp.buf.document_highlight }
					)
					vim.api.nvim_create_autocmd(
						{ "CursorMoved", "CursorMovedI" },
						{ buffer = event.buf, callback = vim.lsp.buf.clear_references }
					)
				end
			end,
		})

		-- Define configurations for Mason-managed LSPs (keys are lspconfig server names)
		local servers_configs = {
			lua_ls = {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = { checkThirdParty = false, library = vim.api.nvim_get_runtime_file("", true) },
						completion = { callSnippet = "Replace" },
						telemetry = { enable = false },
						diagnostics = { globals = { "vim" }, disable = { "missing-fields" } },
					},
				},
			},
			gopls = {
				settings = {
					gopls = {
						env = {
							GOEXPERIMENT = "rangefunc",
						},
					},
				},
				filetypes = {
					"go",
					"gomod",
					"gowork",
					"gotmpl",
				},
			},
			rust_analyzer = {},
			biome = {
				root_dir = lspconfig_util.root_pattern("biome.json", "biome.jsonc", "package.json", ".git"),
			},
			bashls = {},
			dockerls = {},
			tailwindcss = {},
			graphql = {},
			html = {
				filetypes = {
					"html",
					"twig",
					"hbs",
				},
			},
			cssls = {},
			jsonls = {},
			yamlls = {},
			sqlls = {},
			puppet = {},
			ruff = {
				init_options = {
					configuration = {
						line_length = 80,
					},
				},
				root_dir = lspconfig_util.root_pattern(".git", "pyproject.toml", "ruff.toml", "setup.py", ".venv"),
				filetypes = { "python" },
				commands = {
					RuffAutofix = {
						function()
							local bufnr = vim.api.nvim_get_current_buf()
							local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "ruff" })
							if clients and #clients > 0 then
								clients[1]:request("workspace/executeCommand", {
									command = "ruff.applyAutofix",
									arguments = { { uri = vim.uri_from_bufnr(bufnr), only = { "source.fixAll" } } },
								}, nil, bufnr)
							else
								print("Ruff LSP client not found for this buffer.")
							end
						end,
						description = "Ruff: Fix all auto‑fixable problems",
					},
					RuffOrganizeImports = {
						function()
							local bufnr = vim.api.nvim_get_current_buf()
							local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "ruff" })
							if clients and #clients > 0 then
								clients[1]:request("workspace/executeCommand", {
									command = "ruff.applyOrganizeImports",
									arguments = {
										{ uri = vim.uri_from_bufnr(bufnr), only = { "source.organizeImports" } },
									},
								}, nil, bufnr)
							else
								print("Ruff LSP client not found for this buffer.")
							end
						end,
						description = "Ruff: Format imports",
					},
				},
			},
			pylsp = {
				filetypes = { "python" },
				root_dir = lspconfig_util.root_pattern(".git", "pyproject.toml", "setup.py", ".venv"),
				settings = {
					pylsp = {
						plugins = {
							pyflakes = { enabled = false },
							pycodestyle = { enabled = false },
							autopep8 = { enabled = false },
							yapf = { enabled = false },
							mccabe = { enabled = false },
							pylsp_mypy = { enabled = false },
							pylsp_black = { enabled = false },
							pylsp_isort = { enabled = false },
							ruff = { enabled = false },
							jedi = {
								extra_paths = {
									"/home/linuxbrew/.linuxbrew/lib/python3.13/site-packages",
									"/home/linuxbrew/.linuxbrew/Cellar/python@3.13/3.13.3/lib/python3.13/site-packages",
								},
							},
						},
					},
				},
			},
			clangd = {
				-- cmd = {
				-- 	"clangd",
				-- 	"--background-index",
				-- 	"--clang-tidy",
				-- 	"--header-insertion=iwyu",
				-- 	"--completion-style=detailed",
				-- 	"--function-arg-placeholders",
				-- },
				filetypes = { "cpp", "objc", "objcpp", "cuda", "proto" },
				init_options = {
					usePlaceholders = true,
					completeUnimported = true,
					clangdFileStatus = true,
					fallbackFlags = { "--std=c++20" },
				},
			},
		}
		-- config = function()
		-- ... (your capabilities, LspAttach, servers_configs definitions) ...

		-- CURRENT LSP SETUP METHOD: Explicitly configure each server from `servers_configs`
		-- This loop ensures that each LSP server defined in `servers_configs`
		-- is initialized with its specific custom settings and global capabilities.
		-- Mason (via mason-tool-installer.nvim) is responsible for ensuring the
		-- LSP server binaries are installed and available in the PATH.

		for server_name, custom_config in pairs(servers_configs) do
			local server_opts = vim.tbl_deep_extend("force", {
				capabilities = capabilities, -- Apply base capabilities
			}, custom_config or {}) -- Ensure custom_config is a table
			vim.lsp.config(server_name, server_opts)
			vim.lsp.enable(server_name)
		end

		-- -----------------------------------------------------------------------------
		-- ALTERNATIVE LSP SETUP APPROACH (CURRENTLY DISABLED)
		-- -----------------------------------------------------------------------------
		-- The following section outlines a method using `mason-lspconfig.nvim` to
		-- automatically handle the setup of LSP servers based on the `servers_configs` table.
		--
		-- This approach was disabled because the current method (an explicit loop, see below)
		-- provides more direct control and resolved issues with duplicate client initializations
		-- or settings not being applied as expected.
		--
		-- If re-evaluating this `mason-lspconfig.setup` with handlers in the future,

		-- ensure the explicit setup loop further down is removed to prevent conflicts.
		-- -----------------------------------------------------------------------------
		-- -- local lsp_names_for_mason_bridge = {}
		-- -- for server_name, _ in pairs(servers_configs) do
		-- --     table.insert(lsp_names_for_mason_bridge, server_name)
		-- -- end
		--
		-- -- require("mason-lspconfig").setup({
		-- --     ensure_installed = lsp_names_for_mason_bridge,
		-- --     -- To use this effectively without a manual loop following it,
		-- --     -- a `handlers` table would typically be provided here to call
		-- --     -- lspconfig[server_name].setup() with the custom configurations

		-- --     -- from the `servers_configs` table.
		-- -- })
		-- -----------------------------------------------------------------------------
		-- end, -- End of your main config function
	end,
}
