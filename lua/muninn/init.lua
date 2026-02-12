local M = {}
local logging = require("muninn.util.log")
local context = require("muninn.util.context")
local prompt = require("muninn.util.prompt")
local annotation = require("muninn.util.annotation")
local claude = require("muninn.util.claude")
local bufutil = require("muninn.util.bufutil")

local function muninn_test()
    -- noop
end

-- comment
local function select_local_function()
    local ctx = context.get_context_at_cursor()
    if ctx then
        local sRow, sCol = ctx.fn_context:get_start()
        vim.api.nvim_win_set_cursor(0, { sRow + 1, sCol })
        vim.cmd("normal! v")
        local eRow, eCol = ctx.fn_context:get_end()
        vim.api.nvim_win_set_cursor(0, { eRow + 1, eCol })
    end
end

local function muninn_autocomplete()
    local ctx = context.get_context_at_cursor()
    logging.default():log("INFO", "Acquired context")
    if ctx then
        local request_prompt = prompt.build_prompt(ctx, "Please complete this function.")

        ctx.an_context.state = context.STATE_RUN
        annotation.start_annotation(ctx)

        ---@param result ClaudeResult
        local result_cb = function(result)
            if result then
                bufutil.insert_safe_result_at_function(ctx, result.structured_output.content)
            end
            ctx.an_context.state = context.STATE_END
        end
        claude.execute_prompt(request_prompt, result_cb)
    end
end


local function init_commands()
    vim.api.nvim_create_user_command("Muninn", select_local_function, { range = true })
    vim.api.nvim_create_user_command("MuninnAutocomplete", muninn_autocomplete, { range = false })
    vim.api.nvim_create_user_command("MuninnTest", muninn_test, {})
    vim.api.nvim_create_user_command("MuninnLog", function()
        logging.default():show(0.33, 0.80)
    end, {})
end

local function init_keymap()
    vim.keymap.set({ "n" }, "<leader>mm", ":Muninn<CR>", { silent = true, desc = "Muninn" })
    vim.keymap.set({ "n" }, "<leader>ma", ":MuninnAutocomplete<CR>", { silent = true, desc = "Muninn Autocomplete" })
    vim.keymap.set({ "n" }, "<leader>me", ":InspectTree<CR>", { silent = true, desc = "Muninn Explore" })
    vim.keymap.set({ "n" }, "<leader>mt", ":MuninnTest<CR>", { silent = true, desc = "Muninn Test" })
    vim.keymap.set({ "n" }, "<leader>ml", ":MuninnLog<CR>", { silent = true, desc = "Muninn Log" })
end

function M.setup()
    if not vim.g.muninn_init then
        logging.setup()
        init_commands()
        init_keymap()
        vim.g.muninn_init = true
    end
end

return M
