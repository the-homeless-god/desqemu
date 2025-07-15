from flask import Flask, jsonify, render_template_string
import datetime
import os

app = Flask(__name__)

# HTML template for the main page
HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>🐳 DESQEMU API Demo</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
            padding: 2rem;
        }

        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255, 255, 255, 0.1);
            padding: 2rem;
            border-radius: 20px;
            backdrop-filter: blur(10px);
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
        }

        h1 {
            text-align: center;
            margin-bottom: 2rem;
            font-size: 2.5rem;
        }

        .endpoint {
            background: rgba(255, 255, 255, 0.1);
            padding: 1rem;
            margin: 1rem 0;
            border-radius: 10px;
            border: 1px solid rgba(255, 255, 255, 0.2);
        }

        .endpoint h3 {
            color: #ffd700;
            margin-bottom: 0.5rem;
        }

        .method {
            background: #4CAF50;
            color: white;
            padding: 0.2rem 0.5rem;
            border-radius: 3px;
            font-size: 0.8rem;
            margin-right: 0.5rem;
        }

        .url {
            font-family: monospace;
            background: rgba(0, 0, 0, 0.3);
            padding: 0.2rem 0.5rem;
            border-radius: 3px;
        }

        .status {
            background: rgba(76, 175, 80, 0.2);
            padding: 1rem;
            border-radius: 10px;
            margin: 1rem 0;
            border: 1px solid rgba(76, 175, 80, 0.3);
            text-align: center;
        }

        .timestamp {
            font-size: 0.9rem;
            opacity: 0.7;
            text-align: center;
            margin-top: 2rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 DESQEMU API Demo</h1>
        
        <div class="status">
            <strong>✅ API сервер работает!</strong><br>
            Время запуска: {{ startup_time }}
        </div>

        <div class="endpoint">
            <h3><span class="method">GET</span> <span class="url">/</span></h3>
            <p>Главная страница (эта страница)</p>
        </div>

        <div class="endpoint">
            <h3><span class="method">GET</span> <span class="url">/api/status</span></h3>
            <p>Статус API сервера в формате JSON</p>
        </div>

        <div class="endpoint">
            <h3><span class="method">GET</span> <span class="url">/api/time</span></h3>
            <p>Текущее время сервера</p>
        </div>

        <div class="endpoint">
            <h3><span class="method">GET</span> <span class="url">/api/info</span></h3>
            <p>Информация о системе</p>
        </div>

        <div class="timestamp">
            Запрос выполнен: {{ current_time }}
        </div>
    </div>
</body>
</html>
"""

@app.route('/')
def home():
    return render_template_string(HTML_TEMPLATE, 
                               startup_time=startup_time,
                               current_time=datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"))

@app.route('/api/status')
def status():
    return jsonify({
        'status': 'running',
        'service': 'DESQEMU API Demo',
        'version': '1.0.0',
        'timestamp': datetime.datetime.now().isoformat(),
        'uptime': str(datetime.datetime.now() - startup_time)
    })

@app.route('/api/time')
def time():
    return jsonify({
        'current_time': datetime.datetime.now().isoformat(),
        'timezone': 'UTC',
        'formatted': datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    })

@app.route('/api/info')
def info():
    return jsonify({
        'system': 'DESQEMU Alpine Linux',
        'container': 'Python Flask API',
        'features': [
            'Podman контейнеры',
            'QEMU эмуляция',
            'Chromium браузер',
            'Alpine Linux'
        ],
        'endpoints': [
            '/',
            '/api/status',
            '/api/time',
            '/api/info'
        ]
    })

if __name__ == '__main__':
    startup_time = datetime.datetime.now()
    print(f"🚀 DESQEMU API Demo запущен в {startup_time}")
    print(f"🌐 Доступен на http://localhost:8000")
    app.run(host='0.0.0.0', port=8000, debug=True) 
