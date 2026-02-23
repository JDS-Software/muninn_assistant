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

---@class MnFnContext
---@field id string
---@field bufnr number
---@field fn_body MnReference
---@field fn_comment MnReference?
local MnFnContext = {}
MnFnContext.__index = MnFnContext

---@param bufnr number the buffer number for the function context
---@param fn_body MnReference the function reference
---@param fn_comment MnReference? the function's upper-most comment, if one exists
---@return MnFnContext
function M.new(bufnr, fn_body, fn_comment)
    local sr, sc, er, ec = fn_body.node:range()
    local id_str = table.concat({ sr, sc, er, ec }, "_")
    return setmetatable(
        { bufnr = bufnr, fn_body = fn_body, fn_comment = fn_comment, id = id_str },
        MnFnContext
    )
end

---@return number row
---@return number col
function MnFnContext:get_start()
    if self.fn_comment and self.fn_comment.loc then
        return self.fn_comment.loc.sRow, self.fn_comment.loc.sCol
    end
    return self.fn_body.loc.sRow, self.fn_body.loc.sCol
end

---
---@return number row
---@return number col
function MnFnContext:get_end()
    return self.fn_body.loc.eRow, self.fn_body.loc.eCol
end

---@param cursor table
---@return boolean true if the context intersects the cursor position
function MnFnContext:contains(cursor)
    local sRow, sCol = self:get_start()
    local eRow, eCol = self:get_end()
    local cRow = cursor[2] - 1 -- getcurpos is 1-based, treesitter locations are 0-based
    local cCol = cursor[3] - 1
    if cRow < sRow or cRow > eRow then
        return false
    end
    if cRow == sRow and cCol < sCol then
        return false
    end
    if cRow == eRow and cCol >= eCol then
        return false
    end
    return true
end

return M
