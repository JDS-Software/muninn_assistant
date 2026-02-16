local M = {}
local context = require("muninn.util.context")
local color = require("muninn.util.color")

M.ext_namespace = vim.api.nvim_create_namespace("muninn_scope_viewer")
M.hl_group = "scope_viewer_hl"

local cache = {} --[[@as table<string, MnScopeViewerCacheLine>]]


-- clears all marks in the cache
local function clear_marks()
    for key, line in pairs(cache) do
        line:clear()
        cache[key] = nil
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
    local cacheline = cache[name]
    if not cacheline then
        clear_marks()
        cacheline = new_cacheline(ctx)
        cache[name] = cacheline
        vim.api.nvim_set_hl(0, M.hl_group, { bg = tostring(color.get_theme_background():lerp(color.white, 0.03)) })
    end
end

return M
