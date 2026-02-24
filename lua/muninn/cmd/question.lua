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

local context = require("muninn.util.context")
local prompt = require("muninn.util.prompt")
local claude = require("muninn.util.claude")
local input = require("muninn.components.prompt")
local logger = require("muninn.util.log").default
local animation = require("muninn.util.decor.animation")
local float = require("muninn.components.float")

---@param ctx MnContext
local function launch_error(ctx)
    return function()
        ctx:reset_state()
        animation.new_failure_animation():start(ctx)
        vim.defer_fn(function()
            ctx:next_state()
        end, 5000)
    end
end

---@param result ClaudeResult
local function launch_response_viewer(result)
    if not result or not result.structured_output or not result.structured_output.content then
        logger():alert("ERROR", "Failed to get response from Muninn")
        return
    end

    local lines = vim.split(result.structured_output.content, "\n", { plain = true })
    local win_opts = float.make_win_opts({
        width_ratio = 0.5,
        height_ratio = 0.33,
        title = "Muninn's Response",
        content_count = #lines,
        content_offset = 2,
    })
    win_opts.row = vim.o.lines - win_opts.height - 2
    win_opts.col = vim.o.columns - win_opts.width - 2

    local buf = float.create_buf("markdown")
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("modifiable", false, { buf = buf })

    local ok, win_handle = pcall(vim.api.nvim_open_win, buf, true, win_opts)
    if ok then
        local function close_win()
            if win_handle and vim.api.nvim_win_is_valid(win_handle) then
                vim.cmd("stopinsert")
                vim.api.nvim_win_close(win_handle, true)
            end
        end

        vim.api.nvim_set_option_value("wrap", true, { win = win_handle })
        vim.keymap.set("n", "<Esc>", close_win, { buffer = buf, nowait = true })
        vim.keymap.set("n", "q", close_win, { buffer = buf, nowait = true })
    end
end

return function()
    local ctx = context.get_context_at_cursor()

    if ctx then
        input.show("Ask a question.", function(question)
            if not question then
                return
            end

            local ask_prompt = prompt.build_query_prompt(ctx, question)

            logger():log("QUESTION_PROMPT", ask_prompt)
            local anim = animation.new_question_animation(ctx)
            anim:start(ctx)

            claude.execute_prompt(ask_prompt, function(result)
                if result and result.structured_output and result.structured_output.content then
                    launch_response_viewer(result)
                    ctx:next_state()
                else
                    logger():alert("ERROR", "Query failed:\nResult:\n" .. vim.inspect(result))
                    ctx.an_context.preserve_ext = true
                    ctx:next_state()
                    vim.defer_fn(launch_error(ctx), anim:get_wait())
                end
            end)
        end)
    end
end
