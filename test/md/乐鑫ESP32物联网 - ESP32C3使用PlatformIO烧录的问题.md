# 🔌 ESP32-C3 PlatformIO烧录配置指南

### 🚨 问题根源
**RISC-V架构特殊配置需求**  

| 芯片型号       | 指令集架构       | 烧录模式要求  |
|----------------|------------------|--------------|
| ESP32-S系列    | ARM Cortex-M3    | 自动识别      |
| **ESP32-C3**   | RISC-V           | 需手动指定    |

---

### 🛠️ 解决方案
**platformio.ini配置示例**

## ESP32C3使用PlatformIO烧录的问题

由于ESP32-C3采用开源的RISC-V指令集架构，与ESP32-S系列使用的ARM Cortex-M3架构不同，因此在使用PlatformIO进行烧录时，需要在配置文件添加一行代码。

### 添加代码

在platformio.ini文件中添加一行代码：

```ini
[env:esp32-c3-devkitm-1]
platform = espressif32
board_build.flash_mode = dio
board = esp32-c3-devkitm-1
framework = arduino
lib_deps =
```

<div align="center">
🎨 文档维护：自231班 黄海东 
📅 最后更新：2025.04.13  
📧 联系作者：jnjnjnn@163.com
</div>