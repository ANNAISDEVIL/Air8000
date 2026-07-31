PROJECT = "minimal_test"
VERSION = "1.0.0"


-- Minimal test main.lua for startup verification
local sys = require("sys")

-- Set verbose log level so we can see the startup marker
sys.taskInit(function()
    while true do
        log.info("test_main.lua", "Hello from Air8000 minimal test!")
        sys.wait(5000)
    end
end)

-- Keep the system running
sys.run()
