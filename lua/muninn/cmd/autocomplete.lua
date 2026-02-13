local annotation = require("muninn.util.annotation")
local animation = require("muninn.util.animation")
local bufutil = require("muninn.util.bufutil")
local claude = require("muninn.util.claude")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default
local prompt = require("muninn.util.prompt")

return function()
	local ctx = context.get_context_at_cursor()
	logger():log("INFO", "Acquired context")
	if ctx then
		local request_prompt = prompt.build_prompt(ctx, "Please complete this function.")

		logger():log("AUTOCOMPLETE PROMPT", request_prompt)
		local anim = animation.new_autocomplete_animation()

		ctx.an_context.state = context.STATE_RUN
		annotation.start_annotation(ctx, anim)

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
