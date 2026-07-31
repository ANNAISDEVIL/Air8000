PROJECT = "air8000_vibration_gateway"
VERSION = "1.0.0"

-- 加载系统库
local sys = require("sys")
--==================== 【配置区，按需修改】====================
-- 串口配置：和DSP通信串口 Air8000W UART编号查阅硬件手册
local UART_ID = 11
local UART_BAUD = 115200

-- MQTT 服务器配置
local MQTT_BROKER = "g79e1bb3.ala.cn-hangzhou.emqxsl.cn"
local MQTT_PORT = 8883
local MQTT_CLIENT_ID = "vib_" .. mobile.imei()
local MQTT_USER = ""
local MQTT_PWD = ""

-- 主题定义
local PUB_UPLOAD_TOPIC  = "device/vibration/upload"  -- 振动数据上传
local SUB_CMD_TOPIC     = "device/vibration/cmd"     -- 云端下发控制指令

local REPORT_CSQ_INTERVAL = 50000  -- 信号强度上报周期ms
--==========================================================

-- 全局变量
local mqtt_client = nil
local net_ready = false

-- 日志等级
log.setLevel(log.DEBUG)
log.info("main.lua 启动")

--[[
    串口接收回调：接收DSP传来的振动数据
    协议约定：自定义二进制/JSON，根据你DSP端协议自行解析
]]
local function uart_recv_cb(id, data)
    if not data or #data == 0 then
        return
    end
    log.info("uart recv from dsp", data)

    -- 网络就绪 && MQTT在线，直接转发上传云端
    if net_ready and mqtt_client then
        local ret = mqtt_client:publish(PUB_UPLOAD_TOPIC, data, 0)
        if not ret then
            log.warn("mqtt publish fail, network abnormal")
        end
    end
end

--[[
    MQTT消息回调：云端下发指令 → 转发给DSP
]]
local function mqtt_message_cb(client, msg)
    log.info("mqtt recv cmd", msg.topic, msg.payload)
    -- 直接透传给DSP
    uart.write(UART_ID, msg.payload)
end

--[[
    MQTT 连接管理任务（自动重连闭环）
]]
local function mqtt_task()
    while true do
        -- 等待网络就绪
        if not net_ready then
            log.info("mqtt task wait network...")
            sys.wait(1000)
        else
            log.info("mqtt start connect", MQTT_BROKER, MQTT_PORT)
            -- 释放旧连接
            if mqtt_client then
                mqtt_client:close()
                mqtt_client = nil
            end

            -- 创建MQTT实例
            mqtt_client = mqtt.client(MQTT_CLIENT_ID, 60, MQTT_USER, MQTT_PWD)
            mqtt_client:on(mqtt_message_cb)

            local ok = mqtt_client:connect(MQTT_BROKER, MQTT_PORT)
            if ok then
                log.info("mqtt connect success")
                mqtt_client:subscribe(SUB_CMD_TOPIC, 0)

                -- 保持循环，连接断开自动跳出
                while mqtt_client:connected() do
                    sys.wait(500)
                end
                log.warn("mqtt connection lost")
            else
                log.warn("mqtt connect failed")
            end
        end

        sys.wait(3000) -- 重连冷却
    end
end

--[[
    网络事件回调：4G拨号成功/掉线
]]
sys.subscribe("IP_READY", function(ip, adapter)
    log.info("network IP_READY", ip, adapter)
    net_ready = true
end)

sys.subscribe("IP_LOSE", function(adapter)
    log.warn("network IP_LOSE", adapter)
    net_ready = false
    if mqtt_client then
        mqtt_client:close()
    end
end)

--[[
    定时上报信号CSQ、IMEI状态
]]
sys.taskInit(function()
    while true do
        local csq_val = mobile.csq()
        local imei_val = mobile.imei()
        log.info("status", "csq", csq_val, "imei", imei_val)

        -- 可选：定时把模组状态上传云端
        -- local status_json = string.format('{"imei":"%s","csq":%d}', imei_val, csq_val)
        -- if net_ready and mqtt_client then
        --     mqtt_client:publish("device/vibration/status", status_json, 0)
        -- end
        sys.wait(REPORT_CSQ_INTERVAL)
    end
end)

--[[
    初始化串口
]]
sys.taskInit(function()
    uart.setup(UART_ID, UART_BAUD, 8, 1, uart.NONE)
    uart.on(UART_ID, uart_recv_cb)
    log.info("uart init ok, id=" .. UART_ID)
end)

--[[
    启动MQTT任务
]]
sys.taskInit(mqtt_task)

-- 系统主循环，必须放在最后
sys.run()
