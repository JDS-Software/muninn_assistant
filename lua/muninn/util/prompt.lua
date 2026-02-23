local M = {}
local bufutil = require("muninn.util.bufutil")

local task_prompt_template = [[Your task is to assist the user with a portion of their code.
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

---@param ctx MnContext
---@param user_prompt string
---@return string
function M.build_task_prompt(ctx, user_prompt)
    local beginning, middle, ending = bufutil.scissor_function_reference(ctx)
    if beginning and middle and ending then
        return string.format(
            task_prompt_template,
            user_prompt,
            table.concat(beginning, "\n"),
            table.concat(middle, "\n"),
            table.concat(ending, "\n")
        )
    end
    return require("muninn.util.claude_refusal")
end

local query_prompt_template = [[Your task is to assist the user with a question they have regarding this project.
You are provided with a request from the user and the entire content of a source code file.
Your response will be shown to the user in an annotation.
The user's request is between >>> USER INPUT START <<< and >>> USER INPUT END <<<.
The file content is between >>> FILE CONTENT START <<< and >>> FILE CONTENT END <<<.

>>> USER INPUT START <<<
%s
>>> USER INPUT END <<<

>>> FILE CONTENT START <<<
%s
>>> FILE CONTENT END <<<
]]

function M.build_query_prompt(context, user_prompt)
    local file_content = bufutil.get_buffer_content(context)
    return string.format(query_prompt_template, user_prompt, file_content)
end

return M
