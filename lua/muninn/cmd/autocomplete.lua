-- Copyright (c) 2026-present JDS Consulting, PLLC.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is furnished
-- to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

local animation = require("muninn.util.decor.animation")
local bufutil = require("muninn.util.bufutil")
local claude = require("muninn.util.claude")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default
local prompt = require("muninn.util.prompt")

---@param ctx MnContext
local function alert_failure(ctx)
    local anim = animation.new_failure_animation()

    ctx:reset_state()

    anim:start(ctx)


    vim.defer_fn(function()
        ctx:next_state()
    end, 5000)
end

return function()
    local ctx = context.get_context_at_cursor()
    logger():log("INFO", "Acquired context")
    if ctx then
        local request_prompt = prompt.build_task_prompt(ctx, "Please complete this function.")

        logger():log("AUTOCOMPLETE PROMPT", request_prompt)

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
                end, anim:get_frame_time():to_millis() * 2)
            end
            ctx:next_state()
        end

        claude.execute_prompt(request_prompt, result_cb)
    end
end
