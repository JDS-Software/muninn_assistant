local M = {}

local logger = require("muninn.util.log").default
local fn_context = require("muninn.util.context_util.fn_context")
local an_context = require("muninn.util.context_util.an_context")
local reference = require("muninn.util.context_util.reference")

local matching_function_types = { "function_definition", "func_literal" }

local fn_types = {
	"function_declaration",
	"function_definition",
	"func_literal",
	"method_declaration",
	"generator_function_declaration",
}

local struct_types = {
	"struct_specifier",
	"enum_specifier",
	"union_specifier",
	"type_declaration",
	"class_declaration",
	"class_definition",
	"interface_declaration",
	"type_alias_declaration",
	"enum_declaration",
}

local decl_types = {
	"variable_declaration",
	"declaration",
	"lexical_declaration",
	"var_declaration",
}

---@class MnContext
---@field fn_context MnFnContext
---@field an_context MnAnContext
---@field name string?
local MnContext = {}
MnContext.__index = MnContext

function MnContext:reset_state()
	self.an_context.state = an_context.STATE_INIT
end

function MnContext:next_state()
	if self:finished() then
		return
	end
	self.an_context.state = self.an_context.state + 1
end

---@return boolean
function MnContext:finished()
	return self.an_context.state == an_context.STATE_END
end

--- reads the relevant name from the fn_context's TSNode or "anonymous"
---@return string
function MnContext:_read_name()
	if self.fn_context.fn_body.node:named() then
		local name_node = self.fn_context.fn_body.node:field("name")[1]
		if name_node then
			return vim.treesitter.get_node_text(name_node, self.fn_context.bufnr, {})
		end
	end
	return "anonymous"
end

function MnContext:get_bufnr()
	return self.fn_context.bufnr
end

---@return string
function MnContext:get_name()
	if not self.name then
		self.name = self:_read_name()
	end
	return self.name
end

---@param fn_ctx MnFnContext
---@return MnContext
local function new_context(fn_ctx)
	local an_ctx = an_context.new(fn_ctx)
	return setmetatable({ fn_context = fn_ctx, an_context = an_ctx }, MnContext)
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
			local ssr, _, _, _ = sibling:range()
			local _, _, nser, _ = next_sibling:range()
			if ssr - nser > 1 then
				return sibling
			end
			sibling = next_sibling
		else
			return sibling
		end
	end

	sibling = sibling:next_sibling()
	if sibling and sibling:type() == "comment" then
		return sibling
	end
	return nil
end

---@param bufnr number?
---@return MnContext?
function M.get_context_at_cursor(bufnr)
	local fn_ctxs = M.get_contexts_for_buffer(bufnr)
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

---@param n TSNode
---@return TSNode
local function get_relevant_fn_scope(n)
	local scope = n
	local type = n:type()
	if vim.list_contains(matching_function_types, type) then
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
			elseif at == "decorated_definition" then
				scope = ancestor
				break
			elseif vim.list_contains(decl_types, at) then
				scope = ancestor
				break
			end
			ancestor = ancestor:parent()
		end
	end
	return scope
end

---@param n TSNode
---@return TSNode?
local function get_relevant_struct_scope(n)
	local parent = n:parent()
	if parent and parent:type() == "type_definition" then
		return parent
	end
	if parent and parent:type() == "decorated_definition" then
		return parent
	end
	return parent and parent:type() == "declaration" and parent or n
end

---@param n TSNode
---@return TSNode?
local function get_relevant_var_scope(n)
	local parent = n:parent()
	if not parent or parent:parent() ~= nil then
		return nil
	end
	for child in n:iter_children() do
		if child:type() == "function_declarator" then
			return nil
		end
	end
	return n
end

---@param scope TSNode
---@return string
local function scope_key(scope)
	local sr, sc, er, ec = scope:range()
	return sr .. ":" .. sc .. ":" .. er .. ":" .. ec
end

---@param n TSNode
---@param source number
---@param results table
---@param seen table
local function process_node(n, source, results, seen)
	local type = n:type()

	local scope = nil
	if vim.tbl_contains(fn_types, type) then
		scope = get_relevant_fn_scope(n)
	elseif vim.tbl_contains(struct_types, type) then
		scope = get_relevant_struct_scope(n)
		if not scope then
			return
		end
	elseif vim.tbl_contains(decl_types, type) then
		scope = get_relevant_var_scope(n)
		if not scope then
			return
		end
	end

	if scope then
		local key = scope_key(scope)
		if seen[key] then
			return
		end
		seen[key] = true

		local fn_body = reference.new(scope)

		local maybe_comment = find_top_comment(scope)
		local fn_comment = nil
		if maybe_comment then
			fn_comment = reference.new(maybe_comment)
		end

		local ctx = fn_context.new(source, fn_body, fn_comment)
		table.insert(results, ctx)
	end
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

	local results = {}
	local seen = {}

	local function walk(n)
		process_node(n, source, results, seen)
		for child in n:iter_children() do
			walk(child)
		end
	end

	for _, tree in ipairs(trees) do
		walk(tree:root())
	end
	return results
end

return M
