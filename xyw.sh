#!/bin/sh
# 校园网登录服务 v1.2
# 依赖：busybox (nc)

WEB_PORT=2481
LOG_FILE="/tmp/xyw.log"
PID_FILE="/var/run/xyw.pid"
CONFIG_FILE="./xyw.conf"

start() {
    echo "Starting campus network service..."
    echo "Access URL: http://$(hostname -i):$WEB_PORT/"
    load_config
    mkdir -p ./www
    echo "$(gen_html)" > ./www/index.html
    
    {
        while true; do
            handle_http &
            sleep ${CHECK_INTERVAL:-30}
            check_connection
        done
    } > $LOG_FILE 2>&1 &
    echo $! > $PID_FILE
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
    busybox nc -l -p $WEB_PORT -e sh -c "
        while read -r line; do
            if echo \"\$line\" | grep -q '^GET /login'; then
                params=\"\${line#*?}\"
                params=\"\${params% *}\"
                IFS='&' read -ra ARR <<< \"\$params\"
                for p in \"\${ARR[@]}\"; do
                    case \$p in
                        user=*) USERNAME=\${p#*=} ;;
                        pass=*) PASSWORD=\${p#*=} ;;
                        operator=*) OPERATOR=\${p#*=} ;;
                    esac
                done
                echo -e 'HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nConnection: close\r\n\r'
                do_login && echo '登录成功' || echo '登录失败'
                break
            elif echo \"\$line\" | grep -q '^GET / '; then
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
