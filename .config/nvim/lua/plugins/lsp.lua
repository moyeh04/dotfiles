return {
	"neovim/nvim-lspconfig",
	dependencies = {
		-- ## Mason Core & Tool Installer ##
		{
			"mason-org/mason.nvim",
			lazy = false,
			priority = 1000,
			config = function()
				require("mason").setup({
					ui = { icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
				})
				vim.defer_fn(function()
					vim.cmd("doautocmd User MasonToolsStarting")
				end, 100)
			end,
		},
		{
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			dependencies = { "mason-org/mason.nvim" },

			event = "User MasonToolsStarting",
			-- Setup call moved into the main config function below
		},

		-- ## LSP Bridge v2 ##
		{ "mason-org/mason-lspconfig.nvim" },

		-- ## Completion Engine & Snippets ##
		{ "hrsh7th/nvim-cmp", event = "InsertEnter" },
		{ "hrsh7th/cmp-nvim-lsp" }, -- Required nvim-cmp source for nvim-lsp
		{ "hrsh7th/cmp-buffer" },
		{ "hrsh7th/cmp-path" },
		{ "hrsh7th/cmp-cmdline" },
		{
			"L3MON4D3/LuaSnip",
			dependencies = { "rafamadriz/friendly-snippets" },
			event = "InsertEnter",
			build = "make install_jsregexp",
		},
		{ "saadparwaiz1/cmp_luasnip" },
		{ "rafamadriz/friendly-snippets" },

		-- ## UI ##
		{
			"j-hui/fidget.nvim",
			tag = "v1.4.0",
			opts = {
				progress = { display = { done_icon = "✓" } },
				notification = { window = { winblend = 0 } },
			},
		},
	},

	config = function()
		local cmp_lsp = require("cmp_nvim_lsp")
		local capabilities = cmp_lsp.default_capabilities() -- Use capabilities enhanced by nvim-cmp

		-- ## Tool Installation via Mason ##
		-- You can add other tools here that you want Mason to install
		-- for you, so that they are available from within Neovim.
		local ensure_installed_tools = {
			-- Linters (for nvim-lint)
			"checkmake",
			"shellcheck",
			"markdownlint-cli2",
			"rubocop",
			"ktlint",
			"tflint",
			-- Formatters (for conform.nvim)
			"prettierd",
			"stylua",
			"shfmt",
			"rustfmt",
			"google-java-format",
			"htmlbeautifier",
			"buf",
			"taplo",
			-- LSPs (EXCLUDING Python LSPs: ruff-lsp, pylsp, pyright)
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
			"terraform-ls",
			"sqlls",
			"texlab",
			"marksman",
			"puppet-editor-services",
			-- DAP (optional)
			"delve",
		}
		require("mason-tool-installer").setup({ ensure_installed = ensure_installed_tools, run_on_start = false })

		-- ## LSP Attach Configuration (Keymaps, etc.) ##
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }), -- Using your original group name
			-- Create a function that lets us more easily define mappings specific LSP related items.
			-- It sets the mode, buffer and description for us each time.
			callback = function(event)
				local map = function(keys, func, desc)
					vim.keymap.set("n", keys, func, { buffer = event.buf, silent = true, desc = "LSP: " .. desc })
				end

				-- Jump to the definition of the word under your cursor.
				--  This is where a variable was first declared, or where a function is defined, etc.

				--  To jump back, press <C-T>.
				map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
				-- Find references for the word under your cursor.
				map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
				-- Jump to the implementation of the word under your cursor.
				--  Useful when your language has ways of declaring types without an actual implementation.
				map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
				-- Jump to the type of the word under your cursor.
				--  Useful when you're not sure what type a variable is and you want to see
				--  the definition of its *type*, not where it was *defined*.
				map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]efinition")
				-- Fuzzy find all the symbols in your current document.
				--  Symbols are things like variables, functions, types, etc.
				map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
				-- Fuzzy find all the symbols in your current workspace
				--  Similar to document symbols, except searches over your whole project.
				map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
				-- Rename the variable under your cursor
				--  Most Language Servers support renaming across files, etc.
				map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
				-- Execute a code action, usually your cursor needs to be on top of an error
				-- or a suggestion from your LSP for this to activate.
				map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")

				-- Opens a popup that displays documentation about the word under your cursor
				--  See `:help K` for why this keymap
				map("K", vim.lsp.buf.hover, "Hover Documentation")
				-- WARN: This is not Goto Definition, this is Goto Declaration.
				--  For example, in C this would take you to the header
				map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

				-- Workspace folder management
				map("<leader>wa", vim.lsp.buf.add_workspace_folder, "[W]orkspace [A]dd Folder")
				map("<leader>wr", vim.lsp.buf.remove_workspace_folder, "[W]orkspace [R]emove Folder")
				map("<leader>wl", function()
					print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
				end, "[W]orkspace [L]ist Folders")

				-- The following two autocommands are used to highlight references of the
				-- word under your cursor when your cursor rests there for a little while.
				--    See `:help CursorHold` for information about when this is executed
				--
				-- When you move your cursor, the highlights will be cleared (the second autocommand).
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

		-- ## Setup mason-lspconfig Bridge (v2 Syntax) ##
		-- Defines which *Mason-installed* LSPs mason-lspconfig should help enable.
		local servers_for_mason_lspconfig_bridge = {
			"lua_ls",
			"gopls",
			"rust_analyzer",
			"biome",
			"bashls",
			"dockerls",
			"tailwindcss",
			"graphql",
			"html",
			"cssls",
			"jsonls",
			"yamlls",
			"terraformls",
			"sqlls",
			"texlab",
			"marksman",
			"puppet",
		}
		require("mason-lspconfig").setup({
			ensure_installed = servers_for_mason_lspconfig_bridge, -- Only Mason-managed LSPs
			-- automatic_installation = false, -- Removed this line as it's default/inert in v2
		})

		-- ## Configure Individual LSPs using vim.lsp.config() ##
		-- Configure Ruff (Manually Installed)
		-- Assumes 'ruff' is in PATH
		vim.lsp.config("ruff", {
			capabilities = capabilities,
			init_options = { settings = { args = { "--line-length=80" } } },
			filetypes = { "python" },
		})

		-- Configure Pylsp (Manually Installed)
		-- Assumes 'python3 -m pylsp' is runnable
		vim.lsp.config("pylsp", {
			capabilities = capabilities,
			cmd = { "python3", "-m", "pylsp" }, -- Explicit command
			settings = {
				pylsp = {
					plugins = { -- Copied from original config
						pyflakes = { enabled = false },
						pycodestyle = { enabled = false },
						autopep8 = { enabled = false },
						yapf = { enabled = false },
						mccabe = { enabled = false },
						pylsp_mypy = { enabled = false },
						pylsp_black = { enabled = false },
						pylsp_isort = { enabled = false },
					},
				},
			},
		})

		-- Enable the following language servers
		local servers_configs = {
			lua_ls = {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						workspace = {
							checkThirdParty = false,
							---@diagnostic disable-next-line: deprecated
							library = { "${3rd}/luv/library", unpack(vim.api.nvim_get_runtime_file("", true)) },
						},
						completion = { callSnippet = "Replace" },
						telemetry = { enable = false },
						diagnostics = { globals = { "vim" }, disable = { "missing-fields" } },
					},
				},
			},
			jsonls = {},
			sqlls = {},
			terraformls = {},
			yamlls = {},
			bashls = {},
			dockerls = {},
			docker_compose_language_service = {},
			tailwindcss = {},
			graphql = {},
			html = { filetypes = { "html", "twig", "hbs" } }, -- Keeps your filetype override
			cssls = {},
			texlab = {},
			marksman = {},
			gopls = { settings = { gopls = { env = { GOEXPERIMENT = "rangefunc" } } } }, -- Keeps your Go settings
			rust_analyzer = {},
			biome = {
				root_dir = require("lspconfig.util").root_pattern("biome.json", "biome.jsonc", "package.json", ".git"),
			},
			puppet = {},
		}

		-- Loop through the explicitly defined servers_configs table
		for server_name, custom_config in pairs(servers_configs) do
			-- Apply base capabilities and merge custom settings
			local server_opts = vim.tbl_deep_extend("force", { capabilities = capabilities }, custom_config)
			vim.lsp.config(server_name, server_opts)
		end

		-- ## Configure nvim-cmp (Autocompletion) ##
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		require("luasnip.loaders.from_vscode").lazy_load()

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
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
			window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
		})
		-- Cmdline completion
		cmp.setup.cmdline("/", { mapping = cmp.mapping.preset.cmdline(), sources = { { name = "buffer" } } })
		cmp.setup.cmdline(":", {
			mapping = cmp.mapping.preset.cmdline(),
			sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
		})
	end,
}
