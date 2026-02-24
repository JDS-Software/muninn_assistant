-- install_parsers.lua
-- Installs treesitter parsers for CI using nvim-treesitter's async :wait() API.
--
-- Usage: nvim --headless --cmd "set rtp+=/tmp/nvim-treesitter" -c "lua require('muninn.tests.install_parsers').install()"

local M = {}

local function println(s)
    io.write(s .. "\n")
    io.flush()
end

function M.install()
    local langs = { "go", "javascript", "typescript", "python" }
    local ok, result = require("nvim-treesitter").install(langs, { summary = true }):pwait(300000)

    if not ok or not result then
        println("install failed: " .. tostring(result))
        local log_ok, log = pcall(require, "nvim-treesitter.log")
        if log_ok then
            log.show()
        end
    end

    vim.cmd(ok and result and "quit" or "cquit 1")
end

return M
