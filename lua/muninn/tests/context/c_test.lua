-- c_test.lua
-- Validates C99 language feature detection via treesitter

local M = {}

local utils = require("muninn.tests.context.utils")

local FIXTURE = "lua/muninn/tests/fixtures/lang.c"

-- feature validators

-- void greet(void) { ... }  with // comment
local function basic_function(ctxs)
	local ctx = ctxs[1]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 2
		and ctx.fn_body.loc.sRow == 3
end

-- /* \n * block comment \n */ int add(int a, int b) { ... }
local function block_comment(ctxs)
	local ctx = ctxs[2]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 7
		and ctx.fn_body.loc.sRow == 10
end

-- static void helper(void) { ... }
local function static_function(ctxs)
	local ctx = ctxs[3]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 43
		and ctx.fn_body.loc.sRow == 44
end

-- runner

local function test_c()
	local ctxs = utils.load_fixture(FIXTURE, "c")
	assert_not_nil(ctxs, "c treesitter parser must be available")
	assert_equal(3, #ctxs, "should detect all 3 functions")

	assert_true(basic_function(ctxs), "basic function with line comment")
	assert_true(block_comment(ctxs), "function with block comment")
	assert_true(static_function(ctxs), "static function")
end

function M.run()
	local runner = TestRunner.new("c")
	runner:test("C99 language validation", test_c)
	runner:run()
end

return M
