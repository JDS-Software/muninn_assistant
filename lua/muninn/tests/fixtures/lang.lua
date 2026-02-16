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
