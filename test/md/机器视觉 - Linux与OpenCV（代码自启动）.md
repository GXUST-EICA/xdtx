# 🐧 OpenCV服务自启动配置指南

### 🔄 技术方案对比
**自启动方式选择**  

| 方式         | 优势                        | 适用场景               |
|--------------|----------------------------|-----------------------|
| **systemd**  | 🎯 系统级服务管理            | 长期运行/开机自启      |
| **crontab**  | ⏰ 定时任务调度              | 周期性执行任务         |
| **手动启动** | 🖥️ 临时调试                 | 开发测试阶段           |

---

### 🛠️ systemd服务配置流程
**四步完成服务部署**  

| 步骤 | 操作说明                  | 关键命令/文件           |
|------|---------------------------|-------------------------|
| 1️⃣   | 创建启动脚本              | `/home/orangepi/code/start_pi.sh` |
| 2️⃣   | 编写服务配置文件          | `/etc/systemd/system/pi.service` |
| 3️⃣   | 重载服务配置              | `sudo systemctl daemon-reload` |
| 4️⃣   | 启用并启动服务            | `sudo systemctl enable --now pi.service` |

---

### 📜 关键配置文件示例
**启动脚本配置**  

```bash
#!/bin/bash
# 加载Conda环境变量，orangepi是香橙派zero3的用户名，miniconda3是miniconda的安装目录
source /home/orangepi/miniconda3/etc/profile.d/conda.sh

# 激活虚拟环境，cv是虚拟环境的名字，/home/orangepi/code是代码的目录，pi.py是代码的文件名
conda activate cv

# 运行Python脚本
/home/orangepi/miniconda3/envs/cv/bin/python /home/orangepi/code/pi.py
```

**systemd服务文件**  
```ini
[Unit]
Description=Run pi.py in cv Conda Environment
After=network.target

[Service]
Type=simple
ExecStart=/home/orangepi/code/start_pi.sh
WorkingDirectory=/home/orangepi/code
StandardOutput=inherit
StandardError=inherit
Restart=always
User=orangepi

[Install]
WantedBy=multi-user.target
```

---

### 🔍 服务状态监控
**常用管理命令**  

```bash
# 查看服务状态
sudo systemctl status pi.service

# 重启服务
sudo systemctl restart pi.service

# 查看日志
journalctl -u pi.service -f
```

---

### 🚨 常见问题排查
| 现象                 | 可能原因                  | 解决方案               |
|----------------------|--------------------------|------------------------|
| 服务启动失败         | 脚本权限不足             | `chmod +x start_pi.sh` |
| Conda环境未激活      | 环境变量加载路径错误      | 检查conda.sh路径       |
| Python依赖缺失       | 虚拟环境包未安装         | `pip install -r requirements.txt` |

<p align="center">
👨💻 文档维护：自231班 黄海东<br/>
📅 版本追踪：v2.1.3 (2025.04.13)<br/>
📧 技术支持：<a href="mailto:jnjnjnn@163.com">jnjnjnn@163.com</a>
</p>