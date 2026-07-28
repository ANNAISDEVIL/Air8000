PROJECT = "tcp_demo"
VERSION = "1.0.0"

local sys = require("sys")
require("sysplus")

-- local socket = require("socket")
local libnet = require("libnet")

-------------------------------------------------
-- 修改这里
-------------------------------------------------
local SERVER_ADDR = "223.112.116.189"
local SERVER_PORT = 9000
-------------------------------------------------

local TASK_NAME = "TCP_TASK"

local function tcp_task()

    while true do

        -- 等待网络
        while not socket.adapter(socket.dft()) do
            log.info("NET", "Waiting IP_READY...")
            sys.waitUntil("IP_READY", 1000)
        end

        log.info("NET", "IP READY")

        -------------------------------------------------
        -- 创建 Socket
        -------------------------------------------------
        local netc = socket.create(nil, TASK_NAME)

        if not netc then
            log.error("TCP", "socket.create failed")
            sys.wait(3000)
            goto CONTINUE
        end

        -------------------------------------------------
        -- 配置 TCP Client
        -------------------------------------------------
        if not socket.config(netc) then
            log.error("TCP", "socket.config failed")
            socket.release(netc)
            sys.wait(3000)
            goto CONTINUE
        end

        -------------------------------------------------
        -- 连接服务器
        -------------------------------------------------
        log.info("TCP", "Connecting...")

        if not libnet.connect(
            TASK_NAME,
            15000,
            netc,
            SERVER_ADDR,
            SERVER_PORT
        ) then

            log.error("TCP", "Connect Failed")

            socket.release(netc)

            sys.wait(5000)

            goto CONTINUE
        end

        log.info("TCP", "Connected")

        -------------------------------------------------
        -- 每5秒发送一次
        -------------------------------------------------
        while true do

            local msg = "Hello Server\r\n"

            local ok = libnet.tx(
                TASK_NAME,
                5000,
                netc,
                msg
            )

            if not ok then
                log.error("TCP", "Send Failed")
                break
            end

            log.info("TCP", "TX:", msg)

            local result = libnet.wait(
                TASK_NAME,
                5000,
                netc
            )

            if not result then
                log.warn("TCP", "Disconnected")
                break
            end

        end

        -------------------------------------------------
        -- 清理
        -------------------------------------------------
        libnet.close(
            TASK_NAME,
            5000,
            netc
        )

        socket.release(netc)

        log.info("TCP", "Reconnect after 5s")

        sys.wait(5000)

        ::CONTINUE::

    end
end

sys.taskInitEx(
    tcp_task,
    TASK_NAME
)

sys.run()