#!/bin/sh
# 校园网登录服务 v1.3
# 依赖：busybox (nc)

WEB_PORT=2481
LOG_FILE="/tmp/xyw.log"
PID_FILE="/var/run/xyw.pid"
CONFIG_FILE="./xyw.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
    echo "$1"  # 控制台直接输出
}

start() {
    echo "🟢 正在启动校园网服务..."
    echo "🔗 访问地址: http://$(hostname -i):$WEB_PORT/"
    
    load_config
    log "加载配置: USERNAME=${USERNAME} OPERATOR=${OPERATOR}"
    
    mkdir -p ./www || {
        echo "❌ 无法创建网页目录"
        exit 1
    }
    echo "$(gen_html)" > ./www/index.html
    
    {
        log "服务进程启动 PID: $$"
        while true; do
            log "等待HTTP连接..."
            handle_http &
            sleep ${CHECK_INTERVAL:-30}
            log "开始定期网络检查..."
            check_connection
        done
    } >> $LOG_FILE 2>&1 &
    echo $! > $PID_FILE
    echo "✅ 服务已启动! PID: $(cat $PID_FILE)"
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
    log "收到新的HTTP请求"
    busybox nc -l -p $WEB_PORT -e sh -c "
        log 'NC进程启动处理请求'
        while read -r line; do
            echo \"原始请求: \$line\" >> $LOG_FILE
            if echo \"\$line\" | grep -q '^GET /login'; then
                params=\"\${line#*?}\"
                params=\"\${params% *}\"
                log \"登录请求参数: \$params\"
                
                IFS='&' read -ra ARR <<< \"\$params\"
                for p in \"\${ARR[@]}\"; do
                    case \$p in
                        user=*) USERNAME=\${p#*=} ;;
                        pass=*) PASSWORD=\${p#*=} ;;
                        operator=*) OPERATOR=\${p#*=} ;;
                    esac
                done
                
                echo -e 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r'
                if do_login; then
                    echo '登录成功'
                    log '用户 ${USERNAME} 登录成功'
                else
                    echo '登录失败'
                    log '用户 ${USERNAME} 登录失败'
                fi
                break
            elif echo \"\$line\" | grep -q '^GET / '; then
                log '返回网页界面'
                echo -e 'HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close\r\n\r'
                cat ./www/index.html
                break
            fi
        done
    "
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
