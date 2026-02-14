-- go_test.lua
-- Validates Go language feature detection via treesitter

local M = {}

local utils = require("muninn.tests.context.utils")

local FIXTURE = "lua/muninn/tests/fixtures/lang.go"

-- feature validators

-- func greet() { ... }  with // comment
local function basic_function(ctxs)
	local ctx = ctxs[1]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 4
		and ctx.fn_body.loc.sRow == 5
end

-- /* \n * block comment \n */ func add(a, b int) int { ... }
local function block_comment(ctxs)
	local ctx = ctxs[2]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 9
		and ctx.fn_body.loc.sRow == 12
end

-- func (p Point) String() string { ... }
local function method_declaration(ctxs)
	local ctx = ctxs[3]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 16
		and ctx.fn_body.loc.sRow == 17
end

-- type Point struct { ... }
local function struct_type(ctxs)
	local ctx = ctxs[4]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 21
		and ctx.fn_body.loc.sRow == 22
end

-- type Greeter interface { ... }
local function interface_type(ctxs)
	local ctx = ctxs[5]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 27
		and ctx.fn_body.loc.sRow == 28
end

-- var handler = func() { ... }
local function anonymous_function(ctxs)
	local ctx = ctxs[6]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 32
		and ctx.fn_body.loc.sRow == 33
end

-- func divide(a, b float64) (float64, error) { ... }
local function multi_return(ctxs)
	local ctx = ctxs[7]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 37
		and ctx.fn_body.loc.sRow == 38
end

-- func sum(nums ...int) int { ... }
local function variadic_function(ctxs)
	local ctx = ctxs[8]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 45
		and ctx.fn_body.loc.sRow == 46
end

-- var globalCount = 42
local function global_variable(ctxs)
	local ctx = ctxs[9]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 54
		and ctx.fn_body.loc.sRow == 55
end

-- runner

local function test_go()
	local ctxs = utils.load_fixture(FIXTURE, "go")
	assert_not_nil(ctxs, "go treesitter parser must be available")
	assert_equal(9, #ctxs, "should detect all 9 scopes")

	assert_true(basic_function(ctxs), "basic function with line comment")
	assert_true(block_comment(ctxs), "function with block comment")
	assert_true(method_declaration(ctxs), "method declaration")
	assert_true(struct_type(ctxs), "struct type definition")
	assert_true(interface_type(ctxs), "interface type definition")
	assert_true(anonymous_function(ctxs), "anonymous function assignment")
	assert_true(multi_return(ctxs), "multi-return function")
	assert_true(variadic_function(ctxs), "variadic function")
	assert_true(global_variable(ctxs), "global variable")
end

function M.run()
	local runner = TestRunner.new("go")
	runner:test("Go language validation", test_go)
	runner:run()
end

return M
