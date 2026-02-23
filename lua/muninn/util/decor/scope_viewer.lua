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
local context = require("muninn.util.context")
local color = require("muninn.util.color")

M.ext_namespace = vim.api.nvim_create_namespace("muninn_scope_viewer")
M.hl_group = "scope_viewer_hl"

local caches = {} --[[@as table<integer, table<string, MnScopeViewerCacheLine>>]]

-- clears all marks in the cache
local function clear_marks()
    for bufnr, cache in pairs(caches) do
        for _, line in pairs(cache) do
            line:clear()
        end
        caches[bufnr] = nil
    end
end

---@param bufnr number
function M.evict_cache(bufnr)
    if caches[bufnr] then
        caches[bufnr] = nil
    end
end

---@class MnScopeViewerCacheLine
---@field ctx MnContext
---@field ext_mark_id number
local MnScopeViewerCacheLine = {}
MnScopeViewerCacheLine.__index = MnScopeViewerCacheLine

function MnScopeViewerCacheLine:clear()
    vim.api.nvim_buf_del_extmark(self.ctx:get_bufnr(), M.ext_namespace, self.ext_mark_id)
end

function MnScopeViewerCacheLine:_create_ext_mark()
    local sRow, sCol = self.ctx.fn_context:get_start()
    local eRow, eCol = self.ctx.fn_context:get_end()
    local opts = { end_row = eRow, end_col = eCol, hl_group = M.hl_group, hl_eol = true }
    self.ext_mark_id = vim.api.nvim_buf_set_extmark(self.ctx:get_bufnr(), M.ext_namespace, sRow, sCol, opts)
end

---@return MnScopeViewerCacheLine
local function new_cacheline(ctx)
    --NOTE: We leave stale state here... Not necessarily an act of evil, but we should watch this
    local self = setmetatable({ ctx = ctx }, MnScopeViewerCacheLine)
    self:_create_ext_mark()
    return self
end

---@param args NeovimAutocmdEventArgs
function M.on_moved_or_insert_leave(args)
    local ctx = context.get_context_at_cursor(args.buf)
    if not ctx then
        clear_marks()
        return
    end

    local name = ctx:get_name()
    local bufnr = ctx:get_bufnr()

    local cache = caches[bufnr]
    if not cache then
        cache = {}
    end

    local cacheline = cache[name]
    if not cacheline then
        clear_marks()
        cacheline = new_cacheline(ctx)

        cache[name] = cacheline
        caches[bufnr] = cache
        vim.api.nvim_set_hl(0, M.hl_group, { bg = tostring(color.get_theme_background():lerp(color.white, 0.03)) })
    end
end

return M
