local M = {}

---@alias LogLevel "INFO" | "WARN" | "ERROR"

---@class MnLogger
---@field bufnr number the buffer handle
---@field winnr number the window handle
---@field buffer table line buffer
local MnLogger = {}
MnLogger.__index = MnLogger

M.default = function() --[[@as fun(): MnLogger]]
    return M.default_logger
end

---@return MnLogger
function M.new_logger()
    return setmetatable({ bufnr = nil, winnr = nil, buffer = {} }, MnLogger)
end

---@param str string the string to split
---@return table
local function split_newline(str)
    local lines = {}
    for line in str:gmatch("[^\n]+") do
        lines[#lines + 1] = line
    end
    return lines
end

---@param level LogLevel
---@param message string
function MnLogger:log(level, message)
    local buff = split_newline(message)

    table.insert(self.buffer, level .. ": " .. buff[1])
    if #buff > 1 then
        for i, line in ipairs(buff) do
            if i > 1 then
                table.insert(self.buffer, "    " .. line)
            end
        end
    end
end

---@param width_ratio number percentage of width
---@param height_ratio number percentage of heigh
function MnLogger:show(width_ratio, height_ratio)
    local width = math.floor(vim.o.columns * width_ratio)
    local height = math.floor(vim.o.lines * height_ratio)

    local row = math.floor((vim.o.lines - height) / 2)
    local col = math.floor(vim.o.columns - width)

    local win_opts = {
        relative = "editor",
        width = width,
        height = height,
        row = row,
        col = col,
        border = "rounded",
        title = " Logs[MUNINN] ",
        title_pos = "center",
        style = "minimal",
    }

    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("bufhidden", "wipe", { buf = buf })
    vim.api.nvim_set_option_value("swapfile", false, { buf = buf })

    self.buf_handle = buf

    local ok, win_handle = pcall(vim.api.nvim_open_win, buf, true, win_opts)
    if not ok then
        self.buf_handle = nil
        return
    end
    self.win_handle = win_handle
    vim.api.nvim_buf_set_lines(self.buf_handle, 0, -1, false, self.buffer)

    local augroup_name = "MUNINN_LOG_WINDOW"
    local augroup = vim.api.nvim_create_augroup(augroup_name, {})

    vim.api.nvim_create_autocmd("WinClosed", {
        group = augroup,
        pattern = tostring(self.win_handle),
        once = true,
        callback = function()
            self.buf_handle = nil
            self.win_handle = nil
        end,
    })
end

--- initializes the module's default logger
function M.setup()
    M.default_logger = M.new_logger()
    M.default():log("INFO", "MnLogger initialized...")
end

return M
