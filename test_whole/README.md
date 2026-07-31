# Air8000W 振动监测网关工程

基于合宙 Air8000W LTE Cat.1 模块 + LuatOS 的振动监测终端通信网关工程。

外部 DSP（TS113B）采集振动数据并通过 UART 发送给 Air8000W，Air8000W 负责 4G 拨号、MQTT 上云、云端指令透传。

---

## 1. 项目架构

```
┌─────────────────────────┐         UART          ┌──────────────────────┐
│  TS113B  (DSP)    │ ─────────────────────▶│   Air8000W (LuatOS)   │
│  - 振动 AD 采集         │ ◀─────────────────────│   - 4G 蜂窝拨号       │
│  - FFT / 频谱分析       │                       │   - MQTT 客户端       │
│  - 特征值计算           │                       │   - 串口数据转发       │
└─────────────────────────┘                       └──────────┬───────────┘
                                                             │ LTE Cat.1
                                                             ▼
                                                    ┌──────────────────┐
                                                    │  云端 MQTT Broker │
                                                    │  (EMQX / 阿里云等)│
                                                    └──────────────────┘
```

### 角色分工

| 模块 | 职责 |
|------|------|
| DSP 主控 | 振动信号采集、算法处理、业务逻辑 |
| Air8000W | 4G 通信、MQTT 协议、网络状态管理 |
| 云端 Broker | 消息路由、数据存储、下发指令 |

---

## 2. 目录结构

```
air8000_vibration_gateway/
├── main.lua          # 主程序入口（核心逻辑）
├── README.md         # 本文档
├── project.conf      # Luatools 工程配置（烧录工具自动生成）
└── user_cfg.txt      # 可选：APN / 网络参数自定义配置
```

---

## 3. 硬件接线

### DSP ↔ Air8000W 串口连接

| DSP 引脚 | Air8000W 引脚 | 说明 |
|----------|---------------|------|
| UARTx_TX | UART1_RX      | DSP 发 → Air8000 收 |
| UARTx_RX | UART1_TX      | DSP 收 ← Air8000 发 |
| GND      | GND           | 共地，必须连接 |

> ⚠️ 注意电平匹配：Air8000W 为 3.3V TTL 电平，若 DSP 为 3.3V 可直连；若为 5V 需加电平转换。

### 天线与 SIM 卡

- **主天线**：接 LTE 主集天线接口（ANT_MAIN）
- **SIM 卡**：Nano SIM，插入 SIM 卡槽，支持移动 / 联通 / 电信 4G

---

## 4. 环境搭建

### 4.1 所需工具

| 工具 | 用途 | 下载地址 |
|------|------|----------|
| Luatools | 固件烧录、脚本下载、日志调试 | 合宙官网 / LuatOS 文档站 |
| USB 数据线 | 连接 Air8000W 开发板到 PC | — |

### 4.2 固件版本要求

- Air8000W LuatOS 稳定版（建议 V1.2.0 及以上）
- 包含 `mqtt`、`socket`、`uart`、`sys` 标准库

### 4.3 烧录步骤

1. 打开 Luatools，选择对应 Air8000W 固件
2. 点击 **下载固件**，等待烧录完成
3. 切换到 **Lua 脚本下载** 界面
4. 添加 `main.lua`（及其他自定义 .lua 文件）
5. 点击 **下载脚本**，模块自动重启运行

---

## 5. 快速运行

### 5.1 修改配置

打开 `main.lua`，修改顶部配置区：

```lua
-- ====== 必须修改 ======
local MQTT_BROKER = "你的MQTT服务器地址"   -- 例如 "broker.emqx.io"
local MQTT_PORT = 1883                     -- 普通端口 1883，SSL 用 8883
local MQTT_USER = "用户名"                  -- 无认证留空
local MQTT_PWD  = "密码"                    -- 无认证留空

-- ====== 按需修改 ======
local UART_ID = 1            -- 串口编号，依硬件而定
local UART_BAUD = 115200     -- 波特率，与 DSP 端一致
local REPORT_CSQ_INTERVAL = 5000  -- 信号上报周期(ms)
```

### 5.2 查看运行日志

Luatools 连接模块后，在 **日志窗口** 可观察：

```
[INFO] network IP_READY 10.xx.xx.xx
[INFO] mqtt start connect broker.emqx.io 1883
[INFO] mqtt connect success
[INFO] status csq 24 imei 867xxxxxxxxxxxx
```

---

## 6. MQTT 主题定义

| 主题 | 方向 | QoS | 说明 |
|------|------|-----|------|
| `device/vibration/upload` | 终端 → 云端 | 0 | 振动数据 / 算法结果上报 |
| `device/vibration/cmd` | 云端 → 终端 | 0 | 云端下发控制指令 |
| `device/vibration/status` | 终端 → 云端 | 0 | （可选）CSQ / 状态心跳 |

### Client ID 规则

默认使用 IMEI 作为 Client ID，保证全局唯一：

```lua
local MQTT_CLIENT_ID = "vib_" .. mobile.imei()
```

---

## 7. 串口通信协议

### 7.1 默认模式：透明传输

当前工程为 **透传模式**：
- DSP 通过串口发出的数据 → Air8000 直接作为 MQTT payload 上传
- 云端下发的 MQTT payload → Air8000 直接通过串口转发给 DSP

Air8000 **不解析业务数据内容**，业务协议完全由 DSP 侧定义。

### 7.2 推荐协议帧格式（DSP 侧自行实现）

若后续需要帧校验 / 粘包处理，建议 DSP 侧采用如下帧结构：

| 字段 | 字节数 | 说明 |
|------|--------|------|
| 帧头 | 2 | `0xAA 0x55` |
| 长度 | 2 | payload 字节数（大端） |
| 命令码 | 1 | 数据类型 / 指令类型 |
| Payload | N | 业务数据 |
| 校验和 | 1 | 前面所有字节累加和取低 8 位 |

> 如需在 Air8000 侧实现帧解析，可在 `uart_recv_cb` 中增加状态机解析逻辑。

---

## 8. 功能特性

### ✅ 已实现

- [x] 4G 自动拨号，IP 状态监听（IP_READY / IP_LOSE）
- [x] MQTT 客户端自动连接 + 断线重连
- [x] 串口 ↔ MQTT 双向透传
- [x] 定时上报 CSQ 信号强度与 IMEI
- [x] 网络掉线时自动释放 MQTT 资源，防止内存泄漏
- [x] 重连冷却机制，避免频繁拨号

### 🚧 可选扩展（按需开启）

- [ ] 硬件看门狗 / 软件看门狗
- [ ] 断网数据本地缓存 + 恢复补发
- [ ] MQTT SSL/TLS 加密（8883 端口）
- [ ] MQTT 遗嘱消息（Will）
- [ ] 低功耗 PSM / eDRX 休眠模式
- [ ] 串口帧解析与粘包处理
- [ ] OTA 远程升级

---

## 9. 常见问题 FAQ

### Q1：模块一直没有 `IP_READY` 事件？
排查步骤：
1. 检查 SIM 卡是否插好、是否欠费
2. 检查天线是否接牢
3. 查看日志中 CSQ 值，小于 10 说明信号弱
4. 确认 APN 设置，可通过 `user_cfg.txt` 配置

### Q2：MQTT 连接失败怎么办？
1. 确认 Broker 地址 / 端口 / 账号密码正确
2. 确认服务器 1883 端口未被防火墙封禁
3. 用 PC 端 MQTT 工具（如 MQTTX）验证服务器可用性
4. 检查 Client ID 是否重复冲突

### Q3：串口收不到 DSP 数据？
1. 确认 TX / RX 没有接反
2. 确认波特率、数据位、停止位两端一致
3. 用示波器 / 逻辑分析仪抓波形确认 DSP 端是否有输出
4. 共地是否良好

### Q4：Air8000W 支持 AT 指令吗？
**不支持。** Air8000W 为 LuatOS 纯脚本方案，没有 AT 固件。所有功能通过 Lua API 调用，这也是本工程存在的意义。

---

## 10. 关键 API 速查

### 网络相关

```lua
mobile.csq()        -- 获取信号强度，返回 0~31，99 表示无信号
mobile.imei()       -- 获取模块 IMEI
-- 事件：IP_READY / IP_LOSE
```

### MQTT 相关

```lua
mqtt.client(clientid, keepalive, username, password)  -- 创建实例
client:connect(host, port)         -- 连接 Broker
client:subscribe(topic, qos)       -- 订阅主题
client:publish(topic, payload, qos) -- 发布消息
client:connected()                 -- 查询连接状态
client:close()                     -- 关闭连接，释放资源
client:on(callback)                -- 设置消息接收回调
```

### 串口相关

```lua
uart.setup(id, baud, databits, stopbits, parity)  -- 初始化
uart.on(id, callback)           -- 注册接收回调
uart.write(id, data)            -- 发送数据
```

---

## 11. 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0.0 | 2026-07-27 | 初始版本，基础 MQTT 透传 + 网络状态管理 |

---

## 12. 相关文档

- LuatOS 官方文档：https://wiki.luatos.com
- Air8000W 硬件手册
- MQTT 3.1.1 协议规范
