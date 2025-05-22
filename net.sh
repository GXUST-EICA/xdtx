#!/bin/bash

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

# 创建虚拟环境并安装依赖
setup_python_env() {
    print_info "正在设置Python环境..."
    python3 -m venv /opt/campus_network
    source /opt/campus_network/bin/activate
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
WorkingDirectory=/opt/campus_network
ExecStart=/opt/campus_network/bin/python /opt/campus_network/net.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd
    systemctl daemon-reload
    systemctl enable campus-network.service
    print_info "服务已创建并启用"
    
    # 运行systemctl daemon-reload
    print_info "正在重新加载systemd..."
    sudo systemctl daemon-reload
    print_info "systemd重新加载完成"
}

# 主安装流程
main() {
    print_info "开始安装校园网连接助手..."
    
    # 检测发行版
    DISTRO=$(detect_distro)
    print_info "检测到系统: $DISTRO"
    
    # 安装依赖
    install_dependencies "$DISTRO"
    
    # 创建安装目录
    mkdir -p /opt/campus_network
    
    # 下载主程序
    print_info "正在下载主程序..."
    curl -L "https://xdtx.eica.fun/linux/net.py" -o /opt/campus_network/net.py
    
    # 设置Python环境
    setup_python_env
    
    # 创建系统服务
    create_service
    
    # 设置权限
    chmod +x /opt/campus_network/net.py
    
    print_info "安装完成！"
    print_info "请访问 http://localhost:5000 进行配置"
    print_info "使用以下命令管理服务："
    echo "启动服务：sudo systemctl start campus-network"
    echo "停止服务：sudo systemctl stop campus-network"
    echo "查看状态：sudo systemctl status campus-network"
}

# 运行主程序
main 