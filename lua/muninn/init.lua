local M = {}

local function init_commands()
    vim.api.nvim_create_user_command("Muninn", require("muninn.cmd.default"), {})
    vim.api.nvim_create_user_command("MuninnAutocomplete", require("muninn.cmd.autocomplete"), {})
    vim.api.nvim_create_user_command("MuninnPrompt", require("muninn.cmd.prompt"), {})
    vim.api.nvim_create_user_command("MuninnTest", require("muninn.cmd.test"), {})
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

function M.setup(user_input)
    if not vim.g.muninn_init then
        require("muninn.util.log").setup()
        require("muninn.util.event_listeners").setup()
        init_commands()
        init_keymap()
        vim.g.muninn_init = true
    end
end

return M
