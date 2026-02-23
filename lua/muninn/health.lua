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

local function check_neovim_version()
    local v = vim.version()
    if v.major > 0 or (v.major == 0 and v.minor >= 10) then
        vim.health.ok("Neovim " .. v.major .. "." .. v.minor .. "." .. v.patch)
    else
        vim.health.error("Neovim 0.10+ required, found " .. v.major .. "." .. v.minor .. "." .. v.patch)
    end
end

local function check_claude_cli()
    if vim.fn.executable("claude") == 1 then
        vim.health.ok("claude CLI found")
    else
        vim.health.error("claude CLI not found in $PATH", { "Install Claude Code: https://docs.anthropic.com/en/docs/claude-code" })
    end
end

local function check_treesitter()
    if vim.treesitter then
        vim.health.ok("treesitter available")
    else
        vim.health.error("treesitter not available")
    end
end

function M.check()
    vim.health.start("muninn")
    check_neovim_version()
    check_claude_cli()
    check_treesitter()
end

return M
