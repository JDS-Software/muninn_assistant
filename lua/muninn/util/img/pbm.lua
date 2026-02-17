local M = {}

local render = require("muninn.util.decor.render")

---@param path string
---@return string
local function normalize_path(path)
	return vim.fn.fnamemodify(vim.fn.expand(path), ":p")
end

---@param frame MnFrame
---@param path string
---@return boolean?
function M.write(frame, path)
	local f = io.open(normalize_path(path), "w")
	if not f then
		return nil
	end
	f:write("P1\n")
	f:write(string.format("%d %d\n", frame.width, frame.height))
	for row = 0, frame.height - 1 do
		local cells = {}
		for col = 1, frame.width do
			cells[col] = tostring(frame.bits[row * frame.width + col])
		end
		f:write(table.concat(cells, " ") .. "\n")
	end
	f:close()
	return true
end

---@param path string
---@return MnFrame?
function M.read(path)
	local f = io.open(normalize_path(path), "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()

	-- Strip comments: # through end of line (PBM spec allows inline comments)
	content = content:gsub("#[^\n]*", "")

	local tokens = {}
	for token in content:gmatch("%S+") do
		tokens[#tokens + 1] = token
	end

	if tokens[1] ~= "P1" then
		return nil
	end

	local width = tonumber(tokens[2])
	local height = tonumber(tokens[3])
	if not width or not height then
		return nil
	end

	local bits = {}
	for i = 4, #tokens do
		local v = tonumber(tokens[i])
		if not v then
			return nil
		end
		bits[#bits + 1] = v
	end

	local ok, frame = pcall(render.new_frame, bits, width, height)
	if not ok then
		return nil
	end
	return frame
end

return M
