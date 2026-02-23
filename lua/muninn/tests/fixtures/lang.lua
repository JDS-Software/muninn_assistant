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

local M = {}

-- table-field assigned anonymous function
M.example = function()
    print("function_definition inside assignment_statement")
end

-- function declaration with dot
function M.working()
    print("function_declaration with dot accessor")
end

-- method syntax with colon
function M:method()
    print("function_declaration with colon accessor")
end

-- local function declaration
local function helper()
    print("local function_declaration")
end

-- local variable-assigned function
local assigned = function()
    print("function_definition inside variable_declaration")
end

-- top-level global function
function global_func()
    print("function_declaration without table prefix")
end

-- nested function
function M.outer()
    local function inner()
        print("nested function_declaration")
    end
    inner()
end

-- callback function (no assignment ancestor)
vim.schedule(function()
    print("function_definition as argument")
end)

return M
