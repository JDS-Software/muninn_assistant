local logger = require("muninn.util.log").default

return function()
	logger():log("INFO", "Test function")
end
