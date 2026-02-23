-- Copyright (c) 2026-present JDS Consulting, PLLC.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is furnished
-- to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- lua_test.lua
-- Validates Lua language feature detection via treesitter

local M = {}

local utils = require("muninn.tests.context.utils")

local FIXTURE = "lua/muninn/tests/fixtures/lang.lua"

-- feature validators

-- local M = {}
local function module_table_declaration(ctxs)
    local ctx = ctxs[1]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 0
        and ctx.fn_body.loc.sRow == 20
end

-- M.example = function() ... end
local function table_field_assigned(ctxs)
    local ctx = ctxs[2]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 22
        and ctx.fn_body.loc.sRow == 23
        and ctx.fn_body.loc.sCol == 0
end

-- function M.working() ... end
local function declaration_dot(ctxs)
    local ctx = ctxs[3]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 27
        and ctx.fn_body.loc.sRow == 28
end

-- function M:method() ... end
local function method_colon(ctxs)
    local ctx = ctxs[4]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 32
        and ctx.fn_body.loc.sRow == 33
end

-- local function helper() ... end
local function local_function(ctxs)
    local ctx = ctxs[5]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 37
        and ctx.fn_body.loc.sRow == 38
end

-- local assigned = function() ... end
local function local_var_assigned(ctxs)
    local ctx = ctxs[6]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 42
        and ctx.fn_body.loc.sRow == 43
        and ctx.fn_body.loc.sCol == 0
end

-- function global_func() ... end
local function global_function(ctxs)
    local ctx = ctxs[7]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 47
        and ctx.fn_body.loc.sRow == 48
end

-- function M.outer() local function inner() ... end end
local function nested_outer(ctxs)
    local ctx = ctxs[8]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 52
        and ctx.fn_body.loc.sRow == 53
end

-- local function inner() ... end  (inside M.outer)
local function nested_inner(ctxs)
    local ctx = ctxs[9]
    return ctx.fn_body.loc.sRow == 54
end

-- vim.schedule(function() ... end)
local function callback_function(ctxs)
    local ctx = ctxs[10]
    return ctx.fn_body.loc.sRow == 61
end

-- runner

local function test_lua()
    local ctxs = utils.load_fixture(FIXTURE, "lua")
    assert_not_nil(ctxs, "lua treesitter parser must be available")
    assert_equal(10, #ctxs, "should detect all 10 scopes")

    assert_true(module_table_declaration(ctxs), "module table declaration")
    assert_true(table_field_assigned(ctxs), "table-field assigned function")
    assert_true(declaration_dot(ctxs), "function declaration with dot")
    assert_true(method_colon(ctxs), "method syntax with colon")
    assert_true(local_function(ctxs), "local function declaration")
    assert_true(local_var_assigned(ctxs), "local variable-assigned function")
    assert_true(global_function(ctxs), "global function")
    assert_true(nested_outer(ctxs), "nested outer function")
    assert_true(nested_inner(ctxs), "nested inner function")
    assert_true(callback_function(ctxs), "callback function")
end

function M.run()
    local runner = TestRunner.new("lua")
    runner:test("Lua language validation", test_lua)
    runner:run()
end

return M
