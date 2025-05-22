import requests
import time
from datetime import datetime
import urllib3
import os
import json
import platform
from flask import Flask, render_template, request, jsonify
import threading
import logging

urllib3.disable_warnings()

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s',  # 简化日志格式
    handlers=[
        logging.FileHandler('campus_network.log'),
        logging.StreamHandler()
    ]
)

VERSION = "2.0"
USERNAME = "" 
PASSWORD = ""
OPERATORS = {
    "中国移动": "@cmcc",
    "中国联通": "@cucc",
    "中国电信": "@ctcc",
    "免费校园网": ""
}
LOGIN_URL = "http://172.16.1.11/drcom/login"
TEST_URL = "http://www.baidu.com"

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key'

class CampusNetwork:
    def __init__(self):
        self.config_path = os.path.join(os.path.expanduser('~'), '.campus_network_config.json')
        self.is_running = False
        self.load_config()
        self.logs = []
        self.max_logs = 100  # 最多保存100条日志
        self.monitoring_thread = None
        self.is_mips = self.check_architecture()
        
    def check_architecture(self):
        """检查系统架构"""
        arch = platform.machine().lower()
        return arch in ['mips', 'mipsel']
        
    def load_config(self):
        """加载配置"""
        try:
            if os.path.exists(self.config_path):
                with open(self.config_path, 'r') as f:
                    config = json.load(f)
                    self.username = config.get('username', '')
                    self.password = config.get('password', '')
                    self.operator = config.get('operator', '免费校园网')
                    self.interval = config.get('interval', '30')
            else:
                self.username = ''
                self.password = ''
                self.operator = '免费校园网'
                self.interval = '30'
        except Exception as e:
            logging.error(f"加载配置失败: {str(e)}")
            self.username = ''
            self.password = ''
            self.operator = '免费校园网'
            self.interval = '30'

    def save_config(self):
        """保存配置"""
        try:
            config = {
                'username': self.username,
                'password': self.password,
                'operator': self.operator,
                'interval': self.interval
            }
            with open(self.config_path, 'w') as f:
                json.dump(config, f)
        except Exception as e:
            logging.error(f"保存配置失败: {str(e)}")

    def log(self, message):
        """记录日志"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] {message}"
        self.logs.append(log_entry)
        if len(self.logs) > self.max_logs:
            self.logs.pop(0)
        logging.info(message)

    def check_connection(self):
        """检查网络连接"""
        try:
            response = requests.get(TEST_URL, timeout=5)
            return response.status_code == 200
        except:
            return False

    def campus_network_login(self):
        """校园网登录"""
        operator = OPERATORS[self.operator]
        
        params = {
            'callback': 'dr1003',
            'DDDDD': self.username + operator if operator else self.username,
            'upass': self.password,
            '0MKKey': '123456',
            'R1': '0',
            'R2': '',
            'R3': '0',
            'R6': '0',
            'para': '00',
            'v6ip': '',
            'terminal_type': '1',
            'lang': 'zh-cn',
            'jsVersion': '4.1.3',
            'v': '2282'
        }
        
        try:
            # 先检查是否能访问登录服务器
            try:
                requests.get("http://172.16.1.11", timeout=3)
            except:
                self.log("无法连接到校园网认证服务器")
                return False

            # 尝试登录
            response = requests.get(LOGIN_URL, params=params, verify=False, timeout=5)
                
            if '"result":1' in response.text:
                return True
            elif 'already' in response.text.lower():
                self.log("账号已在线")
                return True
            elif 'password' in response.text.lower():
                self.log("用户名或密码错误")
                return False
            else:
                self.log("登录失败，检查账号密码运行商是否正确！")
                return False
            
        except requests.exceptions.Timeout:
            self.log("登录请求超时")
            return False
        except requests.exceptions.ConnectionError:
            self.log("网络连接错误")
            return False
        except Exception as e:
            self.log(f"登录异常: {str(e)}")
            return False

    def start_monitoring(self):
        if not self.is_running:
            self.is_running = True
            self.log("开始自动连接...")
            if self.monitoring_thread is None or not self.monitoring_thread.is_alive():
                self.monitoring_thread = threading.Thread(target=self.monitoring_loop)
                self.monitoring_thread.daemon = True
                self.monitoring_thread.start()

    def stop_monitoring(self):
        if self.is_running:
            self.is_running = False
            self.log("停止自动连接...")
            if self.monitoring_thread and self.monitoring_thread.is_alive():
                self.monitoring_thread.join(timeout=1)

    def monitoring_loop(self):
        while self.is_running:
            if not self.check_connection():
                self.retry_login(0)
            else:
                self.log("网络连接正常")
                self.schedule_next_check()
            time.sleep(1)  # 添加短暂延迟，避免CPU占用过高

    def retry_login(self, attempt):
        if not self.is_running or attempt >= 3:
            if attempt >= 3:
                self.log("多次登录尝试均失败，请检查账号密码运行商是否正确！")
            self.schedule_next_check()
            return
            
        if self.campus_network_login():
            self.log("重新登录成功！")
            self.schedule_next_check()
        else:
            self.log(f"第{attempt+1}次登录尝试失败，等待5秒后重试...")
            time.sleep(5)
            self.retry_login(attempt + 1)

    def schedule_next_check(self):
        """安排下一次检查"""
        if not self.is_running:
            return
            
        try:
            interval = int(self.interval)
            if interval < 5:
                interval = 5
                self.interval = "5"
                self.save_config()
        except ValueError:
            interval = 30
            self.interval = "30"
            self.save_config()

        time.sleep(interval)  # 直接等待，而不是使用Timer
        if self.is_running:  # 检查是否还在运行
            self.monitoring_loop()

# 创建全局实例
campus_net = CampusNetwork()

@app.route('/')
def index():
    return render_template('index.html', 
                         username=campus_net.username,
                         password=campus_net.password,
                         operator=campus_net.operator,
                         interval=campus_net.interval,
                         is_running=campus_net.is_running,
                         logs=campus_net.logs[-10:],  # 只显示最近10条日志
                         operators=list(OPERATORS.keys()),
                         is_mips=campus_net.is_mips)  # 添加MIPS架构标志

@app.route('/api/update_config', methods=['POST'])
def update_config():
    try:
        data = request.json
        campus_net.username = data.get('username', '')
        campus_net.password = data.get('password', '')
        campus_net.operator = data.get('operator', '免费校园网')
        campus_net.interval = data.get('interval', '30')
        campus_net.save_config()
        return jsonify({'status': 'success', 'message': '配置已保存'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': f'保存配置失败: {str(e)}'}), 500

@app.route('/api/toggle_monitoring', methods=['POST'])
def toggle_monitoring():
    try:
        if not campus_net.is_running:
            campus_net.start_monitoring()
            return jsonify({
                'status': 'success',
                'is_running': True,
                'message': '已开始自动连接'
            })
        else:
            campus_net.stop_monitoring()
            return jsonify({
                'status': 'success',
                'is_running': False,
                'message': '已停止自动连接'
            })
    except Exception as e:
        logging.error(f"切换监控状态失败: {str(e)}")
        return jsonify({
            'status': 'error',
            'message': f'操作失败: {str(e)}'
        }), 500

@app.route('/api/get_logs', methods=['GET'])
def get_logs():
    try:
        return jsonify({
            'status': 'success',
            'logs': campus_net.logs[-10:]
        })
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'获取日志失败: {str(e)}'
        }), 500

if __name__ == "__main__":
    # 创建templates目录
    os.makedirs('templates', exist_ok=True)
    
    # 创建index.html模板
    with open('templates/index.html', 'w', encoding='utf-8') as f:
        f.write('''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>校园网自动登录</title>
    <style>
        :root {
            --primary-color: #1246ff;
            --primary-hover: #0d3cc2;
            --success-color: #10b981;
            --error-color: #ef4444;
            --text-color: #1f2937;
            --border-color: #e5e7eb;
            --bg-color: #f8fafc;
        }
        
        /* 基础样式 */
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        body {
            font-family: 'Microsoft YaHei UI', sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
            font-size: 22px;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 20px;
        }
        
        .container {
            background-color: white;
            padding: 32px 36px;
            border-radius: 16px;
            box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
            transition: all 0.3s ease;
            width: 100%;
            max-width: 640px;
            min-width: 320px;
            margin: 40px auto;
        }
        
        h1 {
            text-align: center;
            color: var(--primary-color);
            margin-bottom: 32px;
            font-size: 48px;
            font-weight: 700;
            letter-spacing: 2px;
        }
        
        .form-group {
            margin-bottom: 22px;
            width: 100%;
        }
        
        label {
            display: block;
            margin-bottom: 8px;
            color: var(--text-color);
            font-weight: 500;
            font-size: 22px;
        }
        
        input, select {
            width: 100%;
            padding: 12px 14px;
            border: 2px solid var(--border-color);
            border-radius: 8px;
            font-size: 22px;
            transition: all 0.3s ease;
            background-color: white;
        }
        
        button {
            background-color: var(--primary-color);
            color: white;
            border: none;
            padding: 14px 0;
            border-radius: 8px;
            cursor: pointer;
            font-size: 26px;
            font-weight: 600;
            transition: all 0.3s ease;
            width: 100%;
            margin-top: 10px;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .log-area {
            background-color: var(--bg-color);
            padding: 14px;
            border-radius: 8px;
            margin-top: 22px;
            height: 140px;
            overflow-y: auto;
            font-family: 'Consolas', monospace;
            border: 1px solid var(--border-color);
            box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.05);
        }
        
        .log-entry {
            margin: 6px 0;
            color: var(--text-color);
            font-size: 18px;
            line-height: 1.5;
            padding: 2px 6px;
            border-radius: 4px;
            transition: background-color 0.2s ease;
        }
        
        .status-message {
            margin-top: 14px;
            padding: 12px;
            border-radius: 8px;
            display: none;
            font-weight: 500;
            text-align: center;
            animation: fadeIn 0.3s ease;
            font-size: 20px;
        }
        
        .footer {
            text-align: center;
            margin-top: 28px;
            padding-top: 16px;
            border-top: 1px solid var(--border-color);
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 12px;
        }
        
        .footer-buttons {
            display: flex;
            gap: 16px;
            flex-wrap: wrap;
            justify-content: center;
        }
        
        .footer a {
            color: var(--primary-color);
            text-decoration: none;
            font-weight: 500;
            transition: all 0.3s ease;
            padding: 10px 22px;
            border-radius: 20px;
            background-color: rgba(18, 70, 255, 0.1);
            display: inline-flex;
            align-items: center;
            gap: 8px;
            font-size: 18px;
        }
        
        .footer a i {
            font-size: 22px;
        }
        
        .version {
            color: #6b7280;
            font-size: 15px;
            margin-top: 4px;
        }
        
        .author {
            color: #6b7280;
            font-size: 15px;
            margin-top: 2px;
        }
        
        /* 响应式设计 */
        @media (max-width: 900px) {
            .container {
                max-width: 98vw;
                padding: 12px 4vw;
            }
            h1 {
                font-size: 32px;
            }
            .footer-buttons {
                gap: 8px;
            }
        }
        @media (max-width: 600px) {
            .container {
                min-width: unset;
                padding: 8px 2vw;
            }
            h1 {
                font-size: 22px;
            }
            .footer-buttons {
                flex-direction: column;
                gap: 8px;
                width: 100%;
            }
            .footer a {
                width: 100%;
                justify-content: center;
            }
        }
        
        /* 自定义滚动条 */
        ::-webkit-scrollbar {
            width: 8px;
            height: 8px;
        }
        
        ::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 4px;
        }
        
        ::-webkit-scrollbar-thumb {
            background: #c1c1c1;
            border-radius: 4px;
        }
        
        ::-webkit-scrollbar-thumb:hover {
            background: #a8a8a8;
        }
        
        /* 动画效果 */
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        
        .status-success {
            background-color: #d1fae5;
            color: var(--success-color);
        }
        
        .status-error {
            background-color: #fee2e2;
            color: var(--error-color);
        }
        
        .button-running {
            background-color: var(--error-color);
        }
        
        .button-running:hover {
            background-color: #dc2626;
        }
        
        button:hover {
            background-color: var(--primary-hover);
            transform: translateY(-2px);
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        
        button:disabled {
            background-color: #93c5fd;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
        }
        
        input:focus, select:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 3px rgba(18, 70, 255, 0.1);
        }
        
        .log-entry:hover {
            background-color: rgba(0, 0, 0, 0.05);
        }
        
        .footer a:hover {
            color: var(--primary-hover);
            background-color: rgba(18, 70, 255, 0.2);
            transform: translateY(-2px);
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>校园网自动登录</h1>
        
        <div class="form-group">
            <label for="username">账号</label>
            <input type="text" id="username" value="{{ username }}" placeholder="请输入账号">
        </div>
        
        <div class="form-group">
            <label for="password">密码</label>
            <input type="password" id="password" value="{{ password }}" placeholder="请输入密码">
        </div>
        
        <div class="form-group">
            <label for="operator">运营商</label>
            <select id="operator">
                {% for op in operators %}
                <option value="{{ op }}" {% if op == operator %}selected{% endif %}>{{ op }}</option>
                {% endfor %}
            </select>
        </div>
        
        <div class="form-group">
            <label for="interval">检查间隔（秒）</label>
            <input type="number" id="interval" value="{{ interval }}" min="5" placeholder="最小5秒">
        </div>
        
        <button id="toggleButton" class="{{ 'button-running' if is_running else '' }}">
            {{ "停止连接" if is_running else "开始连接" }}
        </button>
        
        <div id="statusMessage" class="status-message"></div>
        
        <div class="log-area" id="logArea">
            {% for log in logs %}
            <div class="log-entry">{{ log }}</div>
            {% endfor %}
        </div>

        <div class="footer">
            <div class="footer-buttons">
                <a href="http://www.eica.fun" target="_blank">
                    <i class="fas fa-microchip"></i>
                    嵌入式智控协会
                </a>
                <a href="https://xdtx.eica.fun" target="_blank">
                    <i class="fas fa-download"></i>
                    获取其他版本的连接工具
                </a>
            </div>
            <div class="version">Version {{ version }}</div>
            <div class="author">@小东同学</div>
        </div>
    </div>

    <script>
        let isRunning = {{ 'true' if is_running else 'false' }};
        
        function showStatus(message, isError = false) {
            const statusDiv = document.getElementById('statusMessage');
            statusDiv.textContent = message;
            statusDiv.className = `status-message ${isError ? 'status-error' : 'status-success'}`;
            statusDiv.style.display = 'block';
            setTimeout(() => {
                statusDiv.style.display = 'none';
            }, 3000);
        }

        function updateConfig() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;
            const operator = document.getElementById('operator').value;
            const interval = document.getElementById('interval').value;

            if (!username || !password) {
                showStatus('账号和密码不能为空', true);
                return;
            }

            fetch('/api/update_config', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    username: username,
                    password: password,
                    operator: operator,
                    interval: interval
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    showStatus(data.message);
                } else {
                    showStatus(data.message, true);
                }
            })
            .catch(error => {
                showStatus('保存配置失败: ' + error, true);
            });
        }

        function toggleMonitoring() {
            const username = document.getElementById('username').value;
            const password = document.getElementById('password').value;

            if (!username || !password) {
                showStatus('请先输入账号和密码', true);
                return;
            }

            const button = document.getElementById('toggleButton');
            button.disabled = true;  // 禁用按钮防止重复点击

            fetch('/api/toggle_monitoring', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                }
            })
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    isRunning = data.is_running;
                    button.textContent = isRunning ? '停止连接' : '开始连接';
                    button.className = isRunning ? 'button-running' : '';
                    showStatus(data.message);
                } else {
                    showStatus(data.message || '操作失败', true);
                }
            })
            .catch(error => {
                showStatus('操作失败: ' + error, true);
            })
            .finally(() => {
                button.disabled = false;  // 恢复按钮状态
            });
        }

        function updateLogs() {
            fetch('/api/get_logs')
            .then(response => response.json())
            .then(data => {
                if (data.status === 'success') {
                    const logArea = document.getElementById('logArea');
                    logArea.innerHTML = data.logs.map(log => 
                        `<div class="log-entry">${log}</div>`
                    ).join('');
                    logArea.scrollTop = logArea.scrollHeight;
                }
            })
            .catch(error => {
                console.error('获取日志失败:', error);
            });
        }

        // 绑定按钮点击事件
        document.getElementById('toggleButton').addEventListener('click', toggleMonitoring);
        
        // 当输入框失去焦点时保存配置
        ['username', 'password', 'operator', 'interval'].forEach(id => {
            document.getElementById(id).addEventListener('change', updateConfig);
        });

        // 每2秒更新一次日志
        //setInterval(updateLogs, 2000);
    </script>
</body>
</html>
        ''')
    
    # 自动启动自动连接（如果配置了账号和密码）
    if campus_net.username and campus_net.password:
        campus_net.start_monitoring()

    # 启动Flask应用
    log = logging.getLogger('werkzeug')
    log.setLevel(logging.ERROR)
    app.run(host='0.0.0.0', port=5000,debug=False) 