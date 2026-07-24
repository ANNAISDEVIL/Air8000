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

## 烧录

使用 Luatools 烧录 `main.lua`，并勾选“添加默认 lib”。Air8000 的 BLE 功能依赖 WiFi 协处理器，如果扫描不到设备或连接异常，请先升级/确认 WiFi 固件。

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

## 参考

- Air8000 BLE 官方示例：`module/Air8000/demo/ble/peripheral`
- LuatOS BLE API：`https://docs.openluat.com/osapi/core/ble/`
