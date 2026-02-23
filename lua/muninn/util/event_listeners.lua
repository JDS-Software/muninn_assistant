local M = {}
local viewer = require("muninn.util.decor.scope_viewer")

---@class NeovimAutocmdEventArgs
---@field id number
---@field event string
---@field group number?
---@field file string
---@field match string
---@field buf number
---@field data? table

local DEBOUNCE_MS = 150

local bufcache = {}

---@param bufnr integer
local function build_buffer_autocmds(bufnr)
    local timer = vim.uv.new_timer()

    ---@param args NeovimAutocmdEventArgs
    local cb = function(args)
        if timer then
            timer:stop()
            timer:start(DEBOUNCE_MS, 0, vim.schedule_wrap(function()
                viewer.on_moved_or_insert_leave(args)
            end))
        end
    end

    local autocmd_id = vim.api.nvim_create_autocmd({ "CursorMoved", "InsertLeave" }, { callback = cb, buffer = bufnr })
    return { autocmd_id = autocmd_id, timer = timer }
end

local function setup_on_bufenter()
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function(args)
            local bufnr = args.buf
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            if #bufname > 0 and not bufcache[bufnr] then
                bufcache[bufnr] = build_buffer_autocmds(bufnr)
            end
        end,
    })
end

local function setup_on_bufend()
    vim.api.nvim_create_autocmd("BufUnload", {
        callback = function(args)
            local bufnr = args.buf
            local bufname = vim.api.nvim_buf_get_name(bufnr)
            if #bufname > 0 then
                local entry = bufcache[bufnr]
                if entry then
                    entry.timer:stop()
                    if not entry.timer:is_closing() then
                        entry.timer:close()
                    end
                    vim.api.nvim_del_autocmd(entry.autocmd_id)
                    bufcache[bufnr] = nil
                    viewer.evict_cache(bufnr)
                end
            end
        end,
    })
end

function M.setup()
    setup_on_bufenter()
    setup_on_bufend()
end

return M
