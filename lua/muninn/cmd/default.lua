local animation = require("muninn.util.animation")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default
local prompt = require("muninn.util.prompt")

return function()
    local ctx = context.get_context_at_cursor()
    logger():log("INFO", "Acquired context")
    if ctx then
        local request_prompt = prompt.build_prompt(ctx, "Please complete this function.")

        logger():log("PROMPT", request_prompt)

        ctx:next_state()
        animation.new_autocomplete_animation():start(ctx)

        local sRow, sCol = ctx.fn_context:get_start()
        vim.api.nvim_win_set_cursor(0, { sRow + 1, sCol })
        vim.cmd("normal! v")
        local eRow, eCol = ctx.fn_context:get_end()
        vim.api.nvim_win_set_cursor(0, { eRow + 1, eCol })

        local cleanup = function()
            vim.schedule(function()
                ctx:next_state()
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
            end)
        end

        vim.defer_fn(cleanup, 5000)
    end
end
