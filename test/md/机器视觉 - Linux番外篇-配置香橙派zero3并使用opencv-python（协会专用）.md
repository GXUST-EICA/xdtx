## Linux番外篇-配置香橙派zero3并使用opencv-python（协会专用）

### 硬件介绍

香橙派zero3是全志H618的芯片，自带千兆网口，蓝牙五等等，具体可以去官网了解。

- **香橙派zero3官网**: [香橙派zero3官网](http://www.orangepi.cn/html/hardWare/computerAndMicrocontrollers/details/Orange-Pi-Zero-3.html)

### 镜像配置

我们已经有配置好的Ubuntu镜像，几乎就是烧录镜像进去就可以用了。

### 镜像内容

1. **安装Ubuntu22.04镜像**
2. **香橙派zero3第一次配网**
3. **安装miniconda**
4. **创造虚拟环境名为"cv"，python版本为3.10**
5. **配置pip源为阿里源**
6. **安装了jupyter**
7. **安装了opencv-python,ultralytics(YOLOv8)和onnx**
8. **sudo的账号密码都是orangepi**

### 烧录镜像

1. **下载镜像**: 选用**32G**的闪迪或者其他读取速度高的储存卡，但是因为镜像太大了，我就没有放上云盘，而放在实验室的电脑上，文件夹目录在D盘的orangepi文件夹，大家可以拷贝下来或者在实验室的电脑上烧录。
2. **烧录镜像**: 使用win32diskimager，这个软件在下载中心有，大家可以下载下来，然后打开软件，检查插入储存卡的盘符，选择镜像文件，然后点击写入，等待完成即可。读卡器可以自己准备也可以询问学长借用。
3. **烧录完成之后，储存卡插入香橙派zero3，将15W或者以上的type-c充电器保证香橙派供电**（**这个需要自己准备，购买的开发板没有！**，一般自己手机都会有符合这个的充电器）。

### 连接方式

1. **连接成功之后，我们在下面看到我这个香橙派的ip地址是192.168.137.115，我们打开jupyter需要知道orangepi的ip地址，在浏览器输入192.168.137.115:8888就可以看到jupyter的界面了,如果需要密码的话，**jupyter默认密码是12345678**。
2. **这个就需要我们自己去学jupyter的基本用法了**: [Jupyter Notebook + OpenCV 完美组合](https://blog.csdn.net/weixin_44155966/article/details/112688909) | [15个应该掌握的Jupyter Notebook 使用技巧](https://zhuanlan.zhihu.com/p/256039090) | [一文弄懂Jupyter的配置与使用](https://blog.csdn.net/weixin_38556197/article/details/139426996) | [良心总结！Jupyter Notebook 从小白到高手](https://blog.csdn.net/cainiao_python/article/details/125567913)