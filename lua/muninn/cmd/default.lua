local annotation = require("muninn.util.annotation")
local animation = require("muninn.util.animation")
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
		annotation.start_annotation(ctx, anim)

		local sRow, sCol = ctx.fn_context:get_start()
		vim.api.nvim_win_set_cursor(0, { sRow + 1, sCol })
		vim.cmd("normal! v")
		local eRow, eCol = ctx.fn_context:get_end()
		vim.api.nvim_win_set_cursor(0, { eRow + 1, eCol })

		vim.defer_fn(function()
			ctx.an_context.state = context.STATE_END
			vim.cmd("normal! \\<Esc>")
		end, 5000)
	end
end
