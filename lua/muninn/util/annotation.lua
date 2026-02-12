local M = {}
local context = require("muninn.util.context")
local logger = require("muninn.util.log").default

M.namespace = vim.api.nvim_create_namespace("muninn_annotation")
M.hl_group = "muninn_highlight"
M.highlight = { fg = "#000000", bg = "#908080" }
M.animation = "|/-\\"
M.banner = " Working "
M.wait_dur = 1000 / 10

---@param ctx MnContext
---@return function
local function create_animation_callback(ctx)
    return function()
        if ctx.an_context.state == context.STATE_END then
            logger():log("INFO", "animation over")
            M.end_annotation(ctx)
            return
        end

        local anim_idx = (ctx.an_context.anim_state % #M.animation) + 1
        local anim_char = M.animation:sub(anim_idx, anim_idx)
        local message = anim_char .. M.banner .. anim_char

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
        local sPos = vim.api.nvim_buf_get_extmark_by_id(ctx.fn_context.bufnr, M.namespace,
            ctx.an_context.ext_mark_start, {})
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
        local ePos = vim.api.nvim_buf_get_extmark_by_id(ctx.fn_context.bufnr, M.namespace,
            ctx.an_context.ext_mark_end, {})
        vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, ePos[1], ePos[2], end_options)
        ctx.an_context.anim_state = ctx.an_context.anim_state + 1
        vim.defer_fn(ctx.an_context.update_cb, M.wait_dur)
    end
end

---@param ctx MnContext
function M.start_annotation(ctx)
    logger():log("INFO", "annotation initialization")
    vim.api.nvim_set_hl(0, M.hl_group, M.highlight)

    local options = {
        virt_lines = {
            {
                { "\\ " .. M.banner .. "  \\", M.hl_group },
            },
        },
        virt_lines_above = true,
    }

    local sRow, sCol = ctx.fn_context:get_start()
    local ext_mark_start = vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, sRow, sCol, options)
    ctx.an_context.ext_mark_start = ext_mark_start

    options.virt_lines_above = false
    local eRow, eCol = ctx.fn_context:get_end()
    local ext_mark_end = vim.api.nvim_buf_set_extmark(ctx.fn_context.bufnr, M.namespace, eRow, eCol, options)
    ctx.an_context.ext_mark_end = ext_mark_end
    ctx.an_context.ext_namespace = M.namespace
    ctx.an_context.update_cb = create_animation_callback(ctx)
    logger():log("INFO", "launching animation")
    ctx.an_context.update_cb()
end

---@param ctx MnContext
function M.end_annotation(ctx)
    if ctx.an_context.ext_mark_start and ctx.an_context.ext_mark_end then
        vim.api.nvim_buf_clear_namespace(ctx.fn_context.bufnr, ctx.an_context.ext_namespace, 0, -1)
        ctx.an_context.ext_mark_start = nil
        ctx.an_context.ext_mark_end = nil
        ctx.an_context.anim_state = 0
    end
end

return M
