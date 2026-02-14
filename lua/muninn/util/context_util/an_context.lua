local M = {}

---@alias MnState number
M.STATE_INIT = 0 --[[@as MnState]]
M.STATE_RUN = 1 --[[@as MnState]]
M.STATE_END = 2 --[[@as MnState]]

local hl_group_base = "muninn_highlight"

---@class MnAnContext
---@field hl_group string
---@field ext_namespace number
---@field hl_namespace string
---@field ext_mark_start number? ext_mark ID
---@field ext_mark_end number? ext_mark ID
---@field state MnState
---@field preserve_ext boolean
---@field update_cb function
local MnAnContext = {}
MnAnContext.__index = MnAnContext

---@param bufnr number
function MnAnContext:clear_highlights(bufnr)
	-- Clear the highlighting by updating extmarks to remove virtual lines
	if self.ext_mark_start then
		local sPos = vim.api.nvim_buf_get_extmark_by_id(bufnr, self.ext_namespace, self.ext_mark_start, {})
		vim.api.nvim_buf_set_extmark(bufnr, self.ext_namespace, sPos[1], sPos[2], {
			id = self.ext_mark_start,
			virt_lines = {},
			virt_text = {},
		})
	end
	if self.ext_mark_end then
		local ePos = vim.api.nvim_buf_get_extmark_by_id(bufnr, self.ext_namespace, self.ext_mark_end, {})
		vim.api.nvim_buf_set_extmark(bufnr, self.ext_namespace, ePos[1], ePos[2], {
			id = self.ext_mark_end,
			virt_lines = {},
			virt_text = {},
		})
	end
end

---@param bufnr number
function MnAnContext:reset(bufnr)
	if self.update_cb then
		self.update_cb = nil
	end

	if not self.preserve_ext then
		if self.ext_namespace then
			vim.api.nvim_buf_clear_namespace(bufnr, self.ext_namespace, 0, -1)
		end
		self.ext_mark_start = nil
		self.ext_mark_end = nil
		self.ext_namespace = nil
	else
		self:clear_highlights(bufnr)
		self.preserve_ext = false
	end
end

---@param fn_context MnFnContext
function M.new(fn_context)
	local options = {}

	local namespace = vim.api.nvim_create_namespace("muninn_annotation" .. fn_context.id)

	local sRow, sCol = fn_context:get_start()
	local ext_mark_start = vim.api.nvim_buf_set_extmark(fn_context.bufnr, namespace, sRow, sCol, options)

	local eRow, eCol = fn_context:get_end()
	local ext_mark_end = vim.api.nvim_buf_set_extmark(fn_context.bufnr, namespace, eRow, eCol, options)

	return setmetatable({
		state = M.STATE_INIT,
		ext_mark_start = ext_mark_start,
		ext_mark_end = ext_mark_end,
		hl_group = hl_group_base .. fn_context.id,
		ext_namespace = namespace,
	}, MnAnContext)
end

return M
