local prompt = require("muninn.util.prompt")
local annotation = require("muninn.util.annotation")
local claude = require("muninn.util.claude")
local bufutil = require("muninn.util.bufutil")
local prompt_dialogue = require("muninn.components.prompt")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default

return function()
	local ctx = context.get_context_at_cursor()
	logger():log("INFO", "Acquired context")
	if ctx then
		local cb = function(user_input)
			local request_prompt = prompt.build_prompt(ctx, user_input)

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
		prompt_dialogue.show("What would you like Muninn to do?", cb)
	end
end
