local M = {}
local bufutil = require("muninn.util.bufutil")

local prompt_template = [[Your task is to assist the user with a portion of their code.
You are provided with a request from the user and the entire content of a source code file.
The user's request is between >>> USER INPUT START <<< and >>> USER INPUT END <<<.
The file content is between >>> FILE CONTENT START <<< and >>> FILE CONTENT END <<<.
The 'content' portion of your response will replace the lines between <content> and </content>.

>>> USER INPUT START <<<
%s
>>> USER INPUT END <<<

>>> FILE CONTENT START <<<
%s

<content>
%s
</content>

%s
>>> FILE CONTENT END <<<

Make no mistakes. Make it secure.
]]

---@param context MnContext
---@param user_prompt string
---@return string
function M.build_prompt(context, user_prompt)
	local beginning, middle, ending = bufutil.scissor_function_reference(context)
	if beginning and middle and ending then
		return string.format(
			prompt_template,
			user_prompt,
			table.concat(beginning, "\n"),
			table.concat(middle, "\n"),
			table.concat(ending, "\n")
		)
	end
	return require("muninn.util.claude_refusal")
end

return M
