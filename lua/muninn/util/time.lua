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
    return (-math.cos(position * two_pi) + 1) / 2
end

return M
