local M = {}
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default

M.namespace = vim.api.nvim_create_namespace("muninn_annotation")
M.hl_group = "muninn_highlight"

---@param ctx MnContext
---@param animation MnAnimation
---@return function
local function create_animation_callback(ctx, animation)
    return function()
        if ctx.an_context.state == context.STATE_END then
            logger():log("INFO", "animation over")
            M.end_annotation(ctx)
            return
        end
        animation:frame()

        vim.api.nvim_set_hl(0, M.hl_group, animation:get_hl())
        local message = animation:message()

        local start_options = {
            id = ctx.an_context.ext_mark_start,
            virt_lines = {
                {
                    { message, M.hl_group },
                },
            },
            virt_text_pos = "inline",
            virt_lines_above = true,
        }
        local sPos =
            vim.api.nvim_buf_get_extmark_by_id(ctx.fn_context.bufnr, M.namespace, ctx.an_context.ext_mark_start, {})
        vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, sPos[1], sPos[2], start_options)

        local end_options = {
            id = ctx.an_context.ext_mark_end,
            virt_lines = {
                {
                    { message, M.hl_group },
                },
            },
            virt_text_pos = "eol",
        }
        local ePos =
            vim.api.nvim_buf_get_extmark_by_id(ctx.fn_context.bufnr, M.namespace, ctx.an_context.ext_mark_end, {})
        vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, ePos[1], ePos[2], end_options)
        vim.defer_fn(ctx.an_context.update_cb, animation:get_wait())
    end
end

---@param ctx MnContext
---@param animation MnAnimation
function M.start_annotation(ctx, animation)
    logger():log("INFO", "annotation initialization")
    vim.api.nvim_set_hl(0, M.hl_group, animation:get_hl())

    local options = {
        virt_lines = {
            {
                { animation:message(), M.hl_group },
            },
        },
        virt_lines_above = true,
    }

    if not ctx.an_context.ext_mark_start then
        local sRow, sCol = ctx.fn_context:get_start()
        local ext_mark_start = vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, sRow, sCol, options)
        ctx.an_context.ext_mark_start = ext_mark_start
    end

    if not ctx.an_context.ext_mark_end then
        options.virt_lines_above = false
        local eRow, eCol = ctx.fn_context:get_end()
        local ext_mark_end = vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, eRow, eCol, options)
        ctx.an_context.ext_mark_end = ext_mark_end
    end

    if not ctx.an_context.ext_namespace then
        ctx.an_context.ext_namespace = M.namespace
    end

    ctx.an_context.update_cb = create_animation_callback(ctx, animation)
    logger():log("INFO", "launching animation")
    ctx.an_context.update_cb()
end

---@param ctx MnContext
local function clear_highlights(ctx)
    -- Clear the highlighting by updating extmarks to remove virtual lines
    if ctx.an_context.ext_mark_start then
        local sPos = vim.api.nvim_buf_get_extmark_by_id(
            ctx.fn_context.bufnr,
            M.namespace,
            ctx.an_context.ext_mark_start,
            {}
        )
        vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, sPos[1], sPos[2], {
            id = ctx.an_context.ext_mark_start,
            virt_lines = {},
            virt_text = {},
        })
    end
    if ctx.an_context.ext_mark_end then
        local ePos = vim.api.nvim_buf_get_extmark_by_id(
            ctx.fn_context.bufnr,
            M.namespace,
            ctx.an_context.ext_mark_end,
            {}
        )
        vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, ePos[1], ePos[2], {
            id = ctx.an_context.ext_mark_end,
            virt_lines = {},
            virt_text = {},
        })
    end
end

---@param ctx MnContext
function M.end_annotation(ctx)
    if ctx.an_context.update_cb then
        ctx.an_context.update_cb = nil
    end

    if not ctx.an_context.preserve_ext then
        if ctx.an_context.ext_namespace then
            vim.api.nvim_buf_clear_namespace(ctx.fn_context.bufnr, ctx.an_context.ext_namespace, 0, -1)
        end
        ctx.an_context.ext_mark_start = nil
        ctx.an_context.ext_mark_end = nil
        ctx.an_context.ext_namespace = nil
    else
        clear_highlights(ctx)
    end
end

return M
