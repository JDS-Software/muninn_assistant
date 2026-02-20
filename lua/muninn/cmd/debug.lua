local logger = require("muninn.util.log").default
local animation = require("muninn.util.decor.animation")
local context = require("muninn.util.context")

return function()
    local ctx = context.get_context_at_cursor()

    if ctx then
        local anim = animation.new_debug_animation(ctx)
        logger():log("INFO", ctx.home_dir)

        ctx:next_state()
        anim:start(ctx)

        vim.defer_fn(function()
            ctx:next_state()
        end, 5000)
    end
end
