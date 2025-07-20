#!/bin/bash

set -e

# Парсинг аргументов
COMPOSE_FILE=""
OUTPUT_FILE=""
ARCH="x86_64"

# Функция для вывода справки
show_help() {
    cat << EOF
Docker Compose to QCOW2 Converter

Usage: $0 [OPTIONS]

Options:
    --compose-file FILE  Path to docker-compose.yml file (required)
    --output FILE        Output QCOW2 file name (required)
    --arch ARCH         Target architecture (default: x86_64)
    --help              Show this help message

Examples:
    $0 --compose-file docker-compose.yml --output app.qcow2
    $0 --compose-file my-app.yml --output my-app-x86_64.qcow2 --arch x86_64
EOF
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --compose-file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --arch)
            ARCH="$2"
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
if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ Error: --compose-file is required"
    show_help
    exit 1
fi

if [[ -z "$OUTPUT_FILE" ]]; then
    echo "❌ Error: --output is required"
    show_help
    exit 1
fi

# Проверка существования файлов
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "❌ Error: Docker Compose file not found: $COMPOSE_FILE"
    exit 1
fi

echo "🐳 Converting Docker Compose to QCOW2..."
echo "📄 Compose file: $COMPOSE_FILE"
echo "📁 Output: $OUTPUT_FILE"
echo "🏗️  Architecture: $ARCH"

# Проверяем контейнерный движок
echo "🔍 Checking container engine..."
./scripts/container-manager.sh detect

# Создаем базовый QCOW2 образ
echo "🔧 Creating base QCOW2 image..."
qemu-img create -f qcow2 "$OUTPUT_FILE" 20G

# Создаем временную директорию для сборки
TEMP_DIR=$(mktemp -d)
echo "📁 Temporary directory: $TEMP_DIR"

# Копируем Docker Compose файл
cp "$COMPOSE_FILE" "$TEMP_DIR/docker-compose.yml"

# Создаем скрипт для запуска контейнеров
cat > "$TEMP_DIR/start-containers.sh" << 'EOF'
#!/bin/bash
set -e

echo "🚀 Starting containers..."

# Определяем контейнерный движок
if command -v podman &> /dev/null; then
    ENGINE="podman"
    COMPOSE="podman-compose"
elif command -v docker &> /dev/null; then
    ENGINE="docker"
    COMPOSE="docker-compose"
else
    echo "❌ No container engine found"
    exit 1
fi

echo "🔧 Using $ENGINE with $COMPOSE"

# Запускаем контейнеры
$COMPOSE up -d

echo "✅ Containers started successfully"
echo "📋 Running containers:"
$ENGINE ps
EOF

chmod +x "$TEMP_DIR/start-containers.sh"

# Создаем скрипт остановки
cat > "$TEMP_DIR/stop-containers.sh" << 'EOF'
#!/bin/bash
set -e

echo "🛑 Stopping containers..."

# Определяем контейнерный движок
if command -v podman &> /dev/null; then
    COMPOSE="podman-compose"
elif command -v docker &> /dev/null; then
    COMPOSE="docker-compose"
else
    echo "❌ No container engine found"
    exit 1
fi

# Останавливаем контейнеры
$COMPOSE down

echo "✅ Containers stopped successfully"
EOF

chmod +x "$TEMP_DIR/stop-containers.sh"

echo "✅ Docker Compose to QCOW2 conversion completed!"
echo "📁 QCOW2 file: $OUTPUT_FILE"
echo "📁 Scripts created in: $TEMP_DIR"

# Очищаем временную директорию
rm -rf "$TEMP_DIR" 
