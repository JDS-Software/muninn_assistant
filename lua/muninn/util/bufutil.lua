local M = {}
local logger = require("muninn.util.log").default

---@param context MnContext
---@param placeholder string? optional line to place as a "tombstone" for the scissored-out portion
---@return table? non-scope content with scope content scissored out
---@return table? scope content
function M.scissor_function_reference(context, placeholder)
    if not context then
        return nil, nil
    end

    if not placeholder then
        placeholder = ""
    end

    local ns_content = {}
    local s_content = {}
    local marker_placed = false

    local line_end, _ = context.fn_context:get_end()
    line_end = line_end + 1

    local line_start, _ = context.fn_context:get_start()

    for i, line in ipairs(vim.api.nvim_buf_get_lines(context.fn_context.bufnr, 0, -1, false)) do
        if line_end >= i and i > line_start then
            if not marker_placed and #placeholder > 0 then
                table.insert(ns_content, "")
                table.insert(ns_content, placeholder)
                table.insert(ns_content, "")
                marker_placed = true
            end
            table.insert(s_content, line)
        else
            table.insert(ns_content, line)
        end
    end

    return ns_content, s_content
end

---@param context MnContext
local function get_context_range(context)
    if context.an_context.ext_mark_start and context.an_context.ext_mark_end then
        local sLoc =
            vim.api.nvim_buf_get_extmark_by_id(context.fn_context.bufnr, context.an_context.ext_namespace,
                context.an_context.ext_mark_start, {})
        local eLoc = vim.api.nvim_buf_get_extmark_by_id(context.fn_context.bufnr, context.an_context.ext_namespace,
            context.an_context.ext_mark_end, {})
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

return M
