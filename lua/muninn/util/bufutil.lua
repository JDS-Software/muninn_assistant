local M = {}
local logger = require("muninn.util.log").default

---@param context MnContext
---@return table? beginning beginning of content before the context of interest
---@return table? middle content interest
---@return table? ending end of content after the context of interest
function M.scissor_function_reference(context)
    if not context then
        return nil, nil, nil
    end

    local begin = {}
    local middle = {}
    local ending = {}

    local line_end, _ = context.fn_context:get_end()
    line_end = line_end + 1

    local line_start, _ = context.fn_context:get_start()

    for i, line in ipairs(vim.api.nvim_buf_get_lines(context.fn_context.bufnr, 0, -1, false)) do
        if i < line_start then
            table.insert(begin, line)
        elseif i >= line_start and i <= line_end then
            table.insert(middle, line)
        else
            table.insert(ending, line)
        end
    end

    return begin, middle, ending
end

---@param context MnContext
local function get_context_range(context)
    if context.an_context.ext_mark_start and context.an_context.ext_mark_end then
        local sLoc = vim.api.nvim_buf_get_extmark_by_id(
            context.fn_context.bufnr,
            context.an_context.ext_namespace,
            context.an_context.ext_mark_start,
            {}
        )
        local eLoc = vim.api.nvim_buf_get_extmark_by_id(
            context.fn_context.bufnr,
            context.an_context.ext_namespace,
            context.an_context.ext_mark_end,
            {}
        )
        return sLoc[1], eLoc[1]
    else
        local sRow, _ = context.fn_context:get_start()
        local eRow, _ = context.fn_context:get_end()
        return sRow, eRow
    end
end

---@param context MnContext
---@param safe_result string
function M.insert_safe_result_at_function(context, safe_result)
    local start_row, end_row = get_context_range(context)

    local lines = vim.split(safe_result, "\n", { plain = true })
    logger():log("INFO", vim.inspect(lines))
    vim.api.nvim_buf_set_lines(context.fn_context.bufnr, start_row, end_row + 1, false, lines)
end

---@param ctx MnContext
---@return string
function M.get_buffer_content(ctx)
    local lines = vim.api.nvim_buf_get_lines(ctx.fn_context.bufnr, 0, -1, false)
    return table.concat(lines, "\n")
end

return M
