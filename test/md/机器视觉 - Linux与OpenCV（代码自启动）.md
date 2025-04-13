## Linux与OpenCV（代码自启动）

### 代码自启动

我们写完代码之后，总是要手动执行，这样很麻烦，所以我们可以使用代码自启动，这样就可以自动执行代码了。

### 使用systemd管理服务

我们以Ubuntu为例，使用代码自启动，需要使用到systemd，systemd是Linux的系统和服务管理器，可以用来管理系统的服务和进程，我们使用systemd来管理代码自启动。

### 创建脚本

首先，我们需要创建脚本，我们可以用nano创建一个脚本，打开终端，输入以下命令：

```bash
nano /home/orangepi/code/start_pi.sh
然后复制并修改以下代码：

bash
#!/bin/bash
# 加载Conda环境变量，orangepi是香橙派zero3的用户名，miniconda3是miniconda的安装目录
source /home/orangepi/miniconda3/etc/profile.d/conda.sh

# 激活虚拟环境，cv是虚拟环境的名字，/home/orangepi/code是代码的目录，pi.py是代码的文件名
conda activate cv

# 运行Python脚本
/home/orangepi/miniconda3/envs/cv/bin/python /home/orangepi/code/pi.py
给予权限
按下ctrl+s保存，然后按下ctrl+x退出，然后给这个脚本给予权限，输入以下命令：

bash
sudo chmod +x /home/orangepi/code/start_pi.sh
创建systemd服务文件
代码自启动自然是，创建一个新的 systemd 服务文件，输入以下命令：

bash
sudo nano /etc/systemd/system/pi.service
然后复制并修改以下代码：

bash
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
启动服务
重新上电一下，输入以下命令，查看服务是否启动成功：

bash
sudo systemctl status pi.service
如果服务启动成功，会显示active (running)，如果服务启动失败，会显示inactive (dead)。

使用systemd管理服务
我们就可以使用代码自启动了。

<div align="center">
🎨 文档维护：自231班 黄海东 
📅 最后更新：2025.04.13  
📧 联系作者：jnjnjnn@163.com
</div>