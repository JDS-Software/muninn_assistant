local animation = require("muninn.util.animation")
local bufutil = require("muninn.util.bufutil")
local claude = require("muninn.util.claude")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default
local prompt = require("muninn.util.prompt")

---@param ctx MnContext
local function alert_failure(ctx)
    local anim = animation.new_failure_animation()

    ctx:reset_state()
    ctx:next_state()

    anim:start(ctx)


    vim.defer_fn(function()
        ctx:next_state()
    end, 5000)
end

return function()
    local ctx = context.get_context_at_cursor()
    logger():log("INFO", "Acquired context")
    if ctx then
        local request_prompt = prompt.build_prompt(ctx, "Please complete this function.")

        logger():log("AUTOCOMPLETE PROMPT", request_prompt)

        ctx:next_state()

        local anim = animation.new_autocomplete_animation()
        anim:start(ctx)

        ---@param result ClaudeResult
        local result_cb = function(result)
            if result and result.structured_output and result.structured_output.content then
                bufutil.insert_safe_result_at_function(ctx, result.structured_output.content)
            else
                if result then
                    logger():log("ERROR", "Claude returned result without structured output")
                end
                ctx.an_context.preserve_ext = true
                vim.defer_fn(function()
                    alert_failure(ctx)
                end, 100)
            end
            ctx:next_state()
        end

        claude.execute_prompt(request_prompt, result_cb)
    end
end
