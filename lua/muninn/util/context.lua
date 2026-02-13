local M = {}

local logger = require("muninn.util.log").default
local fn_context = require("muninn.util.context_util.fn_context")
local reference = require("muninn.util.context_util.reference")
local time = require("muninn.util.time")

---@alias MnState number
M.STATE_INIT = 0 --[[@as MnState]]
M.STATE_RUN = 1 --[[@as MnState]]
M.STATE_END = 2 --[[@as MnState]]

---@class MnAnnotationContext
---@field ext_namespace number
---@field ext_mark_start number? ext_mark ID
---@field ext_mark_end number? ext_mark ID
---@field state MnState
---@field update_cb function
local MnAnnotationContext = {}
MnAnnotationContext.__index = MnAnnotationContext

---@class MnContext
---@field fn_context MnFnContext
---@field an_context MnAnnotationContext
local MnContext = {}
MnContext.__index = MnContext

---@param fn_ctx MnFnContext
---@return MnContext
local function new_context(fn_ctx)
	local an_context = setmetatable({ anim_state = 0, anim_start = time.new_time() }, MnAnnotationContext)
	return setmetatable({ fn_context = fn_ctx, an_context = an_context }, MnContext)
end

---@param node TSNode
---@return TSNode?
local function find_top_comment(node)
	local sibling = node:prev_sibling()
	if not sibling then
		return nil
	end

	while sibling:type() == "comment" do
		local next_sibling = sibling:prev_sibling()
		if next_sibling then
			sibling = next_sibling
		else
			return sibling
		end
	end
	sibling = sibling:next_sibling()
	if sibling:type() == "comment" then
		return sibling
	end
	return nil
end

---@return MnContext?
function M.get_context_at_cursor()
	local fn_ctxs = M.get_contexts_for_buffer()
	if not fn_ctxs or #fn_ctxs == 0 then
		return nil
	end

	local cursor = vim.fn.getcurpos(0)

	for i = #fn_ctxs, 1, -1 do
		local fn_ctx = fn_ctxs[i]
		if fn_ctx:contains(cursor) then
			return new_context(fn_ctx)
		end
	end
	logger():log("INFO", "failed to find relevant context")
	return nil
end

---@param bufnr number?
---@return MnFnContext[]?
function M.get_contexts_for_buffer(bufnr)
	local source = vim.api.nvim_get_current_buf()
	if bufnr then
		source = bufnr
	end

	local ok, parser = pcall(vim.treesitter.get_parser, source)
	if not ok or not parser then
		return nil
	end

	parser:parse(true)

	local trees = parser:trees()

	logger():log("INFO", "Got " .. #trees .. " trees")

	local results = {}

	local function walk(n)
		local type = n:type()
		local matching_types = { "function_declaration", "function_definition", "func_literal" }
		if vim.tbl_contains(matching_types, type) then
			local scope = n
			if type == "function_definition" or type == "func_literal" then
				local ancestor = n:parent()
				while ancestor do
					local at = ancestor:type()
					if at == "assignment_statement" then
						scope = ancestor
						local grandparent = ancestor:parent()
						if grandparent and grandparent:type() == "variable_declaration" then
							scope = grandparent
						end
						break
					end
					ancestor = ancestor:parent()
				end
			end
			local maybe_comment = find_top_comment(scope)
			local fn_comment = nil
			if maybe_comment then
				fn_comment = reference.new(maybe_comment)
			end

			local fn_body = reference.new(scope)
			local ctx = fn_context.new(source, fn_body, fn_comment)
			table.insert(results, ctx)
		end

		for child in n:iter_children() do
			walk(child)
		end
	end

	for _, tree in ipairs(trees) do
		walk(tree:root())
	end
	logger():log("INFO", "Got " .. #results .. " references")
	return results
end

return M
