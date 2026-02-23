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

-- pbm_test.lua
-- Tests for lua/muninn/util/img/pbm.lua

local M = {}

local pbm = require("muninn.util.img.pbm")
local render = require("muninn.util.decor.render")

local function write_file(path, content)
    local f = io.open(path, "w")
    if f then
        f:write(content)
        f:close()
    end
end

local function read_file(path)
    local f = io.open(path, "r")
    if f then
        local content = f:read("*a")
        f:close()
        return content
    end
end

local function test_write()
    -- stylua: ignore
    local bits = {
        1, 0, 0, 1,
        0, 1, 1, 0,
        0, 1, 1, 0,
        1, 0, 0, 1,
    }
    local frame = render.new_frame(4, 4, bits)
    local path = os.tmpname()

    local ok = pbm.write(frame, path)
    assert_true(ok, "write should return true")

    local content = read_file(path)
    local expected = "P1\n4 4\n1 0 0 1\n0 1 1 0\n0 1 1 0\n1 0 0 1\n"
    assert_equal(expected, content, "PBM output should match expected format")

    os.remove(path)
end

local function test_read()
    local path = os.tmpname()
    write_file(path, "P1\n4 4\n1 0 0 1\n0 1 1 0\n0 1 1 0\n1 0 0 1\n")

    local frame = pbm.read(path)
    assert_not_nil(frame, "read should return a frame")
    if frame then
        assert_equal(4, frame.width, "width should be 4")
        assert_equal(4, frame.height, "height should be 4")
        assert_equal(1, frame.bits[1], "first bit should be 1")
        assert_equal(0, frame.bits[2], "second bit should be 0")
        assert_equal(1, frame.bits[16], "last bit should be 1")
    end

    os.remove(path)
end

local function test_read_with_comments()
    local path = os.tmpname()
    write_file(path, "P1\n# this is a comment\n4 4\n# another comment\n1 0 0 1\n0 1 1 0\n0 1 1 0\n1 0 0 1\n")

    local frame = pbm.read(path)
    assert_not_nil(frame, "read should handle comments")
    if frame then
        assert_equal(4, frame.width)
        assert_equal(4, frame.height)
    end

    os.remove(path)
end

local function test_read_with_inline_comments()
    local path = os.tmpname()
    write_file(path, "P1\n4 4 # dimensions\n1 0 0 1 # row 1\n0 1 1 0\n0 1 1 0\n1 0 0 1\n")

    local frame = pbm.read(path)
    assert_not_nil(frame, "read should handle inline comments")
    if frame then
        assert_equal(4, frame.width)
        assert_equal(4, frame.height)
        assert_equal(1, frame.bits[1], "first bit should be 1")
        assert_equal(0, frame.bits[2], "second bit should be 0")
    end

    os.remove(path)
end

local function test_round_trip()
    -- stylua: ignore
    local bits = {
        0, 0, 1, 0, 1, 0, 0, 0,
        0, 1, 1, 0, 0, 1, 1, 0,
        1, 1, 0, 1, 0, 0, 1, 1,
        1, 0, 0, 1, 1, 0, 0, 1,
        1, 0, 0, 1, 1, 0, 0, 1,
        1, 1, 0, 1, 0, 0, 1, 1,
        0, 1, 1, 0, 0, 1, 1, 0,
        0, 0, 1, 0, 1, 0, 0, 0,
    }
    local original = render.new_frame(8, 8, bits)
    local path = os.tmpname()

    pbm.write(original, path)
    local restored = pbm.read(path)

    assert_not_nil(restored, "round trip should produce a frame")
    if restored then
        assert_equal(original.width, restored.width, "width should survive round trip")
        assert_equal(original.height, restored.height, "height should survive round trip")
        for i = 1, #original.bits do
            assert_equal(original.bits[i], restored.bits[i], "bit " .. i .. " should survive round trip")
        end
    end

    os.remove(path)
end

local function test_read_no_spaces()
    local path = os.tmpname()
    write_file(path, "P1\n4 4\n1001\n0110\n0110\n1001\n")

    local frame = pbm.read(path)
    assert_not_nil(frame, "read should handle no-space pixel data")
    if frame then
        assert_equal(4, frame.width)
        assert_equal(4, frame.height)
        assert_equal(1, frame.bits[1], "first bit should be 1")
        assert_equal(0, frame.bits[2], "second bit should be 0")
        assert_equal(0, frame.bits[3], "third bit should be 0")
        assert_equal(1, frame.bits[4], "fourth bit should be 1")
        assert_equal(1, frame.bits[16], "last bit should be 1")
    end

    os.remove(path)
end

local function test_read_errors()
    -- missing file
    local frame = pbm.read("/tmp/muninn_nonexistent_pbm_test_file.pbm")
    assert_nil(frame, "missing file should return nil")

    -- bad magic number
    local path = os.tmpname()
    write_file(path, "P2\n4 4\n0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0\n")
    frame = pbm.read(path)
    assert_nil(frame, "bad magic number should return nil")
    os.remove(path)

    -- non-multiple-of-4 dimensions
    path = os.tmpname()
    write_file(path, "P1\n3 3\n0 0 0 0 0 0 0 0 0\n")
    frame = pbm.read(path)
    assert_nil(frame, "non-multiple-of-4 dimensions should return nil")
    os.remove(path)

    -- wrong number of bits
    path = os.tmpname()
    write_file(path, "P1\n4 4\n0 0 0 0\n")
    frame = pbm.read(path)
    assert_nil(frame, "wrong bit count should return nil")
    os.remove(path)
end

function M.run()
    local runner = TestRunner.new("pbm")

    runner:test("write frame to PBM", test_write)
    runner:test("read PBM to frame", test_read)
    runner:test("read PBM with comments", test_read_with_comments)
    runner:test("read PBM with inline comments", test_read_with_inline_comments)
    runner:test("PBM round trip", test_round_trip)
    runner:test("read PBM with no spaces", test_read_no_spaces)
    runner:test("read PBM error cases", test_read_errors)

    runner:run()
end

return M
