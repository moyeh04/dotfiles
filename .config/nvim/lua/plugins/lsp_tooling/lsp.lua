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
				settings = { gopls = { env = { GOEXPERIMENT = "rangefunc" } } },
				filetypes = { "go", "gomod", "gowork", "gotmpl" },
			},
			rust_analyzer = {},
			biome = { root_dir = lspconfig_util.root_pattern("biome.json", "biome.jsonc", "package.json", ".git") },
			bashls = {},
			dockerls = {},
			tailwindcss = {},
			graphql = {},
			html = { filetypes = { "html", "twig", "hbs" } },
			cssls = {},
			jsonls = {},
			yamlls = {},
			sqlls = {},
			marksman = {},
			puppet = {},
		}

		-- ## Setup mason-lspconfig Bridge ##
		-- This list tells mason-lspconfig which LSPs (by lspconfig name) to
		-- ensure are installed via Mason and to provide default setups for.
		local lsp_names_for_mason_bridge = {}
		for server_name, _ in pairs(servers_configs) do
			table.insert(lsp_names_for_mason_bridge, server_name)
		end
		-- If there are any other LSPs installed by mason.lua that you want default setup for
		-- but don't have custom configs in servers_configs, add their lspconfig names here.
		-- Example: if "marksman" was installed by mason.lua but not in servers_configs:
		-- if not servers_configs["marksman"] then table.insert(lsp_names_for_mason_bridge, "marksman") end
		-- However, since all our Mason LSPs are now keys in servers_configs, this is simpler.

		require("mason-lspconfig").setup({
			ensure_installed = lsp_names_for_mason_bridge,
		})

		-- Apply custom configurations from servers_configs
		for server_name, custom_config in pairs(servers_configs) do
			local server_opts = vim.tbl_deep_extend("force", {
				capabilities = capabilities, -- Apply base capabilities
			}, custom_config or {}) -- Ensure custom_config is a table
			require("lspconfig")[server_name].setup(server_opts)
		end

		-- Configure Ruff (Manually Installed)
		-- Assumes 'ruff' is in PATH
		vim.lsp.config("ruff", {
			init_options = {
				settings = {
					args = { "--line-length=80" },
				},
			},
			root_dir = lspconfig_util.root_pattern(".git", "pyproject.toml", "ruff.toml", "setup.py", ".venv"),
			filetypes = { "python" },
			capabilities = capabilities, -- Using the global capabilities from cmp_nvim_lsp
			commands = {
				RuffAutofix = {
					function(client, bufnr)
						client:exec_cmd({

							command = "ruff.applyAutofix",
							arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
						}, { bufnr = bufnr })
					end,
					description = "Ruff: Fix all auto‑fixable problems",
				},

				RuffOrganizeImports = {
					function(client, bufnr)
						client:exec_cmd({
							command = "ruff.applyOrganizeImports",
							arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
						}, { bufnr = bufnr })
					end,
					description = "Ruff: Format imports",
				},
			},
		})
		vim.lsp.enable("ruff")

		-- Configure Pylsp (Manually Installed)
		-- Assumes 'python3 -m pylsp' is runnable
		vim.lsp.config.pylsp = {
			cmd = { "python3", "-m", "pylsp" },
			filetypes = { "python" },
			root_dir = lspconfig_util.root_pattern(".git", "pyproject.toml", "setup.py", ".venv"), -- From your old config
			capabilities = capabilities,                                                  -- Using the global capabilities
			settings = {
				pylsp = {
					plugins = {
						jepyflakes = { enabled = false },
						pycodestyle = { enabled = false },
						autopep8 = { enabled = false },
						yapf = { enabled = false },
						mccabe = { enabled = false },
						pylsp_mypy = { enabled = false }, -- Run pip install pylsp-mypy first.
						pylsp_black = { enabled = false },
						pylsp_isort = { enabled = false },
						jedi = {
							extra_paths = {
								"/home/linuxbrew/.linuxbrew/lib/python3.13/site-packages",
								"/home/linuxbrew/.linuxbrew/Cellar/python@3.13/3.13.3/lib/python3.13/site-packages",
							},
						},
					},
				},
			},
		}
		vim.lsp.enable("pylsp")
	end,
}
