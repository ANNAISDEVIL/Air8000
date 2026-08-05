# Air8000

在开始开发或升级固件前，请先学习简短刷机指南（基于 OpenLuat / Luatools） ， 重要链接如下：

- Luatools 使用文档（强烈建议阅读）：https://docs.openluat.com/common/Luatools/
- Air8000 LuatOS固件版本：https://docs.openluat.com/air8000/luatos/firmware/#sdkdemo
- Air8000 固件历史版本：https://cdn18.luatos.com/files/Air8000/LuatOS_Air8000/LuatOS-SoC_V2048_Air8000/


快速刷机步骤

1. 下载并安装 Luatools。
2. 连接设备，选择4G模块USB 打印，（COM 端口串口打印有点问题）。 
3. 点项目管理测试，选择底层core，添加脚本（main.lua 必须有）。 
4. 点击下载脚本（参见硬件手册的按键或跳线方法）。 
5. 开始烧录，等待完成并提示成功。刷写期间不要断电或拔线。 


注意事项
刷机前备份重要数据/配置。
