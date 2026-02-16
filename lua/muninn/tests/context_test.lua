-- context_test.lua
-- Tests for lua/muninn/util/context.lua

local M = {}

local context = require("muninn.util.context")

-- Helper: create a scratch buffer with given lines and lua treesitter
local function make_lua_buffer(lines)
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
	vim.bo[buf].filetype = "lua"
	-- Force treesitter parse
	local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
	if not ok or not parser then
		return nil
	end
	parser:parse(true)
	return buf
end

-- ── fixture: function_as_var ──────────────────────────────

local function test_function_as_var_detects_both()
	local lines = vim.fn.readfile("lua/muninn/tests/fixtures/function_as_var.lua")
	local buf = make_lua_buffer(lines)
	assert_not_nil(buf, "lua treesitter parser must be available")

	local ctxs = context.get_contexts_for_buffer(buf)
	assert_not_nil(ctxs, "should return contexts")
	assert_equal(2, #ctxs, "should detect both functions")
end

local function test_function_as_var_scope_includes_assignment()
	local lines = vim.fn.readfile("lua/muninn/tests/fixtures/function_as_var.lua")
	local buf = make_lua_buffer(lines)
	assert_not_nil(buf, "lua treesitter parser must be available")

	local ctxs = context.get_contexts_for_buffer(buf)
	local fn_var = ctxs[1] -- M.example = function()

	-- The fn_body should start at row 3 col 0 (the assignment_statement),
	-- not row 3 col 12 (the function_definition)
	local sRow, sCol = fn_var.fn_body.loc.sRow, fn_var.fn_body.loc.sCol
	assert_equal(3, sRow, "fn_body start row should be assignment row")
	assert_equal(0, sCol, "fn_body start col should be 0 (start of assignment)")
end

local function test_function_as_var_comment_captured()
	local lines = vim.fn.readfile("lua/muninn/tests/fixtures/function_as_var.lua")
	local buf = make_lua_buffer(lines)
	assert_not_nil(buf, "lua treesitter parser must be available")

	local ctxs = context.get_contexts_for_buffer(buf)
	local fn_var = ctxs[1] -- M.example = function()

	-- The comment "-- This comment isn't captured" is on row 2
	assert_not_nil(fn_var.fn_comment, "comment above M.example should be captured")
	assert_equal(2, fn_var.fn_comment.loc.sRow, "comment should start at row 2")
end

local function test_function_as_var_cursor_contains()
	local lines = vim.fn.readfile("lua/muninn/tests/fixtures/function_as_var.lua")
	local buf = make_lua_buffer(lines)
	assert_not_nil(buf, "lua treesitter parser must be available")

	local ctxs = context.get_contexts_for_buffer(buf)
	local fn_var = ctxs[1] -- M.example = function()

	-- Cursor on "M.example = function()" line (row 3), col 0
	-- getcurpos is 1-based, so row 4, col 1
	local cursor = { 0, 4, 1, 0, 1 }
	assert_true(fn_var:contains(cursor), "cursor on M.example line should be inside scope")
end

local function test_function_declaration_still_works()
	local lines = vim.fn.readfile("lua/muninn/tests/fixtures/function_as_var.lua")
	local buf = make_lua_buffer(lines)
	assert_not_nil(buf, "lua treesitter parser must be available")

	local ctxs = context.get_contexts_for_buffer(buf)
	local fn_decl = ctxs[2] -- function M.working()

	-- function_declaration at row 11, comment at row 10
	assert_not_nil(fn_decl.fn_comment, "comment above M.working should be captured")
	assert_equal(10, fn_decl.fn_comment.loc.sRow, "comment should start at row 10")
	assert_equal(11, fn_decl.fn_body.loc.sRow, "fn_body should start at row 11")
end

-- ── runner ──────────────────────────────────────────────────

function M.run()
	local runner = TestRunner.new("context")

	runner:test("function_as_var: detects both functions", test_function_as_var_detects_both)
	runner:test("function_as_var: scope includes assignment", test_function_as_var_scope_includes_assignment)
	runner:test("function_as_var: comment above var-assigned function is captured", test_function_as_var_comment_captured)
	runner:test("function_as_var: cursor on assignment line is within scope", test_function_as_var_cursor_contains)
	runner:test("function_declaration: still works with comments", test_function_declaration_still_works)

	runner:run()
end

return M
