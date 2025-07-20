#!/bin/bash

set -e

# Парсинг аргументов
QCOW2_FILE=""
QEMU_DIR=""
OUTPUT_FILE=""
APP_NAME=""
APP_DESCRIPTION=""

# Функция для вывода справки
show_help() {
    cat << EOF
Portable Archive Creator

Usage: $0 [OPTIONS]

Options:
    --qcow2 FILE         QCOW2 image file (required)
    --qemu-dir DIR       QEMU binaries directory (required)
    --output FILE        Output archive file (required)
    --app-name NAME      Application name
    --app-description DESC Application description
    --help               Show this help message

Examples:
    $0 --qcow2 app.qcow2 --qemu-dir qemu-x86_64 --output app-portable.tar.gz
    $0 --qcow2 my-app.qcow2 --qemu-dir qemu-aarch64 --output my-app-portable.tar.gz --app-name "My App"
EOF
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --qcow2)
            QCOW2_FILE="$2"
            shift 2
            ;;
        --qemu-dir)
            QEMU_DIR="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
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
if [[ -z "$QCOW2_FILE" ]]; then
    echo "❌ Error: --qcow2 is required"
    show_help
    exit 1
fi

if [[ -z "$QEMU_DIR" ]]; then
    echo "❌ Error: --qemu-dir is required"
    show_help
    exit 1
fi

if [[ -z "$OUTPUT_FILE" ]]; then
    echo "❌ Error: --output is required"
    show_help
    exit 1
fi

# Проверка существования файлов
if [[ ! -f "$QCOW2_FILE" ]]; then
    echo "❌ Error: QCOW2 file not found: $QCOW2_FILE"
    exit 1
fi

if [[ ! -d "$QEMU_DIR" ]]; then
    echo "❌ Error: QEMU directory not found: $QEMU_DIR"
    exit 1
fi

echo "📦 Creating portable archive..."
echo "📁 QCOW2: $QCOW2_FILE"
echo "📁 QEMU: $QEMU_DIR"
echo "📁 Output: $OUTPUT_FILE"

# Создаем временную директорию для архива
TEMP_DIR=$(mktemp -d)
ARCHIVE_DIR="$TEMP_DIR/$(basename "$OUTPUT_FILE" .tar.gz)"
mkdir -p "$ARCHIVE_DIR"

echo "📁 Creating archive structure..."

# Копируем QCOW2 файл
cp "$QCOW2_FILE" "$ARCHIVE_DIR/"

# Копируем QEMU бинарники
cp -r "$QEMU_DIR" "$ARCHIVE_DIR/"

# Создаем скрипт запуска
cat > "$ARCHIVE_DIR/start.sh" << 'EOF'
#!/bin/bash
set -e

echo "🚀 Starting DESQEMU application..."

# Определяем архитектуру
if [[ -f "qemu-x86_64/qemu-system-x86_64" ]]; then
    QEMU_BIN="qemu-x86_64/qemu-system-x86_64"
    ARCH="x86_64"
elif [[ -f "qemu-aarch64/qemu-system-aarch64" ]]; then
    QEMU_BIN="qemu-aarch64/qemu-system-aarch64"
    ARCH="aarch64"
else
    echo "❌ QEMU binary not found"
    exit 1
fi

echo "🔧 Using QEMU: $QEMU_BIN"

# Находим QCOW2 файл
QCOW2_FILE=$(find . -name "*.qcow2" | head -1)
if [[ -z "$QCOW2_FILE" ]]; then
    echo "❌ QCOW2 file not found"
    exit 1
fi

echo "📁 QCOW2 file: $QCOW2_FILE"

# Запускаем QEMU
echo "🚀 Starting QEMU VM..."
$QEMU_BIN \
    -m 2G \
    -smp 2 \
    -drive file="$QCOW2_FILE",format=qcow2 \
    -display gtk \
    -net nic \
    -net user \
    -vnc :0 \
    -daemonize

echo "✅ QEMU VM started successfully"
echo "🌐 VNC available at: localhost:5900"
echo "🔗 Web interface: http://localhost:8080"
EOF

chmod +x "$ARCHIVE_DIR/start.sh"

# Создаем скрипт остановки
cat > "$ARCHIVE_DIR/stop.sh" << 'EOF'
#!/bin/bash
set -e

echo "🛑 Stopping DESQEMU application..."

# Находим и останавливаем QEMU процессы
QEMU_PIDS=$(pgrep -f "qemu-system" || true)
if [[ -n "$QEMU_PIDS" ]]; then
    echo "🛑 Stopping QEMU processes: $QEMU_PIDS"
    kill $QEMU_PIDS
    sleep 2
    kill -9 $QEMU_PIDS 2>/dev/null || true
fi

echo "✅ DESQEMU application stopped"
EOF

chmod +x "$ARCHIVE_DIR/stop.sh"

# Создаем README
cat > "$ARCHIVE_DIR/README.md" << EOF
# DESQEMU Portable Application

${APP_DESCRIPTION:-A portable QEMU-based application}

## Quick Start

\`\`\`bash
# Start the application
./start.sh

# Stop the application
./stop.sh
\`\`\`

## Features

- 🖥️ **Portable** - includes QEMU binaries
- 🔒 **Secure** - full VM isolation
- 🌐 **Web interface** - accessible at http://localhost:8080
- 🖥️ **VNC access** - available at localhost:5900

## Requirements

- Linux/macOS/Windows
- No additional dependencies required

## Support

For help and documentation, visit:
https://github.com/the-homeless-god/desqemu
EOF

# Создаем архив
echo "📦 Creating archive..."
cd "$TEMP_DIR"
tar -czf "$OUTPUT_FILE" "$(basename "$ARCHIVE_DIR")"

# Перемещаем архив в текущую директорию
mv "$OUTPUT_FILE" "$(pwd)/"

echo "✅ Portable archive created successfully!"
echo "📁 Archive: $OUTPUT_FILE"
echo "📊 Size: $(du -h "$OUTPUT_FILE" | cut -f1)"

# Очищаем временную директорию
rm -rf "$TEMP_DIR" 
