local context = require("muninn.util.context")
local prompt = require("muninn.util.prompt")
local claude = require("muninn.util.claude")
local input = require("muninn.components.prompt")
local logging = require("muninn.util.log")
local anim = require("muninn.util.decor.animation")

local function launch_error(ctx)
    anim.new_failure_animation():start(ctx)
    vim.defer_fn(function() ctx:next_state() end, 5000)
end

return function()
    local ctx = context.get_context_at_cursor()

    if ctx then
        input.show("Ask a question.", function(question)
            if not question then
                return
            end

            local ask_prompt = prompt.build_query_prompt(ctx, question)

            anim.new_question_animation(ctx):start(ctx)

            claude.execute_prompt(ask_prompt, function(result)
                if result and result.structured_output.result then
                    local l = logging.new_logger()
                    l:log("", result.structured_output.content)
                    l:show(0.5, 0.5)
                else
                    logging.default():log("ERROR", "Query failed")
                    ctx.an_context.preserve_ext = true
                    launch_error(ctx)
                end
                ctx:next_state()
            end)
        end)
    end
end
