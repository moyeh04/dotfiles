-- Some Tabs Prefrences
-- vim.cmd("set expandtab") --I will use it later... basically it sets tabs to spaces
vim.cmd("set tabstop=4")
vim.cmd("set softtabstop=4")
vim.cmd("set shiftwidth=4")
vim.cmd("set textwidth=80")
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = true
vim.opt.formatoptions = vim.opt.formatoptions + "cro"
vim.opt.cursorline = true

-- Set Relative Numbers
vim.cmd("set rnu")
vim.cmd("set nu")

--Set FileFormat
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
