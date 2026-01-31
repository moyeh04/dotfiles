-- Some Tabs Prefrences
-- vim.cmd("set expandtab") --I will use it later... basically it sets tabs to spaces
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = true
vim.opt.formatoptions = vim.opt.formatoptions + "cro"
vim.opt.cursorline = true

-- Set Relative Numbers
vim.cmd("set rnu")
vim.cmd("set nu")

-- Treat underscore as part of a word(w) not WORD(W)
vim.cmd("set iskeyword-=_")

--Set FileFormat to Unix‐style line endings
vim.cmd("set fileformat=unix")

-- Vim Backups
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true

-- Terminal Settings
vim.opt.termguicolors = true

-- Jump Pages
vim.opt.scrolloff = 8
