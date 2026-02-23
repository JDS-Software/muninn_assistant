-- Copyright (c) 2026-present JDS Consulting, PLLC.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is furnished
-- to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

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

local query_prompt_template_with_focus =
[[Your task is to assist the user with a question they have regarding this project.
You are provided with a request from the user and the entire content of a source code file.
Your response will be shown to the user in an annotation.
The user's request is between `>>> USER INPUT START <<<` and `>>> USER INPUT END <<<`.
The file content is between `>>> FILE CONTENT START <<<` and `>>> FILE CONTENT END <<<`.
The user is specifically looking at the content between `>>> BEGIN USER FOCUS >>>` and `<<< END USER FOCUS <<<`.

>>> USER INPUT START <<<
%s
>>> USER INPUT END <<<

>>> FILE CONTENT START <<<
%s

>>> BEGIN USER FOCUS >>>
%s
<<< END USER FOCUS <<<
%s
>>> FILE CONTENT END <<<
]]

local query_prompt_template_no_focus =
[[Your task is to assist the user with a question they have regarding this project.
You are provided with a request from the user and the entire content of a source code file.
Your response will be shown to the user in an annotation.
The user's request is between `>>> USER INPUT START <<<` and `>>> USER INPUT END <<<`.
The file content is between `>>> FILE CONTENT START <<<` and `>>> FILE CONTENT END <<<`.

>>> USER INPUT START <<<
%s
>>> USER INPUT END <<<

>>> FILE CONTENT START <<<
%s
>>> FILE CONTENT END <<<
]]

---@param ctx MnContext
---@param user_prompt string
---@return string
function M.build_query_prompt(ctx, user_prompt)
    local beginning, middle, ending = bufutil.scissor_function_reference(ctx)
    if beginning and middle and ending then
        return string.format(
            query_prompt_template_with_focus,
            user_prompt,
            table.concat(beginning, "\n"),
            table.concat(middle, "\n"),
            table.concat(ending, "\n")
        )
    else
        local file_content = bufutil.get_buffer_content(ctx)
        return string.format(
            query_prompt_template_no_focus,
            user_prompt,
            file_content)
    end
end

return M
