# Air8000 BLE Peripheral Test

这个项目用于快速测试 Air8000 模块的 BLE 外围设备功能。

## 功能

- 广播设备名：`Air8000_BLE`
- Service UUID：`FA00`
- Notify 特征：`EA01`
- Write 特征：`EA02`
- Read 特征：`EA03`
- 手机写入 `EA02` 后，模块会通过 `EA01` notify 回显 `echo:<内容>`
- 连接后每 5 秒通过 `EA01` 发送一次心跳 notify
- `EA03` 可读，内容会记录最近一次收到的数据

## BLE 特性说明

- 本示例的自定义服务 UUID 是 `FA00`，手机调试工具通常会把它显示为 `Unknown Service`。
- `Generic Access` 和 `Generic Attribute` 是 BLE 标准服务，通常只显示设备信息和 GATT 元数据，不用于本 demo 的业务数据读写。
- `EA01` 主要用作通知（Notify）特征，订阅后可以接收回显 `echo:...` 和每 5 秒的心跳消息。
- `EA02` 是写特征，支持两种写入模式：
  - `write default`：带响应写（Write with Response）
  - `write no response`：无响应写（Write without Response）
  代码同时启用了 `WRITE` 和 `WRITE_CMD`，因此手机端两个选项都可以用，都会触发回显逻辑。
- `EA03` 是可读特征，可读取到最近一次写入的数据和当前时间戳。
- `EA01` 仅作为通知（Notify）通道；如果需要写入数据，请使用 `EA02`，如果需要读取最近接收的数据，请使用 `EA03`。

## 烧录

使用 Luatools 烧录 `main.lua`，并勾选“添加默认 lib”。Air8000 的 BLE 功能依赖 WiFi 协处理器，如果扫描不到设备或连接异常，请确认所用固件/底层无线固件已包含并启用了 BLE 功能并升级到支持 BLE 的固件版本。

## 手机验证

1. 打开 nRF Connect、LightBlue 等 BLE 调试工具。
2. 扫描 `Air8000_BLE` 并连接。
3. 找到服务 `FA00`。
4. 对 `EA01` 开启 Notify。
5. 向 `EA02` 写入文本，例如 `hello`。
6. 预期现象：
   - 串口日志打印收到的数据和 hex。
   - `EA01` 收到 `echo:hello`。
   - `EA01` 每 5 秒收到一次 `Air8000 notify #N`。
   - 读取 `EA03` 可看到最近一次收到的数据。

## 推荐的 BLE 调试助手app

使用建议：
- 在测试时请确认已对 EA01 打开 Notify（订阅），否则无法接收设备主动发出的通知。
- 写入时可在 app 中选择带响应（Write with Response）或无响应（Write without Response）；本 demo 支持两者。

## 参考

- Air8000 BLE 官方示例：`module/Air8000/demo/ble/peripheral`
- LuatOS BLE API：`https://docs.openluat.com/osapi/core/ble/`
