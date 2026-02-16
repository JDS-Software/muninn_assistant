local M = {}

local context = require("muninn.util.context")

function M.make_buffer(lines, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = filetype
    local ok, parser = pcall(vim.treesitter.get_parser, buf, filetype)
    if not ok or not parser then
        return nil
    end
    parser:parse(true)
    return buf
end

function M.load_fixture(path, filetype)
    local lines = vim.fn.readfile(path)
    local buf = M.make_buffer(lines, filetype)
    if not buf then
        return nil
    end
    return context.get_contexts_for_buffer(buf)
end

return M
