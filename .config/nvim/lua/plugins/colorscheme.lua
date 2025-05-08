return {
	"tiagovla/tokyodark.nvim",

	lazy = false,
	priority = 1000,
	config = function()
		local tokyonight = require("tokyodark")
		tokyonight.setup({
			transparent_background = false,
			gamma = 1.00,
			comments = { italic = true },

			keywords = { italic = true },
			identifiers = { italic = true },
		})
		vim.cmd([[colorscheme tokyodark]])

		-- Terminal colors
		vim.g.terminal_color_0 = "#06080A"

		vim.g.terminal_color_8 = "#212234"
		vim.g.terminal_color_7 = "#A0A8CD"

		vim.g.terminal_color_15 = "#A0A8CD"
		vim.g.terminal_color_1 = "#EE6D85"
		vim.g.terminal_color_9 = "#EE6D85"
		vim.g.terminal_color_2 = "#95C561"
		vim.g.terminal_color_10 = "#95C561"

		vim.g.terminal_color_3 = "#D7A65F"
		vim.g.terminal_color_11 = "#D7A65F"
		vim.g.terminal_color_4 = "#7199EE"
		vim.g.terminal_color_12 = "#7199EE"
		vim.g.terminal_color_5 = "#A485DD"
		vim.g.terminal_color_13 = "#A485DD"
		vim.g.terminal_color_6 = "#38A89D"
		vim.g.terminal_color_14 = "#38A89D"

		-- Custom highlights
		vim.cmd([[

            highlight Fg guifg=#A0A8CD

            highlight Grey guifg=#4A5057
            highlight Red guifg=#EE6D85
            highlight Orange guifg=#F6955B
            highlight Yellow guifg=#D7A65F

            highlight Green guifg=#95C561
            highlight Blue guifg=#7199EE
            highlight Purple guifg=#A485DD

            highlight Normal guifg=#A0A8CD guibg=#11121D
            highlight NormalNC guifg=#A0A8CD guibg=#11121D
            highlight NormalSB guifg=#A0A8CD guibg=#11121D
            highlight NormalFloat guifg=#A0A8CD guibg=#11121D
            highlight Terminal guifg=#A0A8CD guibg=#11121D
            highlight EndOfBuffer guifg=#212234 guibg=#11121D
            highlight FoldColumn guifg=#A0A8CD guibg=#1A1B2A
            highlight Folded guifg=#A0A8CD guibg=#1A1B2A
            highlight SignColumn guifg=#A0A8CD guibg=#11121D
            highlight ToolbarLine guifg=#A0A8CD
            highlight CursorColumn guibg=#1A1B2A
            highlight CursorLine guibg=#1A1B2A
            highlight ColorColumn guibg=#1A1B2A
            highlight CursorLineNr guifg=#CBCED7
            highlight LineNr guifg=#4A5057

            highlight Conceal guifg=#4A5057 guibg=#1A1B2A
            highlight DiffAdd guibg=#1E2326
            highlight DiffChange guibg=#262B3D
            highlight DiffDelete guibg=#281B27

            highlight DiffText guibg=#1C4474
            highlight Directory guifg=#95C561
            highlight ErrorMsg guifg=#EE6D85 gui=bold,underline
            highlight WarningMsg guifg=#D7A65F gui=bold
            highlight MoreMsg guifg=#7199EE gui=bold
            highlight IncSearch guifg=#CBCED7 guibg=#212234

            highlight Search guifg=#11121D guibg=#98C379

            highlight CurSearch guifg=#11121D guibg=#FE6D85
            highlight MatchParen guibg=#4A5057
            highlight NonText guifg=#4A5057
            highlight Whitespace guifg=#4A5057
            highlight SpecialKey guifg=#4A5057
            highlight Pmenu guifg=#A0A8CD guibg=#11121D

            highlight PmenuSbar guibg=#11121D
            highlight PmenuSel guifg=#11121D guibg=#98C379
            highlight PmenuThumb guibg=#212234
            highlight WildMenu guifg=#11121D guibg=#7199EE
            highlight Question guifg=#D7A65F
            highlight SpellBad guifg=#EE6D85 guisp=#EE6D85 gui=underline

            highlight SpellCap guifg=#D7A65F guisp=#D7A65F gui=underline
            highlight SpellLocal guifg=#7199EE guisp=#7199EE gui=underline
            highlight SpellRare guifg=#A485DD guisp=#A485DD gui=underline

            highlight StatusLine guifg=#A0A8CD guibg=#212234
            highlight StatusLineTerm guifg=#A0A8CD guibg=#212234
            highlight StatusLineNC guifg=#4A5057 guibg=#1A1B2A
            highlight StatusLineTermNC guifg=#4A5057 guibg=#1A1B2A
            highlight TabLine guifg=#A0A8CD guibg=#4A5057
            highlight TabLineFill guifg=#4A5057 guibg=#1A1B2A
            highlight TabLineSel guifg=#11121D guibg=#FE6D85
            highlight WinSeparator guifg=#4A5057
            highlight VertSplit guifg=#CBCED7
            highlight Visual guibg=#212234
            highlight VisualNOS guibg=#212234 gui=underline
            highlight QuickFixLine guifg=#7199EE gui=underline

            highlight Debug guifg=#D7A65F
            highlight debugPC guifg=#11121D guibg=#98C379
            highlight debugBreakpoint guifg=#11121D guibg=#EE6D85
            highlight ToolbarButton guifg=#11121D guibg=#9FBBF3
            highlight FocusedSymbol guibg=#353945

            highlight FloatBorder guifg=#4A5057
            highlight FloatTitle guifg=#7199EE
        ]])
	end,
}
