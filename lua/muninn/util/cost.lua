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

---@class MnModelStats
---@field calls integer
---@field cost_usd number
---@field input_tokens integer
---@field output_tokens integer
---@field cache_read_input_tokens integer
---@field cache_creation_input_tokens integer

---@class MnCostTracker
---@field call_count integer
---@field error_count integer
---@field total_cost_usd number
---@field input_tokens integer
---@field output_tokens integer
---@field cache_read_input_tokens integer
---@field cache_creation_input_tokens integer
---@field duration_api_ms integer
---@field first_call_at integer?
---@field last_call_at integer?
---@field models table<string, MnModelStats>
local MnCostTracker = {}
MnCostTracker.__index = MnCostTracker

---@return MnCostTracker
function M.new_tracker()
    return setmetatable({
        call_count = 0,
        error_count = 0,
        total_cost_usd = 0,
        input_tokens = 0,
        output_tokens = 0,
        cache_read_input_tokens = 0,
        cache_creation_input_tokens = 0,
        duration_api_ms = 0,
        first_call_at = nil,
        last_call_at = nil,
        models = {},
    }, MnCostTracker)
end

---@return MnCostTracker
M.default = function()
    return M.default_tracker
end

---@param name string
---@return MnModelStats
function MnCostTracker:_model(name)
    local entry = self.models[name]
    if not entry then
        entry = {
            calls = 0,
            cost_usd = 0,
            input_tokens = 0,
            output_tokens = 0,
            cache_read_input_tokens = 0,
            cache_creation_input_tokens = 0,
        }
        self.models[name] = entry
    end
    return entry
end

---@param result ClaudeResult?
function MnCostTracker:record(result)
    if not result then
        self.error_count = self.error_count + 1
        return
    end

    local now = os.time()
    local usage = result.usage

    ---@type MnUsageLogEntry
    local entry = {
        ts = now,
        cost_usd = result.total_cost_usd or 0,
        duration_api_ms = result.duration_api_ms or 0,
        input_tokens = (usage and usage.input_tokens) or 0,
        output_tokens = (usage and usage.output_tokens) or 0,
        cache_read_input_tokens = (usage and usage.cache_read_input_tokens) or 0,
        cache_creation_input_tokens = (usage and usage.cache_creation_input_tokens) or 0,
    }

    if result.modelUsage then
        entry.models = {}
        for model_name, mu in pairs(result.modelUsage) do
            entry.models[model_name] = {
                calls = 1,
                cost_usd = mu.costUSD or 0,
                input_tokens = mu.inputTokens or 0,
                output_tokens = mu.outputTokens or 0,
                cache_read_input_tokens = mu.cacheReadInputTokens or 0,
                cache_creation_input_tokens = mu.cacheCreationInputTokens or 0,
            }
        end
    end

    self:record_log_entry(entry)
    require("muninn.util.usage_log").append(entry)
end

---@param entry MnUsageLogEntry
function MnCostTracker:record_log_entry(entry)
    self.call_count = self.call_count + 1
    self.total_cost_usd = self.total_cost_usd + (entry.cost_usd or 0)
    self.duration_api_ms = self.duration_api_ms + (entry.duration_api_ms or 0)

    if entry.ts then
        if not self.first_call_at or entry.ts < self.first_call_at then
            self.first_call_at = entry.ts
        end
        if not self.last_call_at or entry.ts > self.last_call_at then
            self.last_call_at = entry.ts
        end
    end

    self.input_tokens = self.input_tokens + (entry.input_tokens or 0)
    self.output_tokens = self.output_tokens + (entry.output_tokens or 0)
    self.cache_read_input_tokens = self.cache_read_input_tokens + (entry.cache_read_input_tokens or 0)
    self.cache_creation_input_tokens = self.cache_creation_input_tokens + (entry.cache_creation_input_tokens or 0)

    if entry.models then
        for model_name, m in pairs(entry.models) do
            local stats = self:_model(model_name)
            stats.calls = stats.calls + (m.calls or 0)
            stats.cost_usd = stats.cost_usd + (m.cost_usd or 0)
            stats.input_tokens = stats.input_tokens + (m.input_tokens or 0)
            stats.output_tokens = stats.output_tokens + (m.output_tokens or 0)
            stats.cache_read_input_tokens = stats.cache_read_input_tokens + (m.cache_read_input_tokens or 0)
            stats.cache_creation_input_tokens = stats.cache_creation_input_tokens + (m.cache_creation_input_tokens or 0)
        end
    end
end

---@param records MnUsageLogEntry[]
---@param filter? fun(rec: MnUsageLogEntry): boolean
---@return MnCostTracker
function M.tracker_from_records(records, filter)
    local t = M.new_tracker()
    for _, rec in ipairs(records) do
        if not filter or filter(rec) then
            t:record_log_entry(rec)
        end
    end
    return t
end

---@param n number
---@return string
local function fmt_int(n)
    local s = tostring(math.floor(n + 0.5))
    local out, count = s, 0
    while true do
        out, count = out:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
        if count == 0 then break end
    end
    return out
end

---@param usd number
---@return string
local function fmt_usd(usd)
    return string.format("$%.4f", usd)
end

---@param ms integer
---@return string
local function fmt_duration(ms)
    if ms < 1000 then
        return string.format("%dms", ms)
    end
    return string.format("%.1fs", ms / 1000)
end

---@param ts integer?
---@return string
local function fmt_time(ts)
    if not ts then return "—" end
    local today = os.date("%Y-%m-%d")
    local date = os.date("%Y-%m-%d", ts)
    if date == today then
        return os.date("%H:%M:%S", ts) --[[@as string]]
    end
    return os.date("%Y-%m-%d %H:%M:%S", ts) --[[@as string]]
end

---@param title string?
---@return string[]
function MnCostTracker:summary_lines(title)
    local lines = {}
    table.insert(lines, title or "Session Usage")
    table.insert(lines, "─────────────────────────────────")
    table.insert(lines, string.format("  Calls:          %s", fmt_int(self.call_count)))
    if self.error_count > 0 then
        table.insert(lines, string.format("  Errors:         %s", fmt_int(self.error_count)))
    end
    table.insert(lines, string.format("  Total cost:     %s USD", fmt_usd(self.total_cost_usd)))
    table.insert(lines, "")
    table.insert(lines, "Tokens")
    table.insert(lines, "─────────────────────────────────")
    table.insert(lines, string.format("  Input:          %s", fmt_int(self.input_tokens)))
    table.insert(lines, string.format("  Output:         %s", fmt_int(self.output_tokens)))
    table.insert(lines, string.format("  Cache read:     %s", fmt_int(self.cache_read_input_tokens)))
    table.insert(lines, string.format("  Cache writes:   %s", fmt_int(self.cache_creation_input_tokens)))
    table.insert(lines, "")
    table.insert(lines, "Timing")
    table.insert(lines, "─────────────────────────────────")
    local avg_ms = self.call_count > 0 and (self.duration_api_ms / self.call_count) or 0
    table.insert(lines, string.format("  API total:      %s", fmt_duration(self.duration_api_ms)))
    table.insert(lines, string.format("  API avg/call:   %s", fmt_duration(math.floor(avg_ms))))
    table.insert(lines, string.format("  First call:     %s", fmt_time(self.first_call_at)))
    table.insert(lines, string.format("  Last call:      %s", fmt_time(self.last_call_at)))

    local model_names = {}
    for name in pairs(self.models) do
        table.insert(model_names, name)
    end
    if #model_names > 0 then
        table.sort(model_names)
        table.insert(lines, "")
        table.insert(lines, "Models")
        table.insert(lines, "─────────────────────────────────")
        for _, name in ipairs(model_names) do
            local s = self.models[name]
            table.insert(lines, string.format("  %s", name))
            table.insert(lines, string.format("    %s · %s calls · in=%s out=%s",
                fmt_usd(s.cost_usd), fmt_int(s.calls), fmt_int(s.input_tokens), fmt_int(s.output_tokens)))
        end
    end

    return lines
end

function M.setup()
    M.default_tracker = M.new_tracker()
end

return M
