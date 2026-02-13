local M = {}
local bufutil = require("muninn.util.bufutil")

local llm_placeholder = ">>> YOUR RESPONSE GOES HERE <<<"
local prompt_template = [[Your task is to assist the user with a portion of their code.
The user input is between >>> USER INPUT START <<< and >>> USER INPUT END <<<.
The file content is between >>> FILE CONTENT START <<< and >>> FILE CONTENT END <<<.
The specific context that the user needs assistance with is between >>> SCOPE CONTENT START <<< and >>> SCOPE CONTENT END <<<.
Your entire response will be inserted on the line containing %s.

>>> USER INPUT START <<<
%s
>>> USER INPUT END <<<

>>> FILE CONTENT START <<<
%s
>>> FILE CONTENT END <<<

>>> SCOPE CONTENT START <<<
%s
>>> SCOPE CONTENT END <<<

]]

---@param context MnContext
---@param user_prompt string
---@return string
function M.build_prompt(context, user_prompt)
	local nonscope, scope = bufutil.scissor_function_reference(context, llm_placeholder)
	if scope and nonscope then
		return string.format(
			prompt_template,
			llm_placeholder,
			user_prompt,
			table.concat(nonscope, "\n"),
			table.concat(scope, "\n")
		)
	end
	return ""
end

return M
