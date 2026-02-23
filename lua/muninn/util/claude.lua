local M = {}

local command_template = {
    "claude",
    "-p",
    "--model",
    "sonnet",
    "--output-format",
    "json",
    "--json-schema",
    '{"type": "object", "properties": {"result": {"type": "string", "enum": ["success", "failure"]}, "content": {"type": "string"}}}',
}

---@class ClaudeUsage
---@field input_tokens integer
---@field cache_creation_input_tokens integer
---@field cache_read_input_tokens integer
---@field output_tokens integer
---@field server_tool_use ClaudeServerToolUse
---@field service_tier string
---@field cache_creation ClaudeCacheCreation
---@field inference_geo string
---@field iterations any[]

---@class ClaudeServerToolUse
---@field web_search_requests integer
---@field web_fetch_requests integer

---@class ClaudeCacheCreation
---@field ephemeral_1h_input_tokens integer
---@field ephemeral_5m_input_tokens integer

---@class ClaudeModelUsageEntry
---@field inputTokens integer
---@field outputTokens integer
---@field cacheReadInputTokens integer
---@field cacheCreationInputTokens integer
---@field webSearchRequests integer
---@field costUSD number
---@field contextWindow integer
---@field maxOutputTokens integer

---@class ClaudeStructuredOutput
---@field result string
---@field content string

---@class ClaudeResult
---@field type string
---@field subtype string
---@field is_error boolean
---@field duration_ms integer
---@field duration_api_ms integer
---@field num_turns integer
---@field result string
---@field stop_reason string?
---@field session_id string
---@field total_cost_usd number
---@field usage ClaudeUsage
---@field modelUsage table<string, ClaudeModelUsageEntry>
---@field permission_denials any[]
---@field structured_output ClaudeStructuredOutput
---@field uuid string

---@alias MuninnClaudeHandler fun(result: ClaudeResult?): nil

local logger = require("muninn.util.log").default

---@param system_result vim.SystemCompleted
---@param handler MuninnClaudeHandler
local function handle_output(system_result, handler)
    if system_result.code == 0 then
        local ok, result = pcall(vim.json.decode, system_result.stdout)
        result = result --[[@as ClaudeResult]]
        if ok and result then
            handler(result)
        else
            handler(nil)
        end
    else
        logger():alert("ERROR", "Claude CLI exited with code " .. system_result.code)
        if system_result.stderr and system_result.stderr ~= "" then
            logger():alert("ERROR", system_result.stderr)
        end
        handler(nil)
    end
end

---@param safe_prompt string command-line sanitized string that's safe to exist inside double quote cli params
---@param handler MuninnClaudeHandler
function M.execute_prompt(safe_prompt, handler)
    local command_table = vim.deepcopy(command_template)
    table.insert(command_table, safe_prompt)

    local cb = function(output)
        vim.schedule(function()
            handle_output(output, handler)
        end)
    end

    vim.system(command_table, { text = true }, cb)
end

return M
