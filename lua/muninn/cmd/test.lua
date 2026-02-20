local logger = require("muninn.util.log").default

return function()
    logger():log("INFO", "Test invoked with nothing to do")
end
