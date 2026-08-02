PROJECT = "air8000_vibration_gateway"
VERSION = "1.0.1"

local sys = require("sys")

--==================== 配置区 ====================

-- Air8000W UART11
-- 模组引脚：
-- PIN48 = UART11_RX
-- PIN49 = UART11_TX
local UART_ID = 11
local UART_BAUD = 115200

-- MQTT服务器
local MQTT_BROKER = "g79e1bb3.ala.cn-hangzhou.emqxsl.cn"
local MQTT_PORT = 8883

-- 必须根据EMQX控制台填写
local MQTT_USER = ""
local MQTT_PWD = ""

local PUB_UPLOAD_TOPIC = "device/vibration/upload"
local SUB_CMD_TOPIC = "device/vibration/cmd"

local REPORT_CSQ_INTERVAL = 50000

--================================================

local mqtt_client = nil
local net_ready = false
local mqtt_ready = false

local imei = mobile.imei() or "unknown"
local MQTT_CLIENT_ID = "vib_" .. imei

log.setLevel(log.DEBUG)
log.info("main", "main.lua start")
log.info("main", "client id", MQTT_CLIENT_ID)

--================================================
-- UART接收
--================================================

local function uart_recv_cb(id, len)
    -- len是缓冲区数据长度，不是数据本身
    if len == -1 then
        log.info("uart", "wakeup by uart")
        return
    end

    while true do
        local data = uart.read(id, 4096)

        if not data or #data == 0 then
            break
        end

        log.info(
            "uart",
            "rx",
            "len",
            #data,
            "hex",
            data:toHex()
        )

        if net_ready and mqtt_ready and mqtt_client then
            -- 建议振动数据使用QoS 1
            local msg_id = mqtt_client:publish(
                PUB_UPLOAD_TOPIC,
                data,
                1,
                0
            )

            if msg_id then
                log.info("mqtt", "publish queued", msg_id, #data)
            else
                log.warn("mqtt", "publish failed")
            end
        else
            log.warn("mqtt", "not ready, uart data dropped", #data)
        end
    end
end

--================================================
-- MQTT事件回调
--================================================

local function mqtt_event_cb(client, event, data, payload, metas)
    log.info("mqtt", "event", event)

    if event == "conack" then
        mqtt_ready = true

        log.info("mqtt", "connected and authenticated")

        local ret = client:subscribe(SUB_CMD_TOPIC, 0)
        log.info("mqtt", "subscribe", SUB_CMD_TOPIC, ret)

    elseif event == "recv" then
        local topic = data
        local message = payload or ""

        log.info(
            "mqtt",
            "recv",
            "topic",
            topic,
            "len",
            #message
        )

        if topic == SUB_CMD_TOPIC then
            local written = uart.write(UART_ID, message)

            log.info(
                "uart",
                "tx to dsp",
                written,
                #message
            )
        end

    elseif event == "sent" then
        log.info("mqtt", "publish confirmed", data)

    elseif event == "disconnect" then
        mqtt_ready = false
        log.warn("mqtt", "disconnected")
    end
end

--================================================
-- MQTT管理任务
--================================================

local function mqtt_task()
    while true do
        if not net_ready then
            log.info("mqtt", "waiting for IP_READY")
            sys.waitUntil("IP_READY", 3000)
        else
            if mqtt_client then
                mqtt_client:close()
                mqtt_client = nil
            end

            mqtt_ready = false

            log.info(
                "mqtt",
                "create",
                MQTT_BROKER,
                MQTT_PORT
            )

            -- 8883必须启用TLS
            -- true表示TLS加密，但暂不校验服务器CA证书
            mqtt_client = mqtt.create(
                nil,
                MQTT_BROKER,
                MQTT_PORT,
                true
            )

            if not mqtt_client then
                log.error("mqtt", "mqtt.create failed")
                sys.wait(5000)
            else
                mqtt_client:auth(
                    MQTT_CLIENT_ID,
                    MQTT_USER,
                    MQTT_PWD,
                    true
                )

                mqtt_client:keepalive(60)
                mqtt_client:on(mqtt_event_cb)

                -- 这里由程序自己管理重连
                mqtt_client:autoreconn(false)

                local ok = mqtt_client:connect()

                if not ok then
                    log.error("mqtt", "connect start failed")
                    mqtt_client:close()
                    mqtt_client = nil
                    sys.wait(5000)
                else
                    log.info("mqtt", "connect started")

                    -- 等待MQTT完成连接或掉线
                    while net_ready and mqtt_client do
                        if mqtt_client:ready() then
                            mqtt_ready = true
                        end

                        local state = mqtt_client:state()

                        -- 0一般表示断开
                        if state == mqtt.STATE_DISCONNECT then
                            log.warn("mqtt", "state disconnected")
                            break
                        end

                        sys.wait(500)
                    end

                    mqtt_ready = false

                    if mqtt_client then
                        mqtt_client:close()
                        mqtt_client = nil
                    end

                    log.info("mqtt", "reconnect after 3 seconds")
                    sys.wait(3000)
                end
            end
        end
    end
end

--================================================
-- 网络事件
--================================================

sys.subscribe("IP_READY", function(ip, adapter)
    net_ready = true
    log.info("network", "IP_READY", ip, adapter)
end)

sys.subscribe("IP_LOSE", function(adapter)
    net_ready = false
    mqtt_ready = false

    log.warn("network", "IP_LOSE", adapter)

    if mqtt_client then
        mqtt_client:close()
        mqtt_client = nil
    end
end)

--================================================
-- 状态打印
--================================================

sys.taskInit(function()
    while true do
        log.info(
            "status",
            "csq",
            mobile.csq(),
            "imei",
            mobile.imei(),
            "net",
            net_ready,
            "mqtt",
            mqtt_ready
        )

        sys.wait(REPORT_CSQ_INTERVAL)
    end
end)

--================================================
-- 初始化UART11
--================================================

sys.taskInit(function()
    local result = uart.setup(
        UART_ID,
        UART_BAUD,
        8,
        1,
        uart.None
    )

    if result ~= 0 then
        log.error(
            "uart",
            "setup failed",
            "id",
            UART_ID,
            "result",
            result
        )
        return
    end

    uart.on(UART_ID, "receive", uart_recv_cb)

    log.info(
        "uart",
        "init success",
        "id",
        UART_ID,
        "baud",
        UART_BAUD
    )

    -- 给DSP发送启动提示，可选
    uart.write(UART_ID, "AIR8000W_READY\r\n")
end)

sys.taskInit(mqtt_task)

sys.run()