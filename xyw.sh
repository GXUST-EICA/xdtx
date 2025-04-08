#!/bin/sh
# 校园网登录服务 v1.4
# 依赖：busybox (nc)

WEB_PORT=2481
LOG_FILE="/tmp/xyw.log"
PID_FILE="/var/run/xyw.pid"
CONFIG_FILE="./xyw.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
    echo "$1"
}

start() {
    echo "🟢 正在启动校园网服务..."
    
    # 强制指定监听地址
    BIND_IP="0.0.0.0"
    echo "🔗 监听地址: $BIND_IP:$WEB_PORT"
    
    # 检查端口占用
    if netstat -ltn | grep -q ":$WEB_PORT "; then
        log "❌ 端口 $WEB_PORT 已被占用"
        exit 1
    fi
    
    # 加载配置
    load_config
    [ -z "$USERNAME" ] && log "⚠️ 未检测到账号配置"
    
    # 创建网页目录
    mkdir -p ./www || {
        log "❌ 无法创建网页目录"
        exit 1
    }
    echo "$(gen_html)" > ./www/index.html
    
    # 主服务循环
    {
        log "✅ 服务进程启动 PID: $$"
        while true; do
            log "🔄 等待HTTP连接..."
            handle_http &
            sleep ${CHECK_INTERVAL:-30}
            log "🔍 开始网络状态检查..."
            check_connection
        done
    } >> $LOG_FILE 2>&1 &
    
    echo $! > $PID_FILE
    log "✅ 服务启动完成! PID: $(cat $PID_FILE)"
    echo "👉 调试命令: tail -f $LOG_FILE"
}

stop() {
    echo "Stopping service..."
    [ -f $PID_FILE ] && kill $(cat $PID_FILE) 
    rm -f $PID_FILE
}

check_connection() {
    if ! wget -qO- --timeout=3 http://www.baidu.com | grep -qi 'baidu'; then
        do_login
    fi
}

do_login() {
    if curl -sG "$LOGIN_URL" \
        --data-urlencode "DDDDD=${USERNAME}${OPERATOR}" \
        --data-urlencode "upass=${PASSWORD}" \
        --data "0MKKey=123456" | grep -q '"result":1'; then
        save_config
        return 0
    else
        return 1
    fi
}

gen_html() {
    cat <<EOF
<html>
<head><title>校园网控制</title></head>
<body>
<h2>网络状态</h2>
<pre>$(date +%F%T) $(check_connection && echo Connected || echo Disconnected)</pre>

<h3>手动登录</h3>
<form action="/login" method="get">
运营商: 
<select name="operator">
    <option value="@cmcc" ${OPERATOR=='@cmcc'&&'selected'}>中国移动</option>
    <option value="@telecom" ${OPERATOR=='@telecom'&&'selected'}>中国电信</option>
    <option value="" ${OPERATOR==''&&'selected'}>校园网</option>
</select><br>
账号: <input name="user" value="${USERNAME}"><br>
密码: <input type="password" name="pass" value="${PASSWORD}"><br>
<button>立即登录</button>
</form>

<script>
document.forms[0].onsubmit = async (e) => {
    e.preventDefault();
    const params = new URLSearchParams(new FormData(e.target));
    const res = await fetch('/login?'+params.toString());
    alert(await res.text());
    location.reload();
}
</script>
</body>
</html>
EOF
}

handle_http() {
    log "🌐 收到新的HTTP请求"
    # 使用兼容性更好的nc参数
    /bin/busybox nc -l -p $WEB_PORT -s 0.0.0.0 -e /bin/sh -c "
        log '🔛 NC进程启动 (PID $$)'
        # 设置超时防止僵死进程
        timeout -t 5 -s KILL sh -c '
            while read -r line; do
                line=\${line%%\$'\r'*}
                log \"📨 原始请求: \$line\"
                case \"\$line\" in
                    *'GET /login'*)
                        params=\"\${line#*?}\"
                        params=\"\${params%% *}\"
                        log \"🔠 解码前参数: \$params\"
                        params=\$(echo -e \"\${params//%/\\\\x}\")
                        log \"🔡 解码后参数: \$params\"
                        
                        IFS='&' read -ra ARR <<< \"\$params\"
                        for p in \"\${ARR[@]}\"; do
                            case \$p in
                                user=*) USERNAME=\${p#*=} ;;
                                pass=*) PASSWORD=\${p#*=} ;;
                                operator=*) OPERATOR=\${p#*=} ;;
                            esac
                        done
                        
                        echo -e 'HTTP/1.1 200 OK\r'
                        echo -e 'Content-Type: text/plain\r\n'
                        if do_login; then
                            echo '✅ 登录成功'
                            log \"💚 用户 \${USERNAME} 登录成功\"
                        else
                            echo '❌ 登录失败'
                            log \"💔 用户 \${USERNAME} 登录失败\"
                        fi
                        ;;
                    *'GET /'*)
                        log '📄 返回网页界面'
                        echo -e 'HTTP/1.1 200 OK\r'
                        echo -e 'Content-Type: text/html\r\n'
                        cat ./www/index.html
                        ;;
                    *)
                        log '🚫 未知请求类型'
                        echo -e 'HTTP/1.1 404 Not Found\r\n'
                        ;;
                esac
                break  # 单次请求处理
            done
        '
    " 2>>$LOG_FILE
}

save_config() {
    cat > $CONFIG_FILE <<EOF
USERNAME='$USERNAME'
PASSWORD='$PASSWORD'
OPERATOR='$OPERATOR'
LOGIN_URL='$LOGIN_URL'
CHECK_INTERVAL='$CHECK_INTERVAL'
EOF
}

load_config() {
    [ -f $CONFIG_FILE ] && source $CONFIG_FILE
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac 
