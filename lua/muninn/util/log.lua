local float = require("muninn.components.float")

local M = {}

---@alias LogLevel "INFO" | "WARN" | "ERROR"

---@class MnLogger
---@field buf_handle number? the buffer handle
---@field win_handle number? the window handle
---@field buffer table line buffer
local MnLogger = {}
MnLogger.__index = MnLogger

---@return MnLogger
M.default = function()
    return M.default_logger
end

---@return MnLogger
function M.new_logger()
    return setmetatable({ buf_handle = nil, win_handle = nil, buffer = {} }, MnLogger)
end

---@param str string the string to split
---@return table
local function split_newline(str)
    local lines = {}
    for line in (str .. "\n"):gmatch("([^\n]*)\n") do
        lines[#lines + 1] = line
    end
    return lines
end


---@param level LogLevel
---@param message string
function MnLogger:log(level, message)
    if not message or #message == 0 then return end
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

---@param level LogLevel
---@param message string
function MnLogger:alert(level, message)
    if not message or #message == 0 then return end

    local level_translate = { ERROR = vim.log.levels.ERROR, INFO = vim.log.levels.INFO, WARN = vim.log.levels.WARN }
    local notify_level = level_translate[level] or vim.log.levels.INFO
    vim.notify(message, notify_level, {})

    self:log(level, message)
end

---@param width_ratio number percentage of width
---@param height_ratio number percentage of height
function MnLogger:show(width_ratio, height_ratio)
    local buf = float.create_buf()
    self.buf_handle = buf

    local win_opts = float.make_win_opts({
        width_ratio = width_ratio,
        height_ratio = height_ratio,
        title = "Logs[MUNINN]",
    })
    win_opts.col = math.floor(vim.o.columns - win_opts.width)

    local ok, win_handle = pcall(vim.api.nvim_open_win, buf, true, win_opts)
    if not ok then
        self.buf_handle = nil
        return
    end
    self.win_handle = win_handle
    vim.api.nvim_buf_set_lines(self.buf_handle, 0, -1, false, self.buffer)

    local augroup_name = "MuninnLogWindow"
    local group = vim.api.nvim_create_augroup(augroup_name, { clear = true })

    float.on_win_closed(group, self.win_handle, augroup_name, function()
        self.buf_handle = nil
        self.win_handle = nil
    end)
end

--- initializes the module's default logger
function M.setup()
    M.default_logger = M.new_logger()
    M.default():log("INFO", "MnLogger initialized...")
end

return M
