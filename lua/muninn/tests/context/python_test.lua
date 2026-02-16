-- python_test.lua
-- Validates Python language feature detection via treesitter

local M = {}

local utils = require("muninn.tests.context.utils")

local FIXTURE = "lua/muninn/tests/fixtures/lang.py"

-- feature validators

-- def greet(): ...  with # comment
local function basic_function(ctxs)
	local ctx = ctxs[1]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 0
		and ctx.fn_body.loc.sRow == 1
end

-- def add(a, b): ...
local function function_with_params(ctxs)
	local ctx = ctxs[2]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 5
		and ctx.fn_body.loc.sRow == 6
end

-- class Point: ...
local function class_definition(ctxs)
	local ctx = ctxs[3]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 10
		and ctx.fn_body.loc.sRow == 11
end

-- def __init__(self, x, y): ...  (method inside class)
local function method_init(ctxs)
	local ctx = ctxs[4]
	return ctx.fn_comment == nil
		and ctx.fn_body.loc.sRow == 12
end

-- def __str__(self): ...  (method with # comment)
local function method_str(ctxs)
	local ctx = ctxs[5]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 16
		and ctx.fn_body.loc.sRow == 17
end

-- @cache \n def expensive(): ...
local function decorated_function(ctxs)
	local ctx = ctxs[6]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 21
		and ctx.fn_body.loc.sRow == 22
end

-- @dataclass \n class Config: ...
local function decorated_class(ctxs)
	local ctx = ctxs[7]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 27
		and ctx.fn_body.loc.sRow == 28
end

-- async def fetch(url): ...
local function async_function(ctxs)
	local ctx = ctxs[8]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 34
		and ctx.fn_body.loc.sRow == 35
end

-- @app.route("/") \n @login_required \n def index(): ...
local function multiple_decorators(ctxs)
	local ctx = ctxs[9]
	return ctx.fn_comment ~= nil
		and ctx.fn_comment.loc.sRow == 39
		and ctx.fn_body.loc.sRow == 40
end

-- runner

local function test_python()
	local ctxs = utils.load_fixture(FIXTURE, "python")
	assert_not_nil(ctxs, "python treesitter parser must be available")
	assert_equal(9, #ctxs, "should detect all 9 scopes")

	assert_true(basic_function(ctxs), "basic function with line comment")
	assert_true(function_with_params(ctxs), "function with parameters")
	assert_true(class_definition(ctxs), "class definition")
	assert_true(method_init(ctxs), "method inside class (no comment)")
	assert_true(method_str(ctxs), "method with comment")
	assert_true(decorated_function(ctxs), "decorated function")
	assert_true(decorated_class(ctxs), "decorated class")
	assert_true(async_function(ctxs), "async function")
	assert_true(multiple_decorators(ctxs), "multiple decorators")
end

function M.run()
	local runner = TestRunner.new("python")
	runner:test("Python language validation", test_python)
	runner:run()
end

return M
