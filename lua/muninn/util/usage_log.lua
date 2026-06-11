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

---@class MnUsageLogModelEntry
---@field calls integer
---@field cost_usd number
---@field input_tokens integer
---@field output_tokens integer
---@field cache_read_input_tokens integer
---@field cache_creation_input_tokens integer

---@class MnUsageLogEntry
---@field ts integer
---@field cost_usd number
---@field duration_api_ms integer
---@field input_tokens integer
---@field output_tokens integer
---@field cache_read_input_tokens integer
---@field cache_creation_input_tokens integer
---@field models table<string, MnUsageLogModelEntry>?

---@return string
local function state_dir()
    local xdg = os.getenv("XDG_STATE_HOME")
    if xdg and xdg ~= "" then
        return xdg .. "/muninn"
    end
    return vim.fn.expand("~/.local/state/muninn") --[[@as string]]
end

---@return string
function M.path()
    return state_dir() .. "/usage.jsonl"
end

local function ensure_dir()
    pcall(vim.fn.mkdir, state_dir(), "p")
end

---@param entry MnUsageLogEntry
function M.append(entry)
    ensure_dir()
    local ok, encoded = pcall(vim.json.encode, entry)
    if not ok then return end
    local f, err = io.open(M.path(), "a")
    if not f then
        require("muninn.util.log").default():log("ERROR", "usage_log open failed: " .. (err or "?"))
        return
    end
    f:write(encoded)
    f:write("\n")
    f:close()
end

---@return MnUsageLogEntry[]
function M.read_all()
    local records = {}
    local f = io.open(M.path(), "r")
    if not f then return records end
    for line in f:lines() do
        if line ~= "" then
            local ok, rec = pcall(vim.json.decode, line)
            if ok and rec then
                table.insert(records, rec)
            end
        end
    end
    f:close()
    return records
end

return M
