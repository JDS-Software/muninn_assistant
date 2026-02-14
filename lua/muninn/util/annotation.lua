local M = {}
local logger = require("muninn.util.log").default

---@param ctx MnContext
---@param animation MnAnimation
---@return function
local function create_animation_callback(ctx, animation)
	return function()
		if ctx:finished() then
			logger():log("INFO", "animation over")
			M.end_annotation(ctx)
			return
		end
		animation:frame()

		vim.api.nvim_set_hl(0, ctx.an_context.hl_group, animation:get_hl())
		local message = animation:message()

		local start_options = {
			id = ctx.an_context.ext_mark_start,
			virt_lines = {
				{
					{ message, ctx.an_context.hl_group },
				},
			},
			virt_text_pos = "inline",
			virt_lines_above = true,
		}
		local sPos = vim.api.nvim_buf_get_extmark_by_id(
			ctx.fn_context.bufnr,
			ctx.an_context.ext_namespace,
			ctx.an_context.ext_mark_start,
			{}
		)
		vim.api.nvim_buf_set_extmark(
			ctx.fn_context.bufnr,
			ctx.an_context.ext_namespace,
			sPos[1],
			sPos[2],
			start_options
		)

		local end_options = {
			id = ctx.an_context.ext_mark_end,
			virt_lines = {
				{
					{ message, ctx.an_context.hl_group },
				},
			},
			virt_text_pos = "eol",
		}
		local ePos = vim.api.nvim_buf_get_extmark_by_id(
			ctx.fn_context.bufnr,
			ctx.an_context.ext_namespace,
			ctx.an_context.ext_mark_end,
			{}
		)
		vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, ctx.an_context.ext_namespace, ePos[1], ePos[2], end_options)
		vim.defer_fn(ctx.an_context.update_cb, animation:get_wait())
	end
end

---@param ctx MnContext
---@param animation MnAnimation
function M.start_annotation(ctx, animation)
	logger():log("INFO", "annotation initialization")
	vim.api.nvim_set_hl(0, ctx.an_context.hl_group, animation:get_hl())

	local options = {
		virt_lines = {
			{
				{ animation:message(), ctx.an_context.hl_group },
			},
		},
		virt_lines_above = true,
	}

	ctx.an_context.update_cb = create_animation_callback(ctx, animation)
	logger():log("INFO", "launching animation")
	ctx.an_context.update_cb()
end

---@param ctx MnContext
function M.end_annotation(ctx)
	ctx.an_context:reset(ctx.fn_context.bufnr)
end

return M
