# 🐧 Linux与OpenCV配置指南（二）

### 🛠️ Conda命令速查表
**环境管理核心指令**  
快速掌握Conda环境操作：

| 操作描述               | 终端指令                          |
|-----------------------|----------------------------------|
| **查看conda版本**      | `conda --version`               |
| **创建虚拟环境**       | `conda create -n myenv python=3.10` |
| **激活虚拟环境**       | `conda activate myenv`          |
| **退出虚拟环境**       | `conda deactivate`              |
| **删除虚拟环境**       | `conda remove -n myenv --all`   |

---

### 🚀 OpenCV配置流程
**四步完成环境部署**  
推荐操作顺序：

1. **创建专用环境** → `conda create -n cv python=3.10`
2. **激活环境** → `conda activate cv`
3. **安装OpenCV** → `pip install opencv-contrib-python`
4. **验证安装** → `python -c "import cv2; print(cv2.__version__)"`

---

### 🌐 镜像加速配置
**阿里云镜像设置**  
提升包下载速度的最佳实践：

```bash
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
pip config set install.trusted-host mirrors.aliyun.com
```

学习资源直达 → [![菜鸟教程](https://img.shields.io/badge/PIP教程-32CD32?style=flat-square)](https://www.runoob.com/python3/python3-pip.html)

---

<p align="center">
👨💻 文档维护：自231班 黄海东<br/>
📅 版本追踪：v2.1.3 (2025.04.13)<br/>
📧 技术支持：<a href="mailto:jnjnjnn@163.com">jnjnjnn@163.com</a>
</p>