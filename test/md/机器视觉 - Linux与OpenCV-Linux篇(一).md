## Linux与OpenCV-Linux篇（一）

我们学习Linux首先是需要了解Linux是什么，我们一般指的是GUN/linux ,它是一种免费使用和自由传播的类UNIX操作系统，它是一个基于POSIX和UNIX的多用户、多任务、支持多线程和多CPU的操作系统。

嵌入式Linux开发板，大多都可以使用Ubuntu，他是由Debian衍生而来，Ubuntu的版本号是根据年月来命名的，而你问我Debian是什么，它由Linux内核衍生而来。少数的Linux开发板使用的是其他系统，如树莓派使用的是Raspbian OS（基于Debian)，香橙派使用的是Orange Pi OS(基于arch Linux)。说了这么多Linux，其实他们几乎是通用的，少部分的命令可能跟其他Linux开发板不一样。

比如基于debian的Linux开发板，使用apt-get来安装软件，而基于arch的Linux开发板使用pacman来安装软件。

一般购买的嵌入式Linux开发板（无emmc版本），都有选择有无储存卡（SD卡）的套餐，储存卡是用来装系统的，有没有都可以自己准备，发到货的时候都是一张空的SD卡，需要自己烧录系统，下面是常见嵌入式Linux开发板烧录系统的教程：

- [树莓派烧录系统及其配置新系统教程](https://blog.csdn.net/lx_nhs/article/details/124859914)
- [鲁班猫烧录系统及其其他完整教程](https://doc.embedfire.com/linux/rk356x/quick_start/zh/latest/quick_start/flash_img/flash_img.html#id2)
- [香橙派烧录系统教程](https://blog.csdn.net/v13111329954/article/details/140795351)

进去之后就是连接开发板，如果我们不想用额外的显示器显示那个linux开发板的界面怎么办？很简单，使用串口连接Linux开发板配置wifi网络，并使用Windows的Realvnc（VNC Viewer）与Linux开发板连接。我们以树莓派为例：

- [用串口登陆树莓派配置wifi网络](https://blog.csdn.net/u011198687/article/details/120954860)
- [使用 VNC 远程访问树莓派](https://blog.csdn.net/qq_44214671/article/details/110581282)（注意，其他linux开发板可能不会自带vnc，所以需要自己安装）

如果不想使用串口连接，也可以使用网线连接，使用ssh连接，[香橙派首次通过网线SSH连接](https://blog.csdn.net/weixin_73546700/article/details/135931466)

Ubuntu这类的系统毕竟是系统，所以让你的开发板保证软件最新版本很重要，我们以Ubuntu为例子，apt是Ubuntu的包管理器，

```bash
apt-get update

<div align="center">
🎨 文档维护：自231班 黄海东 
📅 最后更新：2024.06  
📧 联系作者：jnjnjnn@163.com
</div>