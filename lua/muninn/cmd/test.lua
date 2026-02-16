local animation = require("muninn.util.animation")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default

---@param ctx MnContext
local function show_failure(ctx)
    ctx:reset_state()
    ctx:next_state()

    animation.new_failure_animation():start(ctx)

    vim.defer_fn(function()
        ctx:next_state()
    end, 5000)
end

local function show_query_annotation(ctx)
    ctx:reset_state()
    ctx:next_state()
    animation.new_query_animation():start(ctx)

    vim.defer_fn(function()
        ctx.an_context.preserve_ext = true
        ctx:next_state()
        vim.defer_fn(function()
            show_failure(ctx)
        end, 100)
    end, 5000)
end

return function()
    local ctx = context.get_context_at_cursor()
    logger():log("INFO", "Test function")
    if ctx then
        local anim = animation.new_autocomplete_animation()
        ctx:next_state()

        anim:start(ctx)

        vim.defer_fn(function()
            ctx.an_context.preserve_ext = true
            ctx:next_state()
            vim.defer_fn(function()
                show_query_annotation(ctx)
            end, 100)
        end, 10000)
    end
end
