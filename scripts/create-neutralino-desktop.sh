#!/bin/bash

set -e

# Парсинг аргументов
PORTABLE_ARCHIVE=""
APP_NAME=""
APP_DESCRIPTION=""
APP_ICON=""
ARCH="x86_64"
QCOW2_FILE=""

# Функция для вывода справки
show_help() {
    cat << EOF
Neutralino Desktop App Creator

Usage: $0 [OPTIONS]

Options:
    --portable-archive FILE  Portable archive file (required)
    --app-name NAME         Application name (required)
    --app-description DESC  Application description
    --app-icon ICON         Path to app icon (SVG recommended)
    --arch ARCH             Target architecture (default: x86_64)
    --qcow2 FILE            QCOW2 image file
    --help                  Show this help message

Examples:
    $0 --portable-archive app-portable.tar.gz --app-name "My App"
    $0 --portable-archive app.tar.gz --app-name "My App" --app-icon icon.svg --arch x86_64
EOF
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --portable-archive)
            PORTABLE_ARCHIVE="$2"
            shift 2
            ;;
        --app-name)
            APP_NAME="$2"
            shift 2
            ;;
        --app-description)
            APP_DESCRIPTION="$2"
            shift 2
            ;;
        --app-icon)
            APP_ICON="$2"
            shift 2
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --qcow2)
            QCOW2_FILE="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Проверка обязательных параметров
if [[ -z "$PORTABLE_ARCHIVE" ]]; then
    echo "❌ Error: --portable-archive is required"
    show_help
    exit 1
fi

if [[ -z "$APP_NAME" ]]; then
    echo "❌ Error: --app-name is required"
    show_help
    exit 1
fi

# Проверка существования файлов
if [[ ! -f "$PORTABLE_ARCHIVE" ]]; then
    echo "❌ Error: Portable archive not found: $PORTABLE_ARCHIVE"
    exit 1
fi

if [[ -n "$APP_ICON" && ! -f "$APP_ICON" ]]; then
    echo "⚠️  Warning: App icon not found: $APP_ICON"
    APP_ICON=""
fi

echo "🖥️  Creating Neutralino desktop application..."
echo "📦 App: $APP_NAME"
echo "📁 Archive: $PORTABLE_ARCHIVE"
echo "🏗️  Architecture: $ARCH"

# Создаем директорию для Neutralino приложения
NEUTRALINO_DIR="neutralino-$ARCH"
mkdir -p "$NEUTRALINO_DIR"

echo "📁 Creating Neutralino directory: $NEUTRALINO_DIR"

# Создаем конфигурацию Neutralino
cat > "$NEUTRALINO_DIR/neutralino.config.json" << EOF
{
  "applicationId": "com.desqemu.${APP_NAME// /-}",
  "version": "1.0.0",
  "defaultMode": "window",
  "port": 0,
  "documentRoot": "/resources/",
  "url": "/",
  "enableServer": true,
  "enableNativeAPI": true,
  "tokenSecurity": "one-time",
  "logging": {
    "enabled": true,
    "writeToFile": true
  },
  "nativeAllowList": [
    "app.*",
    "os.*",
    "filesystem.*",
    "window.*"
  ],
  "globalVariables": {
    "APP_NAME": "$APP_NAME",
    "APP_DESCRIPTION": "$APP_DESCRIPTION"
  },
  "modes": {
    "window": {
      "title": "$APP_NAME",
      "width": 1200,
      "height": 800,
      "minWidth": 800,
      "minHeight": 600,
      "center": true,
      "enableInspector": false,
      "borderless": false,
      "maximize": false,
      "hidden": false,
      "resizable": true,
      "exitProcessOnClose": true
    }
  },
  "cli": {
    "binaryName": "$APP_NAME",
    "resourcesPath": "/resources/",
    "extensionsPath": "/extensions/",
    "clientLibrary": "/lib/neutralino.js",
    "frontendLibrary": {
      "patchFile": "/lib/neutralino.js",
      "mount": {
        "backend": "/lib/neutralino.js"
      }
    }
  }
}
EOF

# Создаем структуру ресурсов
mkdir -p "$NEUTRALINO_DIR/resources"
mkdir -p "$NEUTRALINO_DIR/lib"

# Создаем HTML интерфейс
cat > "$NEUTRALINO_DIR/resources/index.html" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$APP_NAME</title>
    <link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="container">
        <header>
            <h1>$APP_NAME</h1>
            <p>$APP_DESCRIPTION</p>
        </header>
        
        <main>
            <div class="status-panel">
                <h2>Application Status</h2>
                <div id="status">Initializing...</div>
            </div>
            
            <div class="controls">
                <button id="start-btn" class="btn btn-primary">Start Application</button>
                <button id="stop-btn" class="btn btn-secondary" disabled>Stop Application</button>
                <button id="status-btn" class="btn btn-info">Check Status</button>
            </div>
            
            <div class="info-panel">
                <h3>Access Information</h3>
                <ul>
                    <li><strong>Web Interface:</strong> <a href="http://localhost:8080" target="_blank">http://localhost:8080</a></li>
                    <li><strong>VNC Access:</strong> localhost:5900</li>
                    <li><strong>SSH Access:</strong> ssh desqemu@localhost -p 2222</li>
                </ul>
            </div>
        </main>
    </div>
    
    <script src="js/app.js"></script>
</body>
</html>
EOF

# Создаем CSS стили
cat > "$NEUTRALINO_DIR/resources/css/style.css" << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    color: #333;
}

.container {
    max-width: 800px;
    margin: 0 auto;
    padding: 2rem;
}

header {
    text-align: center;
    margin-bottom: 3rem;
    color: white;
}

header h1 {
    font-size: 2.5rem;
    margin-bottom: 0.5rem;
    text-shadow: 0 2px 4px rgba(0,0,0,0.3);
}

header p {
    font-size: 1.1rem;
    opacity: 0.9;
}

.status-panel, .controls, .info-panel {
    background: white;
    border-radius: 12px;
    padding: 1.5rem;
    margin-bottom: 1.5rem;
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
}

.status-panel h2, .info-panel h3 {
    margin-bottom: 1rem;
    color: #2c3e50;
}

#status {
    padding: 1rem;
    border-radius: 8px;
    background: #f8f9fa;
    border-left: 4px solid #007bff;
    font-family: 'Courier New', monospace;
}

.controls {
    display: flex;
    gap: 1rem;
    flex-wrap: wrap;
}

.btn {
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 8px;
    font-size: 1rem;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;
    flex: 1;
    min-width: 120px;
}

.btn-primary {
    background: #007bff;
    color: white;
}

.btn-primary:hover {
    background: #0056b3;
    transform: translateY(-2px);
}

.btn-secondary {
    background: #6c757d;
    color: white;
}

.btn-secondary:hover {
    background: #545b62;
    transform: translateY(-2px);
}

.btn-info {
    background: #17a2b8;
    color: white;
}

.btn-info:hover {
    background: #138496;
    transform: translateY(-2px);
}

.btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
    transform: none;
}

.info-panel ul {
    list-style: none;
}

.info-panel li {
    padding: 0.5rem 0;
    border-bottom: 1px solid #eee;
}

.info-panel li:last-child {
    border-bottom: none;
}

.info-panel a {
    color: #007bff;
    text-decoration: none;
}

.info-panel a:hover {
    text-decoration: underline;
}

.status-success {
    border-left-color: #28a745 !important;
    background: #d4edda !important;
}

.status-error {
    border-left-color: #dc3545 !important;
    background: #f8d7da !important;
}

.status-warning {
    border-left-color: #ffc107 !important;
    background: #fff3cd !important;
}
EOF

# Создаем JavaScript логику
cat > "$NEUTRALINO_DIR/resources/js/app.js" << 'EOF'
// DESQEMU Desktop Application
class DESQEMUApp {
    constructor() {
        this.isRunning = false;
        this.init();
    }

    init() {
        this.bindEvents();
        this.updateStatus('Ready to start application');
    }

    bindEvents() {
        document.getElementById('start-btn').addEventListener('click', () => this.startApp());
        document.getElementById('stop-btn').addEventListener('click', () => this.stopApp());
        document.getElementById('status-btn').addEventListener('click', () => this.checkStatus());
    }

    async startApp() {
        try {
            this.updateStatus('Starting application...', 'warning');
            document.getElementById('start-btn').disabled = true;
            
            // Здесь будет логика запуска QEMU
            await this.simulateStart();
            
            this.isRunning = true;
            this.updateStatus('Application is running', 'success');
            document.getElementById('stop-btn').disabled = false;
            
        } catch (error) {
            this.updateStatus(`Error starting application: ${error.message}`, 'error');
            document.getElementById('start-btn').disabled = false;
        }
    }

    async stopApp() {
        try {
            this.updateStatus('Stopping application...', 'warning');
            document.getElementById('stop-btn').disabled = true;
            
            // Здесь будет логика остановки QEMU
            await this.simulateStop();
            
            this.isRunning = false;
            this.updateStatus('Application stopped', 'success');
            document.getElementById('start-btn').disabled = false;
            
        } catch (error) {
            this.updateStatus(`Error stopping application: ${error.message}`, 'error');
            document.getElementById('stop-btn').disabled = false;
        }
    }

    async checkStatus() {
        try {
            this.updateStatus('Checking status...', 'warning');
            
            // Здесь будет проверка статуса QEMU
            await this.simulateStatusCheck();
            
            const status = this.isRunning ? 'Application is running' : 'Application is stopped';
            this.updateStatus(status, this.isRunning ? 'success' : 'error');
            
        } catch (error) {
            this.updateStatus(`Error checking status: ${error.message}`, 'error');
        }
    }

    updateStatus(message, type = 'info') {
        const statusEl = document.getElementById('status');
        statusEl.textContent = message;
        statusEl.className = `status-${type}`;
    }

    // Симуляция для демонстрации
    simulateStart() {
        return new Promise(resolve => {
            setTimeout(resolve, 2000);
        });
    }

    simulateStop() {
        return new Promise(resolve => {
            setTimeout(resolve, 1000);
        });
    }

    simulateStatusCheck() {
        return new Promise(resolve => {
            setTimeout(resolve, 500);
        });
    }
}

// Инициализация приложения
document.addEventListener('DOMContentLoaded', () => {
    new DESQEMUApp();
});
EOF

# Копируем иконку если есть
if [[ -n "$APP_ICON" ]]; then
    cp "$APP_ICON" "$NEUTRALINO_DIR/resources/app-icon.svg"
else
    # Создаем дефолтную иконку
    cat > "$NEUTRALINO_DIR/resources/app-icon.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#4A90E2" rx="20"/>
  <text x="50" y="60" font-family="Arial, sans-serif" font-size="40" fill="white" text-anchor="middle">D</text>
</svg>
EOF
fi

# Создаем скрипт сборки для всех платформ
cat > "$NEUTRALINO_DIR/build-all-platforms.sh" << 'EOF'
#!/bin/bash
set -e

echo "🖥️  Building Neutralino desktop application for all platforms..."

# Проверяем наличие Neutralino CLI
if ! command -v neu &> /dev/null; then
    echo "❌ Neutralino CLI not found. Installing..."
    npm install -g @neutralinojs/neu
fi

# Собираем для всех платформ
echo "🔨 Building for Linux..."
neu build --release

echo "🔨 Building for Windows..."
neu build --release --target win

echo "🔨 Building for macOS..."
neu build --release --target mac

echo "✅ All platform builds completed!"
echo "📁 Check the dist/ directory for built applications"
EOF

chmod +x "$NEUTRALINO_DIR/build-all-platforms.sh"

echo "✅ Neutralino desktop application created successfully!"
echo "📁 Directory: $NEUTRALINO_DIR"
echo "🚀 To build: cd $NEUTRALINO_DIR && ./build-all-platforms.sh" 
