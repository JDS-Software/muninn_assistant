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

-- typescript_test.lua
-- Validates TypeScript language feature detection via treesitter

local M = {}

local utils = require("muninn.tests.context.utils")

local FIXTURE = "lua/muninn/tests/fixtures/lang.ts"

-- feature validators

-- function greet(): void { ... }
local function basic_function(ctxs)
    local ctx = ctxs[1]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 0
        and ctx.fn_body.loc.sRow == 1
end

-- function add(a: number, b: number): number { ... }
local function typed_parameters(ctxs)
    local ctx = ctxs[2]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 5
        and ctx.fn_body.loc.sRow == 6
end

-- interface Point { ... }
local function interface_definition(ctxs)
    local ctx = ctxs[3]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 10
        and ctx.fn_body.loc.sRow == 11
end

-- type Direction = "north" | "south" | "east" | "west";
local function type_alias(ctxs)
    local ctx = ctxs[4]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 16
        and ctx.fn_body.loc.sRow == 17
end

-- class Vector { ... }
local function class_declaration(ctxs)
    local ctx = ctxs[5]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 19
        and ctx.fn_body.loc.sRow == 20
end

-- const multiply = (a: number, b: number): number => { ... };
local function const_arrow_function(ctxs)
    local ctx = ctxs[6]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 28
        and ctx.fn_body.loc.sRow == 29
end

-- enum Color { ... }
local function enum_declaration(ctxs)
    local ctx = ctxs[7]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 33
        and ctx.fn_body.loc.sRow == 34
end

-- function identity<T>(arg: T): T { ... }
local function generic_function(ctxs)
    local ctx = ctxs[8]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 40
        and ctx.fn_body.loc.sRow == 41
end

-- async function fetchData(url: string): Promise<Response> { ... }
local function async_function(ctxs)
    local ctx = ctxs[9]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 45
        and ctx.fn_body.loc.sRow == 46
end

-- var globalCount: number = 42;
local function global_variable(ctxs)
    local ctx = ctxs[10]
    return ctx.fn_comment ~= nil
        and ctx.fn_comment.loc.sRow == 50
        and ctx.fn_body.loc.sRow == 51
end

-- runner

local function test_typescript()
    local ctxs = utils.load_fixture(FIXTURE, "typescript")
    assert_not_nil(ctxs, "typescript treesitter parser must be available")
    assert_equal(10, #ctxs, "should detect all 10 scopes")

    assert_true(basic_function(ctxs), "basic function")
    assert_true(typed_parameters(ctxs), "typed parameters function")
    assert_true(interface_definition(ctxs), "interface definition")
    assert_true(type_alias(ctxs), "type alias")
    assert_true(class_declaration(ctxs), "class declaration")
    assert_true(const_arrow_function(ctxs), "const arrow function")
    assert_true(enum_declaration(ctxs), "enum declaration")
    assert_true(generic_function(ctxs), "generic function")
    assert_true(async_function(ctxs), "async function")
    assert_true(global_variable(ctxs), "global variable")
end

function M.run()
    local runner = TestRunner.new("typescript")
    runner:test("TypeScript language validation", test_typescript)
    runner:run()
end

return M
