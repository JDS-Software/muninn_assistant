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

-- struct point { int x; int y; };
local function struct_definition(ctxs)
    local ctx = ctxs[3]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 14
        and ctx.fn_body.loc.sRow == 15
end

-- enum direction { NORTH, SOUTH, EAST, WEST };
local function enum_definition(ctxs)
    local ctx = ctxs[4]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 20
        and ctx.fn_body.loc.sRow == 21
end

-- union value { int i; float f; };
local function union_definition(ctxs)
    local ctx = ctxs[5]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 28
        and ctx.fn_body.loc.sRow == 29
end

-- typedef struct { ... } vec2;
local function typedef_struct(ctxs)
    local ctx = ctxs[6]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 34
        and ctx.fn_body.loc.sRow == 35
end

-- static void helper(void) { ... }
local function static_function(ctxs)
    local ctx = ctxs[7]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 43
        and ctx.fn_body.loc.sRow == 44
end

-- int global_count = 42;
local function global_variable(ctxs)
    local ctx = ctxs[8]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 51
        and ctx.fn_body.loc.sRow == 52
end

-- runner

local function test_c()
    local ctxs = utils.load_fixture(FIXTURE, "c")
    assert_not_nil(ctxs, "c treesitter parser must be available")
    assert_equal(8, #ctxs, "should detect all 8 scopes")

    assert_true(basic_function(ctxs), "basic function with line comment")
    assert_true(block_comment(ctxs), "function with block comment")
    assert_true(struct_definition(ctxs), "struct definition")
    assert_true(enum_definition(ctxs), "enum definition")
    assert_true(union_definition(ctxs), "union definition")
    assert_true(typedef_struct(ctxs), "typedef struct")
    assert_true(static_function(ctxs), "static function")
    assert_true(global_variable(ctxs), "global variable")
end

function M.run()
    local runner = TestRunner.new("c")
    runner:test("C99 language validation", test_c)
    runner:run()
end

return M
