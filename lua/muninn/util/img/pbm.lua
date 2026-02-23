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

local render = require("muninn.util.decor.render")

---@param path string
---@return string
local function normalize_path(path)
    return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

---@param frame MnFrame
---@param path string
---@return boolean?
function M.write(frame, path)
    local f = io.open(normalize_path(path), "w")
    if not f then
        return nil
    end
    f:write("P1\n")
    f:write(string.format("%d %d\n", frame.width, frame.height))
    for row = 0, frame.height - 1 do
        local cells = {}
        for col = 1, frame.width do
            cells[col] = tostring(frame.bits[row * frame.width + col])
        end
        f:write(table.concat(cells, " ") .. "\n")
    end
    f:close()
    return true
end

---@param content string
---@return MnFrame?
function M.from_string(content)
    local tokens = {}
    for token in content:gmatch("%S+") do
        tokens[#tokens + 1] = token
    end

    if tokens[1] ~= "P1" then
        return nil
    end

    local width = tonumber(tokens[2])
    local height = tonumber(tokens[3])
    if not width or not height then
        return nil
    end

    local bits = {}
    for i = 4, #tokens do
        local token = tokens[i]
        for ch in token:gmatch(".") do
            local v = tonumber(ch)
            if not v then
                return nil
            end
            bits[#bits + 1] = v
        end
    end

    local ok, frame = pcall(render.new_frame, width, height, bits)
    if not ok then
        return nil
    end
    return frame
end

---@param path string
---@return MnFrame?
function M.read(path)
    local f = io.open(normalize_path(path), "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()

    -- Strip comments: # through end of line (PBM spec allows inline comments)
    content = content:gsub("#[^\n]*", "")
    return M.from_string(content)
end

return M
