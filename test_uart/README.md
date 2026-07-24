# Air8000 UART11 Test

这个项目用于快速测试 Air8000 核心板的 UART11 收发功能。

## 功能

- 串口：`UART11`
- 波特率：`115200`
- 数据位：`8`
- 停止位：`1`
- 校验位：无
- 模块每 3 秒主动发送一行：`Hello from Air8000 UART11`
- PC 或外部 MCU 向 UART11 发送任意数据后，模块会回写：`Air8000 received: <收到的数据>`
- LuatOS 日志会打印接收长度、字符串内容和 hex 内容

## 文件

- `main.lua`：UART11 测试入口脚本

## 烧录

使用 Luatools 烧录 `main.lua`，并勾选“添加默认 lib”。

烧录完成后，打开 Luatools 日志窗口或其他串口日志工具，观察 `UART11` 标签日志。

## 接线

使用 USB 转 TTL 模块或外部 MCU 连接 Air8000 的 UART11 引脚。

典型接线方式：

| Air8000 | USB 转 TTL / 外部 MCU |
| --- | --- |
| UART11_TX | RX |
| UART11_RX | TX |
| GND | GND |

注意：

- TX 和 RX 需要交叉连接。
- 电平需匹配 Air8000 引脚电平，不要直接接入不兼容的高电压串口。
- UART11 的具体引脚位置请以核心板原理图或《Air8000系列模组核心板使用说明》为准。

## PC 端验证

1. 将 USB 转 TTL 接到 Air8000 的 UART11。
2. 打开 SSCOM、LLCOM、MobaXterm 等串口工具。
3. 串口参数设置为 `115200, 8N1, no flow control`。
4. 烧录并运行脚本。
5. 预期现象：
   - PC 串口工具每 3 秒收到 `Hello from Air8000 UART11`。
   - PC 发送 `hello` 后，会收到 `Air8000 received: hello`。
   - LuatOS 日志中能看到 `RX len`、`RX string`、`RX hex`。

## 常见问题

### PC 收不到模块主动发送的数据

- 检查是否连接到 UART11，而不是日志口或其他 UART。
- 检查 TX/RX 是否交叉连接。
- 检查 GND 是否共地。
- 检查串口工具波特率是否为 `115200`。

### 模块收不到 PC 发送的数据

- 确认 PC 串口工具发送的数据没有被错误编码或自动追加特殊字符。
- 确认 USB 转 TTL 的 TX 已连接到 Air8000 的 UART11_RX。
- 用示波器或逻辑分析仪确认 TX 线上是否有波形。

### 日志正常但外部串口无数据

- LuatOS 日志口和 UART11 不是同一个串口。
- 请确认烧录的是本目录下的 `main.lua`。
- 请确认 Air8000 固件支持当前脚本中的 `uart` 库。
