-- For conciseness
local opts = { noremap = true, silent = true }

-- Reload Current Buffer
vim.api.nvim_set_keymap("n", "<leader>r", ":e<CR>", opts)

-- Hotkey to insert the shebang line at the top of any file

vim.keymap.set("n", "<leader>bas", function()
	local first_line = vim.api.nvim_get_current_line()

	-- Check if the first line is empty
	if first_line == "" then
		-- Insert the shebang line

		vim.api.nvim_set_current_line("#!/usr/bin/env bash")

		-- Move to the next line and insert a comment
		vim.api.nvim_command("normal! o# ")
		-- Switch to insert mode
		-- vim.api.nvim_command("startinsert")
	elseif first_line == "#!/usr/bin/env bash" or first_line == "#!/bin/bash" then
		-- If the first line is already a valid shebang, do nothing
		print("Shebang already exists; no action taken.")
	else
		-- If the first line is not empty and not a shebang, print a message
		print("Something already exists at the first line; shebang not inserted.")
	end
end, { silent = true })

-- For Normal shellscripting

vim.keymap.set("n", "<leader>bs", function()
	local first_line = vim.api.nvim_get_current_line()

	-- Check if the first line is empty
	if first_line == "" then
		-- Insert the shebang line

		vim.api.nvim_set_current_line("#!/bin/bash")

		-- Move to the next line and insert a comment
		vim.api.nvim_command("normal! o")
		-- Switch to insert mode
		-- vim.api.nvim_command("startinsert")
	elseif first_line == "#!/usr/bin/env bash" or first_line == "#!/bin/bash" then
		-- If the first line is already a valid shebang, do nothing
		print("Shebang already exists; no action taken.")
	else
		-- If the first line is not empty and not a shebang, print a message
		print("Something already exists at the first line; shebang not inserted.")
	end
end, { silent = true })

-- For Python
vim.keymap.set("n", "<leader>py", function()
	local first_line = vim.api.nvim_get_current_line()

	-- Check if the first line is empty
	if first_line == "" then
		-- Insert the shebang line

		vim.api.nvim_set_current_line("#!/usr/bin/python3")

		-- Move to the next line and insert a comment
		vim.api.nvim_command("normal! o# ")
		-- Switch to insert mode
		-- vim.api.nvim_command("startinsert")
	elseif first_line == "#!/usr/bin/python3" or first_line == "#!/usr/bin/python3" then
		-- If the first line is already a valid shebang, do nothing
		print("Shebang already exists; no action taken.")
	else
		-- If the first line is not empty and not a shebang, print a message
		print("Something already exists at the first line; shebang not inserted.")
	end
end, { silent = true })

-- -- Hotkey to insert the shebang line at the top of any file without #comment
--
-- vim.keymap.set("n", "<leader>s", function()
-- 	local first_line = vim.api.nvim_get_current_line()
--
-- 	-- Check if the first line is empty
--
-- 	if first_line == "" then
-- 		vim.api.nvim_set_current_line("#!/usr/bin/env bash")
-- 		vim.api.nvim_command("normal! o") -- Move to the next line
-- 	elseif first_line == "#!/usr/bin/env bash" or first_line == "#!/bin/bash" then
-- 		-- If the first line is already a valid shebang, do nothing
-- 		print("Shebang already exists; no action taken.")
-- 	else
-- 		-- If the first line is not empty and not a shebang, print a message
--
-- 		print("Something already exists at the first line; shebang not inserted.")
-- 	end
-- end, { silent = true })

-- Autocommand to automatically run chmod +x on save if the first line is a valid shebang
vim.api.nvim_create_autocmd("BufWritePost", {

	pattern = "*", -- This matches all file types
	callback = function()
		local first_line = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]

		-- Check for valid shebangs
		if first_line and (first_line:find("#!/usr/bin/env bash") or first_line:find("#!/bin/bash")) then
			-- Execute the command silently
			vim.api.nvim_command("silent !chmod +x " .. vim.fn.expand("%:p"))
		end
	end,
})

vim.api.nvim_set_keymap("n", "<F8>", ":w<CR>:!shellcheck %:t<CR>", { noremap = true, silent = true })
