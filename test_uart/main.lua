PROJECT = "uart11_test"
VERSION = "1.0.0"

local sys = require("sys")

local UART_ID = 11
local BAUDRATE = 115200

uart.setup(
    UART_ID,
    BAUDRATE,
    8,
    1,
    uart.NONE
)

uart.on(UART_ID, "receive", function(id, len)
    local data = uart.read(id, len)
    if data and #data > 0 then
        log.info("UART11", "RX len", #data)
        log.info("UART11", "RX string", data)
        log.info("UART11", "RX hex", data:toHex())

        uart.write(UART_ID, "Air8000 received: ")
        uart.write(UART_ID, data)
    end
end)

sys.taskInit(function()
    sys.wait(1000)
    log.info("UART11", "start", "baud", BAUDRATE)

    while true do
        uart.write(UART_ID, "Hello from Air8000 UART11\r\n")
        sys.wait(3000)
    end
end)

sys.run()