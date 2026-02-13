local M = {}

local function muninn_test()
	-- noop
end

local function select_local_function()
	local ctx = require("muninn.util.context").get_context_at_cursor()
	if ctx then
		local sRow, sCol = ctx.fn_context:get_start()
		vim.api.nvim_win_set_cursor(0, { sRow + 1, sCol })
		vim.cmd("normal! v")
		local eRow, eCol = ctx.fn_context:get_end()
		vim.api.nvim_win_set_cursor(0, { eRow + 1, eCol })
	end
end

local function init_commands()
	vim.api.nvim_create_user_command("Muninn", select_local_function, { range = true })
	vim.api.nvim_create_user_command("MuninnAutocomplete", require("muninn.cmd.autocomplete"), { range = false })
	vim.api.nvim_create_user_command("MuninnPrompt", require("muninn.cmd.prompt"), {})
	vim.api.nvim_create_user_command("MuninnTest", muninn_test, {})
	vim.api.nvim_create_user_command("MuninnLog", require("muninn.cmd.log"), {})
end

local function init_keymap()
	vim.keymap.set({ "n" }, "<leader>mm", ":Muninn<CR>", { silent = true, desc = "Muninn" })
	vim.keymap.set({ "n" }, "<leader>ma", ":MuninnAutocomplete<CR>", { silent = true, desc = "Muninn Autocomplete" })
	vim.keymap.set({ "n" }, "<leader>mp", ":MuninnPrompt<CR>", { silent = true, desc = "Muninn Prompt" })
	vim.keymap.set({ "n" }, "<leader>me", ":InspectTree<CR>", { silent = true, desc = "Muninn Explore" })
	vim.keymap.set({ "n" }, "<leader>mt", ":MuninnTest<CR>", { silent = true, desc = "Muninn Test" })
	vim.keymap.set({ "n" }, "<leader>ml", ":MuninnLog<CR>", { silent = true, desc = "Muninn Log" })
end

function M.setup()
	if not vim.g.muninn_init then
		require("muninn.util.log").setup()
		init_commands()
		init_keymap()
		vim.g.muninn_init = true
	end
end

return M
