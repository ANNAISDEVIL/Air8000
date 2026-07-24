PROJECT = "air8000_ble_test"
VERSION = "1.0.0"

local sys = require("sys")

local TAG = "BLE_TEST"

local config = {
    device_name = "Air8000_BLE",
    service_uuid = "FA00",
    notify_char_uuid = "EA01",
    write_char_uuid = "EA02",
    read_char_uuid = "EA03",
}

local bluetooth_device
local ble_device
local adv_created = false
local connected = false
local notify_index = 0
local latest_rx = "no data"

local att_db = {
    string.fromHex(config.service_uuid),
    {
        string.fromHex(config.notify_char_uuid),
        ble.NOTIFY | ble.READ | ble.WRITE
    },
    {
        string.fromHex(config.write_char_uuid),
        ble.WRITE | ble.WRITE_CMD
    },
    {
        string.fromHex(config.read_char_uuid),
        ble.READ
    }
}

local function hex_or_text(data)
    if not data or #data == 0 then
        return ""
    end
    return data, data:toHex()
end

local function notify(value)
    if not connected or not ble_device then
        return false
    end

    local ok = ble_device:write_notify({
        uuid_service = string.fromHex(config.service_uuid),
        uuid_characteristic = string.fromHex(config.notify_char_uuid),
    }, value)

    log.info(TAG, "notify", ok, value)
    return ok
end

local function update_read_value()
    if not ble_device then
        return false
    end

    local value = "rx=" .. latest_rx .. ";tick=" .. tostring(os.time())
    local ok = ble_device:write_value({
        uuid_service = string.fromHex(config.service_uuid),
        uuid_characteristic = string.fromHex(config.read_char_uuid),
    }, value)

    log.info(TAG, "read value update", ok, value)
    return ok
end

local function start_adv()
    if not ble_device then
        return false
    end

    if not adv_created then
        local adv_data = {
            {ble.FLAGS, string.char(0x06)},
            {ble.COMPLETE_LOCAL_NAME, config.device_name},
        }
        if ble.COMPLETE_16BIT_SERVICE_UUIDS then
            table.insert(adv_data, {ble.COMPLETE_16BIT_SERVICE_UUIDS, string.fromHex(config.service_uuid)})
        end

        local ok = ble_device:adv_create({
            addr_mode = ble.PUBLIC,
            channel_map = ble.CHNLS_ALL,
            intv_min = 160,
            intv_max = 160,
            adv_data = adv_data
        })

        log.info(TAG, "adv_create", ok)
        if not ok then
            return false
        end
        adv_created = true
    end

    local ok = ble_device:adv_start()
    log.info(TAG, "adv_start", ok, config.device_name)
    return ok
end

local function ble_callback(dev, event, param)
    log.info(TAG, "event", event)

    if event == ble.EVENT_CONN then
        connected = true
        log.info(TAG, "connected", param and param.addr and param.addr:toHex() or "")
        update_read_value()
        notify("Air8000 connected")
    elseif event == ble.EVENT_DISCONN then
        connected = false
        log.info(TAG, "disconnected", param and param.reason or "")
        sys.timerStart(start_adv, 1000)
    elseif event == ble.EVENT_WRITE then
        local value = param and (param.value or param.data) or ""
        local text, hex = hex_or_text(value)
        latest_rx = text
        log.info(TAG, "write", text, hex)
        update_read_value()
        notify("echo:" .. text)
    elseif event == ble.EVENT_READ_VALUE then
        log.info(TAG, "read value", param and param.value or "")
    else
        log.info(TAG, "unhandled event", event)
    end
end

sys.taskInit(function()
    sys.wait(1000)
    log.info(TAG, "start", PROJECT, VERSION)
    log.info(TAG, "service", config.service_uuid, "notify", config.notify_char_uuid, "write", config.write_char_uuid, "read", config.read_char_uuid)

    if not bluetooth or not ble then
        log.error(TAG, "bluetooth/ble library missing, please burn Air8000 firmware with BLE support")
        return
    end

    bluetooth_device = bluetooth.init()
    if not bluetooth_device then
        log.error(TAG, "bluetooth init failed")
        return
    end

    ble_device = bluetooth_device:ble(ble_callback)
    if not ble_device then
        log.error(TAG, "ble create failed")
        return
    end

    local mac = ble.mac and ble.mac()
    log.info(TAG, "ble mac", mac and mac:toHex() or "unknown")

    local ok = ble_device:gatt_create(att_db)
    log.info(TAG, "gatt_create", ok)
    if not ok then
        return
    end

    update_read_value()
    start_adv()

    while true do
        sys.wait(5000)
        if connected then
            notify_index = notify_index + 1
            notify("Air8000 notify #" .. tostring(notify_index))
            update_read_value()
        else
            log.info(TAG, "advertising", config.device_name)
        end
    end
end)

sys.run()
