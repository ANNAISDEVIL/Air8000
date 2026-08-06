# Air8000

在开始开发或升级固件前，请先学习简短刷机指南（基于 OpenLuat / Luatools） ， 重要链接如下：

- Luatools 使用文档（强烈建议阅读）：https://docs.openluat.com/common/Luatools/
- Air8000 LuatOS固件版本：https://docs.openluat.com/air8000/luatos/firmware/#sdkdemo
- Air8000 固件历史版本：https://cdn18.luatos.com/files/Air8000/LuatOS_Air8000/LuatOS-SoC_V2048_Air8000/
- Air8000 开发文档：https://docs.openluat.com/luatos_lesson/
- Air8000 demo git：https://gitee.com/openLuat/LuatOS/tree/master/module/Air8000/demo


快速刷机步骤

1. 下载并安装 Luatools。
2. 连接设备，选择4G模块USB 打印，（COM 端口串口打印没调出来，遂放弃）。 
3. 点项目管理测试，选择底层core，添加脚本（main.lua 必须有）。 
4. 点击下载脚本（参见硬件手册的按键或跳线方法）。 
5. 开始烧录，等待完成并提示成功。刷写期间不要断电或拔线。 


注意事项
刷机前备份重要数据/配置。

仓库顶层结构（简洁树状展示）：

```
Air8000/
├─ tcpTest/               : TCP 测试工程，可忽略，因为已经直接调通MQTT
├─ test_ble_peripheral/   : BLE 外设示例工程
├─ test_uart/             : 113B -> UART -> Air8000 测试工程
│  ├─ README.md
│  ├─ main.lua
│  └─ uart_polling.c      : DSP/TS113B 端 C 源（需编译并烧写到 DSP）
└─ test_whole/            : 113B -> UART -> Air8000 -> CAT1 -> MQTT Broker工程
   ├─ README.md
   ├─ main.lua
   └─ uart_polling.c      :（同上）完整的链路测试也需要 DSP 端 C 源
```

简要说明
- 某些测试依赖于运行在 DSP（即 113B）上的本地 C 代码；若缺少或未烧写 DSP 固件，测试会失败或部分功能不可用。