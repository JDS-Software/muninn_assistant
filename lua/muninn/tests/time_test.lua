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

-- time_test.lua
-- Tests for lua/muninn/util/time.lua

local M = {}
local time = require("muninn.util.time")

local function near(a, b)
    local res = math.abs(a - b) < 1e-9
    if not res then
        io.write(string.format("Wanted %f, got %f", a, b))
    end
    return res
end

local function test_new_time()
    -- number, number
    local t = time.new_time(5, 500000000)
    assert_equal(5, t.sec)
    assert_equal(500000000, t.nsec)

    -- number, nil
    t = time.new_time(3)
    assert_equal(3, t.sec)
    assert_equal(0, t.nsec)

    -- nil, number
    t = time.new_time(nil, 750000000)
    assert_equal(0, t.sec)
    assert_equal(750000000, t.nsec)

    -- nil, nil returns timestamp
    t = time.new_time()
    assert_true(t.sec >= 0)
    assert_not_nil(t.nsec)
end

local function test_diff()
    -- big minus little
    local d = time.new_time(10, 500000000):diff(time.new_time(3, 200000000))
    assert_equal(7, d.sec)
    assert_equal(300000000, d.nsec)

    -- little minus big
    d = time.new_time(5, 100000000):diff(time.new_time(3, 400000000))
    assert_equal(2, d.sec)
    assert_equal(-300000000, d.nsec)

    d = time.new_time(3, 100000000):diff(time.new_time(5, 400000000))
    assert_equal(-2, d.sec)
    assert_equal(-300000000, d.nsec)

    d = time.new_time(3, 400000000):diff(time.new_time(5, 100000000))
    assert_equal(-2, d.sec)
    assert_equal(300000000, d.nsec)

    --diff to millis
    assert_equal(6000, time.new_time(10, 0):diff(time.new_time(4, 0)):to_millis())
end

local function test_to_millis()
    assert_equal(0, time.new_time(0, 0):to_millis())
    assert_equal(3000, time.new_time(3, 0):to_millis())
    assert_equal(500, time.new_time(0, 500000000):to_millis())
    assert_equal(2750, time.new_time(2, 750000000):to_millis())

    --trunctation
    assert_equal(1, time.new_time(0, 1999999):to_millis())
end

local function test_oscillator()
    -- smooth cosine curve: (-cos(position * 2pi) + 1) / 2
    local osc = time.new_oscillator(time.new_time(20, 0)) -- full cycle is 20s
    for i = 1, 10, 1 do
        local t_x = time.new_time(i)
        local position = i / 20
        local expected = (-math.cos(position * 2 * math.pi) + 1) / 2
        local o_val = osc:at(t_x)
        assert_true(near(expected, o_val),
            string.format("checking [%f vs %f] time %s", expected, o_val, vim.json.encode(t_x)))
    end

    -- wrap behavior
    osc = time.new_oscillator(time.new_time(2, 0))
    assert_true(near(0.0, osc:at(time.new_time(2, 0))), "1mod")
    assert_true(near(0.0, osc:at(time.new_time(4, 0))), "2mod")

    -- oscilator range
    osc = time.new_oscillator(time.new_time(1, 0))
    for ms = 0, 999, 50 do
        local val = osc:at(time.new_time(0, ms * 1000000))
        assert_true(val >= -1e-9 and val <= 1.0 + 1e-9)
    end
end

function M.run()
    local runner = TestRunner.new("time")
    runner:test("new_time", test_new_time)
    runner:test("diff", test_diff)
    runner:test("to_millis", test_to_millis)
    runner:test("oscillator key points", test_oscillator)

    runner:run()
end

return M
