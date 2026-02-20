local animation = require("muninn.util.decor.animation")
local logger = require("muninn.util.log").default
local pbm = require("muninn.util.img.pbm")

return function()
    -- create_test_pbm()
    logger():log("INFO", "loading ~/test.pbm")
    local frame = pbm.read("~/test.pbm")
    if frame then
        logger():log("IMAGE", " \n" .. table.concat(frame:to_lines(), "\n"))
    end
end
