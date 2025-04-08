#!/bin/sh
# 校园网登录服务 v1.0
# 依赖：busybox (httpd/nc)

WEB_PORT=8080
LOG_FILE="/tmp/xyw.log"
PID_FILE="/var/run/xyw.pid"
CONFIG_FILE="./xyw.conf"

start() {
    echo "Starting campus network service..."
    load_config
    # 启动守护进程
    {
        while true; do
            check_connection
            sleep ${CHECK_INTERVAL:-30}
        done
    } > $LOG_FILE 2>&1 &
    echo $! > $PID_FILE
    
    # 启动微型web服务器
    busybox httpd -p $WEB_PORT -h ./www &
    echo $! >> $PID_FILE
    
    # 创建网页目录
    mkdir -p ./www
    echo "$(gen_html)" > ./www/index.html
}

stop() {
    echo "Stopping service..."
    [ -f $PID_FILE ] && kill $(cat $PID_FILE) 
    rm -f $PID_FILE
}

check_connection() {
    # 原有网络检查逻辑的Shell实现
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
<form action="/login" method="post">
运营商: 
<select name="operator">
    <option value="@cmcc">中国移动</option>
    <option value="@telecom">中国电信</option>
    <option value="">校园网</option>
</select><br>
账号: <input name="user" value="${USERNAME}"><br>
密码: <input type="password" name="pass" value="${PASSWORD}"><br>
<button>立即登录</button>
</form>

<script>
document.forms[0].onsubmit = async (e) => {
    e.preventDefault();
    const form = new FormData(e.target);
    const res = await fetch('/login?user='+form.get('user')+'&pass='+form.get('pass'));
    alert(await res.text());
}
</script>
</body>
</html>
EOF
}

# HTTP请求处理
handle_http() {
    while read -r line; do
        # 解析GET请求
        if [[ $line =~ "GET /login" ]]; then
            params=${line#*?}
            params=${params% *}
            IFS='&' read -ra ARR <<< "$params"
            for p in "${ARR[@]}"; do
                case $p in
                    user=*) USERNAME=${p#*=} ;;
                    pass=*) PASSWORD=${p#*=} ;;
                    operator=*) OPERATOR=${p#*=} ;;
                esac
            done
            do_login && echo "Login OK" || echo "Login Failed"
        fi
    done < <(busybox nc -l -p $WEB_PORT)
}

save_config() {
    cat > $CONFIG_FILE <<EOF
USERNAME=$USERNAME
PASSWORD=$PASSWORD
OPERATOR=$OPERATOR
LOGIN_URL=$LOGIN_URL
CHECK_INTERVAL=$CHECK_INTERVAL
EOF
}

load_config() {
    [ -f $CONFIG_FILE ] && source $CONFIG_FILE
}

case "$1" in
    start)
        start
        handle_http & # 启动HTTP处理器
        ;;
    stop)
        stop
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac