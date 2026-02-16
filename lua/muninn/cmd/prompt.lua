local prompt = require("muninn.util.prompt")
local claude = require("muninn.util.claude")
local bufutil = require("muninn.util.bufutil")
local prompt_dialogue = require("muninn.components.prompt")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default
local animation = require("muninn.util.decor.animation")
---
---@param ctx MnContext
local function alert_failure(ctx)
    ctx:reset_state()
    ctx:next_state()
    animation.new_failure_animation():start(ctx)

    vim.defer_fn(function()
        ctx:next_state()
    end, 5000)
end

return function()
    local ctx = context.get_context_at_cursor()
    logger():log("INFO", "Acquired context")
    if ctx then
        local cb = function(user_input)
            if not user_input or #user_input == 0 then
                return
            end

            local request_prompt = prompt.build_prompt(ctx, user_input)

            ctx:next_state()

            animation.new_query_animation():start(ctx)

            ---@param result ClaudeResult
            local result_cb = function(result)
                if result and result.structured_output and result.structured_output.content then
                    bufutil.insert_safe_result_at_function(ctx, result.structured_output.content)
                else
                    if result then
                        logger():alert("ERROR", "Claude returned result without structured output")
                    else
                        logger():alert("ERROR", "Claude failed. Check the MuninnLog for more")
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
        prompt_dialogue.show("What would you like Muninn to do?", cb)
    end
end
