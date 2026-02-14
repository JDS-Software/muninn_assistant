-- javascript_test.lua
-- Validates JavaScript language feature detection via treesitter

local M = {}

local utils = require("muninn.tests.context.utils")

local FIXTURE = "lua/muninn/tests/fixtures/lang.js"

-- feature validators

-- function greet() { ... }  with // comment
local function basic_function(ctxs)
	local ctx = ctxs[1]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 0
		and ctx.fn_body.loc.sRow == 1
end

-- function add(a, b) { ... }
local function function_with_params(ctxs)
	local ctx = ctxs[2]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 5
		and ctx.fn_body.loc.sRow == 6
end

-- var multiply = function(a, b) { ... };
local function var_function_expression(ctxs)
	local ctx = ctxs[3]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 10
		and ctx.fn_body.loc.sRow == 11
end

-- const handler = () => { ... };
local function arrow_function(ctxs)
	local ctx = ctxs[4]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 15
		and ctx.fn_body.loc.sRow == 16
end

-- class Point { ... }
local function class_declaration(ctxs)
	local ctx = ctxs[5]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 20
		and ctx.fn_body.loc.sRow == 21
end

-- function* counter() { ... }
local function generator_function(ctxs)
	local ctx = ctxs[6]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 32
		and ctx.fn_body.loc.sRow == 33
end

-- async function fetchData(url) { ... }
local function async_function(ctxs)
	local ctx = ctxs[7]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 40
		and ctx.fn_body.loc.sRow == 41
end

-- var globalCount = 42;
local function global_variable(ctxs)
	local ctx = ctxs[8]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 46
		and ctx.fn_body.loc.sRow == 47
end

-- runner

local function test_javascript()
	local ctxs = utils.load_fixture(FIXTURE, "javascript")
	assert_not_nil(ctxs, "javascript treesitter parser must be available")
	assert_equal(8, #ctxs, "should detect all 8 scopes")

	assert_true(basic_function(ctxs), "basic function declaration")
	assert_true(function_with_params(ctxs), "function with parameters")
	assert_true(var_function_expression(ctxs), "var function expression")
	assert_true(arrow_function(ctxs), "arrow function")
	assert_true(class_declaration(ctxs), "class declaration")
	assert_true(generator_function(ctxs), "generator function")
	assert_true(async_function(ctxs), "async function")
	assert_true(global_variable(ctxs), "global variable")
end

function M.run()
	local runner = TestRunner.new("javascript")
	runner:test("JavaScript language validation", test_javascript)
	runner:run()
end

return M
