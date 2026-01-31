-- Java Development Setup using nvim-java
-- Provides full Java/Spring Boot support with LSP, DAP, and test runner
return {
	"nvim-java/nvim-java",
	ft = { "java" },
	dependencies = {
		"nvim-java/lua-async-await",
		"nvim-java/nvim-java-core",
		"nvim-java/nvim-java-test",
		"nvim-java/nvim-java-dap",
		"MunifTanjim/nui.nvim",
		"neovim/nvim-lspconfig",
		"mfussenegger/nvim-dap",
		{
			-- Spring Boot Tools integration
			"JavaHello/spring-boot.nvim",
			dependencies = {
				"mfussenegger/nvim-jdtls",
			},
		},
	},
	config = function()
		require("java").setup({
			-- Spring Boot support is built-in
			spring_boot_tools = {
				enable = true,
			},
			jdk = {
				-- Auto-install JDK if needed via Mason
				auto_install = true,
			},
			-- jdtls configuration
			jdtls = {
				-- Additional jdtls settings can go here
				settings = {
					java = {
						-- Enable code formatting
						format = {
							enabled = true,
						},
						-- Enable organize imports
						saveActions = {
							organizeImports = true,
						},
						-- Code completion settings
						completion = {
							favoriteStaticMembers = {
								"org.junit.Assert.*",
								"org.junit.jupiter.api.Assertions.*",
								"org.mockito.Mockito.*",
								"org.mockito.ArgumentMatchers.*",
							},
						},
					},
				},
			},
		})

		-- Configure jdtls via lspconfig after nvim-java setup
		require("lspconfig").jdtls.setup({})
	end,
}
