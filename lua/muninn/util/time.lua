local M = {}

---@class MnTime
---@field sec number seconds
---@field nsec number nanoseconds
local MnTime = {}
MnTime.__index = MnTime

---@param sec number? seconds
---@param nsec number? nanoseconds
---@return MnTime
function M.new_time(sec, nsec)
	if not sec and not nsec then
		return setmetatable(vim.uv.clock_gettime("monotonic"), MnTime)
	end
	local s = sec or 0
	local ns = nsec or 0
	return setmetatable({ sec = s, nsec = ns }, MnTime)
end

---@param time MnTime the subtractor time
---@return MnTime diff self - time
function MnTime:diff(time)
	return M.new_time(self.sec - time.sec, self.nsec - time.nsec)
end

---@return number milliseconds
function MnTime:to_millis()
	local millis = math.floor(self.nsec / 1000000)
	return math.floor(self.sec * 1000) + millis
end

---@class MnOscillator
---@field duration MnTime duration of entire oscillation from 0 to 1 to 0
local MnOscillator = {}
MnOscillator.__index = MnOscillator

---@param duration MnTime duration in seconds and nanoseconds
---@return MnOscillator
function M.new_oscillator(duration)
	return setmetatable({ duration = duration }, MnOscillator)
end

---@param time MnTime the time, starting at time = 0, at which to compute the oscillation.
---@return number value 0 to 1
function MnOscillator:at(time)
	local time_millis = time:to_millis()
	local duration_millis = self.duration:to_millis()
	local position = (time_millis % duration_millis) / duration_millis
	local two_pi = 2 * math.pi
	return (math.cos(position * two_pi) + 1) / 2
end

return M
