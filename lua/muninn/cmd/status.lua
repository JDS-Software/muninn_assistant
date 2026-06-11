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

local float = require("muninn.components.float")
local cost = require("muninn.util.cost")
local usage_log = require("muninn.util.usage_log")

local AUGROUP_NAME = "MuninnStatusViewer"

return function()
    local session = cost.default()
    local records = usage_log.read_all()

    local today = os.date("%Y-%m-%d")
    local today_tracker = cost.tracker_from_records(records, function(r)
        return r.ts and os.date("%Y-%m-%d", r.ts) == today
    end)
    local lifetime_tracker = cost.tracker_from_records(records)

    local lines = {}
    local function append_block(t, title)
        for _, l in ipairs(t:summary_lines(title)) do
            table.insert(lines, l)
        end
    end

    append_block(session, "Session")
    table.insert(lines, "")
    append_block(today_tracker, "Today")
    table.insert(lines, "")
    append_block(lifetime_tracker, "Lifetime")

    local max_width = 0
    for _, l in ipairs(lines) do
        if #l > max_width then max_width = #l end
    end

    local desired_width = math.max(max_width + 4, 40)
    local width_ratio = math.min(desired_width / vim.o.columns, 0.5)

    local win_opts = float.make_win_opts({
        width_ratio = width_ratio,
        height_ratio = 0.6,
        title = "Muninn Status",
        content_count = #lines,
        content_offset = 2,
    })

    local buf = float.create_buf()
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
    vim.api.nvim_set_option_value("modified", false, { buf = buf })

    local ok, win_handle = pcall(vim.api.nvim_open_win, buf, true, win_opts)
    if not ok then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
        return
    end

    local function close_win()
        if win_handle and vim.api.nvim_win_is_valid(win_handle) then
            vim.api.nvim_win_close(win_handle, true)
        end
    end

    vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
    vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })

    local group = vim.api.nvim_create_augroup(AUGROUP_NAME, { clear = true })
    float.on_win_closed(group, win_handle, AUGROUP_NAME, function() end)
end
