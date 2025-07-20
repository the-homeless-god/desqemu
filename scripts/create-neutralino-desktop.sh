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
DESQEMU Neutralino Desktop App Creator

Usage: $0 [OPTIONS]

Options:
    --portable-archive FILE  Path to portable archive (required)
    --app-name NAME         Name of the desktop application (required)
    --app-description DESC  Description of the application
    --app-icon ICON         Path to app icon (SVG recommended)
    --arch ARCH             Target architecture (default: x86_64)
    --qcow2 FILE            Path to QCOW2 file (required)
    --help                  Show this help message

Examples:
    $0 --portable-archive my-app-portable-x86_64.tar.gz --app-name "My App" --qcow2 my-app.qcow2
    $0 --portable-archive penpot-portable-aarch64.tar.gz --app-name "Penpot" --app-icon penpot.svg --qcow2 penpot.qcow2
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

if [[ -z "$QCOW2_FILE" ]]; then
    echo "❌ Error: --qcow2 is required"
    show_help
    exit 1
fi

# Проверка существования файлов
if [[ ! -f "$PORTABLE_ARCHIVE" ]]; then
    echo "❌ Error: Portable archive not found: $PORTABLE_ARCHIVE"
    exit 1
fi

if [[ ! -f "$QCOW2_FILE" ]]; then
    echo "❌ Error: QCOW2 file not found: $QCOW2_FILE"
    exit 1
fi

if [[ -n "$APP_ICON" && ! -f "$APP_ICON" ]]; then
    echo "⚠️  Warning: App icon not found: $APP_ICON"
    APP_ICON=""
fi

echo "🚀 Creating Neutralino Desktop App"
echo "📦 App: $APP_NAME"
echo "📄 Portable archive: $PORTABLE_ARCHIVE"
echo "💾 QCOW2 file: $QCOW2_FILE"
echo "🏗️  Architecture: $ARCH"
echo ""

# Создаем временную директорию для сборки
BUILD_DIR="build/neutralino-$APP_NAME-$ARCH"
mkdir -p "$BUILD_DIR"

echo "📁 Creating build directory: $BUILD_DIR"

# Распаковываем портативный архив
echo "📦 Extracting portable archive..."
tar -xzf "$PORTABLE_ARCHIVE" -C "$BUILD_DIR"

# Копируем шаблон Neutralino
echo "📋 Copying Neutralino template..."
cp -r templates/neutralino-app/* "$BUILD_DIR/"

# Копируем QCOW2 файл в resources
echo "💾 Copying QCOW2 file..."
mkdir -p "$BUILD_DIR/resources/qcow2"
cp "$QCOW2_FILE" "$BUILD_DIR/resources/qcow2/app.qcow2"

# Копируем QEMU бинарники в resources
echo "🔧 Copying QEMU binaries..."
mkdir -p "$BUILD_DIR/resources/qemu"
cp -r "$BUILD_DIR/qemu-$ARCH"/* "$BUILD_DIR/resources/qemu/"

# Копируем иконку если есть
if [[ -n "$APP_ICON" ]]; then
    echo "🎨 Copying app icon..."
    cp "$APP_ICON" "$BUILD_DIR/resources/icons/app-icon.svg"
    # Конвертируем SVG в PNG для Neutralino
    if command -v rsvg-convert &> /dev/null; then
        rsvg-convert -w 512 -h 512 "$APP_ICON" -o "$BUILD_DIR/resources/icons/appIcon.png"
    else
        echo "⚠️  Warning: rsvg-convert not found, using default icon"
        cp "$BUILD_DIR/resources/icons/appIcon.png" "$BUILD_DIR/resources/icons/appIcon.png.bak"
    fi
fi

# Создаем конфигурацию приложения
echo "⚙️  Configuring application..."

# Заменяем переменные в neutralino.config.json
sed -i.bak \
    -e "s/{{APP_ID}}/$APP_NAME/g" \
    -e "s/{{APP_NAME}}/$APP_NAME/g" \
    -e "s/{{APP_TITLE}}/$APP_DESCRIPTION/g" \
    -e "s/{{APP_TYPE}}/desktop/g" \
    -e "s/{{DEFAULT_PORT}}/8080/g" \
    "$BUILD_DIR/neutralino.config.json"

# Заменяем переменные в package.json
sed -i.bak \
    -e "s/{{APP_NAME}}/$APP_NAME/g" \
    -e "s/{{APP_DESCRIPTION}}/$APP_DESCRIPTION/g" \
    "$BUILD_DIR/package.json"

# Заменяем переменные в HTML
sed -i.bak \
    -e "s/Penpot/$APP_DESCRIPTION/g" \
    -e "s/penpot-logo.svg/app-icon.svg/g" \
    "$BUILD_DIR/resources/index.html"

# Создаем скрипт автозапуска
cat > "$BUILD_DIR/resources/start-app.sh" << 'EOF'
#!/bin/bash

# DESQEMU Auto-start Script
# This script automatically starts QEMU and opens Chromium

echo "🚀 Starting $APP_NAME..."

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
QEMU_DIR="$SCRIPT_DIR/qemu"
QCOW2_FILE="$SCRIPT_DIR/qcow2/app.qcow2"

# Check if QEMU exists
if [[ ! -f "$QEMU_DIR/qemu-system-x86_64" ]]; then
    echo "❌ QEMU not found in $QEMU_DIR"
    exit 1
fi

# Check if QCOW2 exists
if [[ ! -f "$QCOW2_FILE" ]]; then
    echo "❌ QCOW2 file not found: $QCOW2_FILE"
    exit 1
fi

# Start QEMU with VNC
echo "🖥️  Starting QEMU VM..."
"$QEMU_DIR/qemu-system-x86_64" \
    -m 2G \
    -smp 2 \
    -netdev user,id=net0,hostfwd=tcp::8080-:8080,hostfwd=tcp::5900-:5900,hostfwd=tcp::2222-:22 \
    -device e1000,netdev=net0 \
    -vnc :0,password=on \
    -drive file="$QCOW2_FILE",format=qcow2,if=virtio \
    -daemonize \
    -pidfile /tmp/qemu-$APP_NAME.pid

# Wait for VM to start
sleep 5

# Check if VM is running
if [[ -f "/tmp/qemu-$APP_NAME.pid" ]]; then
    echo "✅ VM started successfully"
    echo "🌐 Application available at: http://localhost:8080"
    echo "📺 VNC available at: localhost:5900 (password: desqemu)"
else
    echo "❌ Failed to start VM"
    exit 1
fi
EOF

chmod +x "$BUILD_DIR/resources/start-app.sh"

# Создаем скрипт остановки
cat > "$BUILD_DIR/resources/stop-app.sh" << 'EOF'
#!/bin/bash

# DESQEMU Stop Script
PID_FILE="/tmp/qemu-$APP_NAME.pid"

if [[ -f "$PID_FILE" ]]; then
    PID=$(cat "$PID_FILE")
    echo "🛑 Stopping QEMU process $PID..."
    kill "$PID" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo "✅ VM stopped"
else
    echo "ℹ️  No running VM found"
fi
EOF

chmod +x "$BUILD_DIR/resources/stop-app.sh"

# Устанавливаем Node.js зависимости
echo "📦 Installing Node.js dependencies..."
cd "$BUILD_DIR"
npm install

# Создаем скрипт сборки для всех платформ
cat > "$BUILD_DIR/build-all-platforms.sh" << EOF
#!/bin/bash
set -e

echo "🏗️  Building $APP_NAME for all platforms..."

# Build for current platform
echo "🔨 Building for current platform..."
neu build --release

# Build for other platforms
echo "🔨 Building for Windows..."
neu build --release --platform windows

echo "🔨 Building for macOS..."
neu build --release --platform macos

echo "🔨 Building for Linux..."
neu build --release --platform linux

echo "✅ All builds completed!"
echo ""
echo "📦 Generated applications:"
echo "  - dist/$APP_NAME (current platform)"
echo "  - dist/$APP_NAME.exe (Windows)"
echo "  - dist/$APP_NAME.dmg (macOS)"
echo "  - dist/$APP_NAME.AppImage (Linux)"
EOF

chmod +x "$BUILD_DIR/build-all-platforms.sh"

# Создаем README для пользователя
cat > "$BUILD_DIR/README.md" << EOF
# $APP_NAME - Neutralino Desktop Application

## Описание

$APP_DESCRIPTION

Это нативное десктопное приложение, созданное с помощью DESQEMU и Neutralino.js.

## Быстрый запуск

### Сборка для всех платформ

\`\`\`bash
./build-all-platforms.sh
\`\`\`

### Запуск приложения

\`\`\`bash
# Текущая платформа
./dist/$APP_NAME

# Windows
./dist/$APP_NAME.exe

# macOS
open ./dist/$APP_NAME.dmg

# Linux
./dist/$APP_NAME.AppImage
\`\`\`

## Особенности

- **🖥️ Автоматический запуск** - QEMU + Chromium при старте
- **📦 Портативность** - включает QEMU бинарники
- **🔒 Безопасность** - полная изоляция в VM
- **🌐 Кроссплатформенность** - macOS, Windows, Linux

## Порты

- **8080** → Веб-приложение
- **5900** → VNC сервер (пароль: desqemu)
- **2222** → SSH доступ

## Структура

\`\`\`
$APP_NAME/
├── resources/
│   ├── qemu/           # QEMU бинарники
│   ├── qcow2/          # QCOW2 образ
│   ├── start-app.sh    # Скрипт запуска
│   └── stop-app.sh     # Скрипт остановки
├── neutralino.config.json
└── package.json
\`\`\`

## Поддержка

Для получения помощи обратитесь к документации DESQEMU:
https://github.com/the-homeless-god/desqemu
EOF

echo "✅ Neutralino desktop app created successfully!"
echo ""
echo "📁 Build directory: $BUILD_DIR"
echo "🚀 To build: cd $BUILD_DIR && ./build-all-platforms.sh"
echo ""

# Устанавливаем выходные переменные для GitHub Actions
echo "neutralino-path=$BUILD_DIR" >> $GITHUB_OUTPUT
echo "app-name=$APP_NAME" >> $GITHUB_OUTPUT
echo "app-arch=$ARCH" >> $GITHUB_OUTPUT

echo "🎉 Neutralino Desktop App Creator completed!" 
