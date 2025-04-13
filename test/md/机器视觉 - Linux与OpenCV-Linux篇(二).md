## Linux与OpenCV-Linux篇（二）

### Conda命令

1. **查看conda版本**: `conda --version`
2. **创建虚拟环境**: `conda create -n myenv python=3.10`
3. **激活虚拟环境**: `conda activate myenv`
4. **退出虚拟环境**: `conda deactivate`
5. **删除虚拟环境**: `conda remove -n myenv --all`
6. **升级全部库**: `conda update --all`
7. **升级一个包**: `conda update package_name`
8. **查看已安装的包**: `conda list`
9. **移除一个包**: `conda remove opencv`
10. **安装一个包**: `conda install opencv`

### 使用顺序

1. **创建虚拟环境**: `conda create -n cv python=3.10`
2. **激活虚拟环境**: `conda activate cv`
3. **安装opencv-python**: `pip install opencv-contrib-python`
4. **使用opencv**: `python`

### 更换pip源

建议更换pip源为阿里源，直接在命令窗口输入:

```bash
pip config set global.index-url https://mirrors.aliyun.com/pypi/simple
pip config set install.trusted-host mirrors.aliyun.com
```
- [菜鸟教程的pip教程](https://www.runoob.com/python3/python3-pip.html)
---

<div align="center">
🎨 文档维护：自231班 黄海东 
📅 最后更新：2025.04.13  
📧 联系作者：jnjnjnn@163.com
</div>