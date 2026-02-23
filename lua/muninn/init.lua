local M = {}

local function init_commands()
    vim.api.nvim_create_user_command("Muninn", require("muninn.cmd.default"), {})
    vim.api.nvim_create_user_command("MuninnAutocomplete", require("muninn.cmd.autocomplete"), {})
    vim.api.nvim_create_user_command("MuninnPrompt", require("muninn.cmd.prompt"), {})
    vim.api.nvim_create_user_command("MuninnTest", require("muninn.cmd.test"), {})
    vim.api.nvim_create_user_command("MuninnDebug", require("muninn.cmd.debug"), {})
    vim.api.nvim_create_user_command("MuninnLog", require("muninn.cmd.log"), {})
    vim.api.nvim_create_user_command("MuninnQuestion", require("muninn.cmd.question"), {})
end

local function init_keymap()
    vim.keymap.set({ "n" }, "<leader>mm", ":Muninn<CR>", { silent = true, desc = "Muninn" })
    vim.keymap.set({ "n" }, "<leader>ma", ":MuninnAutocomplete<CR>", { silent = true, desc = "Muninn Autocomplete" })
    vim.keymap.set({ "n" }, "<leader>mp", ":MuninnPrompt<CR>", { silent = true, desc = "Muninn Prompt" })
    vim.keymap.set({ "n" }, "<leader>me", ":InspectTree<CR>", { silent = true, desc = "Muninn Explore" })
    vim.keymap.set({ "n" }, "<leader>mt", ":MuninnTest<CR>", { silent = true, desc = "Muninn Test" })
    vim.keymap.set({ "n" }, "<leader>md", ":MuninnDebug<CR>", { silent = true, desc = "Muninn Debug" })
    vim.keymap.set({ "n" }, "<leader>ml", ":MuninnLog<CR>", { silent = true, desc = "Muninn Log" })
    vim.keymap.set({ "n" }, "<leader>mq", ":MuninnQuestion<CR>", { silent = true, desc = "Muninn Question" })
end

-- This exists on purpose and does nothing on purpose.
local function noop()
    --do nothing
end

---@param user_input table?
function M.setup(user_input)
    if not vim.g.muninn_init then
        require("muninn.util.log").setup()
        require("muninn.util.event_listeners").setup()
        require("muninn.util.context").setup()
        if user_input then
            noop()
        end
        init_commands()
        init_keymap()
        vim.g.muninn_init = true
    end
end

return M
