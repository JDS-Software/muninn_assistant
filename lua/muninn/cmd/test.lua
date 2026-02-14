local annotation = require("muninn.util.annotation")
local animation = require("muninn.util.animation")
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default

---@param ctx MnContext
local function alert_failure(ctx)
	local anim = animation.new_failure_animation()

	ctx:reset_state()
	ctx:next_state()
	annotation.start_annotation(ctx, anim)
	vim.defer_fn(function()
		ctx:next_state()
	end, 5000)
end

return function()
	local ctx = context.get_context_at_cursor()
	logger():log("INFO", "Test function")
	if ctx then
		local anim = animation.new_demo_animation()
		ctx:next_state()

		annotation.start_annotation(ctx, anim)

		vim.defer_fn(function()
			ctx.an_context.preserve_ext = true
			ctx:next_state()
			logger():alert("ERROR", "Claude failed. Check the MuninnLog for more")
			vim.defer_fn(function()
				alert_failure(ctx)
			end, 100)
		end, 5000)
	end
end
