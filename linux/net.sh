#!/bin/bash

# 清屏
clear

# 显示署名
echo -e "\033[1;36m╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮\033[0m"
echo -e "\033[1;36m┃\033[0m                                                \033[1;36m┃\033[0m"
echo -e "\033[1;36m┃\033[0m                    \033[1;33m小东同学\033[0m                    \033[1;36m┃\033[0m"
echo -e "\033[1;36m┃\033[0m                \033[1;35m嵌入式智控协会\033[0m                  \033[1;36m┃\033[0m"
echo -e "\033[1;36m┃\033[0m                                                \033[1;36m┃\033[0m"
echo -e "\033[1;36m╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯\033[0m"
echo -e "\033[1;32m[✓] 正在启动校园网连接助手...\033[0m"
sleep 1
echo -e "\033[1;32m[✓] 正在初始化系统...\033[0m"
sleep 0.2
echo -e "\033[1;32m[✓] 正在检查网络连接...\033[0m"
sleep 0.5
echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then 
    print_error "请使用sudo运行此脚本"
    exit 1
fi

# 检测Linux发行版
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        VER=$(lsb_release -sr)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
    echo "$OS"
}

# 安装依赖
install_dependencies() {
    local distro=$1
    print_info "正在安装依赖..."
    
    case $distro in
        *"Ubuntu"*|*"Debian"*)
            apt-get update
            apt-get install -y python3 python3-pip python3-venv
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            yum install -y python3 python3-pip
            ;;
        *"Arch"*|*"Manjaro"*)
            pacman -Sy --noconfirm python python-pip
            ;;
        *)
            print_error "不支持的Linux发行版: $distro"
            exit 1
            ;;
    esac
}

# 定义安装路径
INSTALL_DIR="/usr/local/campus_network"

# 检查并创建安装目录
check_and_create_dir() {
    if [ ! -d "$INSTALL_DIR" ]; then
        print_info "创建安装目录: $INSTALL_DIR"
        mkdir -p "$INSTALL_DIR"
        if [ $? -ne 0 ]; then
            print_error "无法创建安装目录，尝试使用备用位置"
            INSTALL_DIR="/tmp/campus_network"
            mkdir -p "$INSTALL_DIR"
            if [ $? -ne 0 ]; then
                print_error "无法创建任何安装目录，安装失败"
                exit 1
            fi
        fi
    fi
}

# 创建虚拟环境并安装依赖
setup_python_env() {
    print_info "正在设置Python环境..."
    python3 -m venv "$INSTALL_DIR/venv"
    source "$INSTALL_DIR/venv/bin/activate"
    pip install flask requests
}

# 创建系统服务
create_service() {
    print_info "正在创建系统服务..."
    
    # 创建服务文件
    cat > /etc/systemd/system/campus-network.service << EOF
[Unit]
Description=Campus Network Auto Login Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python $INSTALL_DIR/net.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd
    systemctl daemon-reload
    systemctl enable campus-network.service
    print_info "服务已创建并启用"
}

# 主安装流程
main() {
    print_info "开始安装校园网连接助手..."
    
    # 检测发行版
    DISTRO=$(detect_distro)
    print_info "检测到系统: $DISTRO"
    
    # 安装依赖
    install_dependencies "$DISTRO"
    
    # 检查并创建安装目录
    check_and_create_dir
    
    # 下载主程序
    print_info "正在下载主程序..."
    while true; do
        read -p "请选择下载工具 (w: wget, c: curl): " choice
        case $choice in
            [Ww]* )
                if command -v wget >/dev/null 2>&1; then
                    wget "https://xdtx.eica.fun/linux/net.py" -O "$INSTALL_DIR/net.py"
                    break
                else
                    print_error "wget未安装，请选择curl或安装wget"
                fi
                ;;
            [Cc]* )
                if command -v curl >/dev/null 2>&1; then
                    curl -L "https://xdtx.eica.fun/linux/net.py" -o "$INSTALL_DIR/net.py"
                    break
                else
                    print_error "curl未安装，请选择wget或安装curl"
                fi
                ;;
            * )
                print_error "无效选择，请输入w或c"
                ;;
        esac
    done
    
    # 设置Python环境
    setup_python_env
    
    # 创建系统服务
    create_service
    
    # 设置权限
    chmod +x "$INSTALL_DIR/net.py"
    
    echo -e "\033[1;32m╭━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╮\033[0m"
    echo -e "\033[1;32m┃\033[0m                                                \033[1;32m┃\033[0m"
    echo -e "\033[1;32m┃\033[0m              \033[1;33m安装完成！\033[0m                        \033[1;32m┃\033[0m"
    echo -e "\033[1;32m┃\033[0m                                                \033[1;32m┃\033[0m"
    echo -e "\033[1;32m╰━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╯\033[0m"
    echo
    echo -e "\033[1;36m[信息] 请访问以下地址进行配置：\033[0m"
    echo -e "\033[1;33m    http://$(hostname -I | awk '{print $1}'):5000\033[0m"
    echo
    echo -e "\033[1;36m[信息] 正在启动服务...\033[0m"
    systemctl start campus-network
    sleep 2
    
    # 检查服务状态
    if systemctl is-active --quiet campus-network; then
        echo -e "\033[1;32m[成功] 服务已成功启动！\033[0m"
    else
        echo -e "\033[1;31m[错误] 服务启动失败，正在检查日志...\033[0m"
        echo -e "\033[1;36m[信息] 服务状态：\033[0m"
        systemctl status campus-network --no-pager
        echo
        echo -e "\033[1;36m[信息] 最近日志：\033[0m"
        journalctl -u campus-network -n 10 --no-pager
        echo
        echo -e "\033[1;33m[提示] 请检查以下可能的问题：\033[0m"
        echo -e "    1. Python环境是否正确安装"
        echo -e "    2. 所需依赖是否完整"
        echo -e "    3. 端口5000是否被占用"
        echo -e "    4. 网络连接是否正常"
        echo
        echo -e "\033[1;33m[提示] 您可以尝试手动启动服务来查看详细错误：\033[0m"
        echo -e "    cd $INSTALL_DIR"
        echo -e "    source venv/bin/activate"
        echo -e "    python net.py"
    fi
    echo
    echo -e "\033[1;36m[信息] 服务管理命令：\033[0m"
    echo -e "\033[1;35m    ▶ 启动服务：\033[0m sudo systemctl start campus-network"
    echo -e "\033[1;35m    ▶ 停止服务：\033[0m sudo systemctl stop campus-network"
    echo -e "\033[1;35m    ▶ 查看状态：\033[0m sudo systemctl status campus-network"
    echo -e "\033[1;35m    ▶ 查看日志：\033[0m sudo journalctl -u campus-network -f"
    echo
}

# 运行主程序
main 