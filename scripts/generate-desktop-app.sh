#!/bin/bash

# ============================================================================
# 🚀 DESQEMU Desktop App Generator
# ============================================================================
# Генерирует готовое desktop приложение из Docker Compose файла
# ============================================================================

set -euo pipefail

# Цвета для логов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Параметры
APP_NAME="${1:-}"
COMPOSE_FILE="${2:-}"
APP_DESCRIPTION="${3:-Desktop Application}"
DEFAULT_PORT="${4:-8080}"

if [[ -z "$APP_NAME" || -z "$COMPOSE_FILE" ]]; then
    log_error "Использование: $0 <app-name> <compose-file> [description] [port]"
    log_info "Пример: $0 penpot-desktop docker-compose.yml 'Penpot Design Tool' 9001"
    exit 1
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
    log_error "Docker Compose файл не найден: $COMPOSE_FILE"
    exit 1
fi

# Создание рабочей директории
WORK_DIR="build/desktop-apps"
APP_DIR="$WORK_DIR/$APP_NAME"

log_info "🏗️ Создание desktop приложения: $APP_NAME"
log_info "📁 Рабочая директория: $APP_DIR"

# Очистка и создание директории
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

# Копирование шаблона
log_info "📋 Копирование шаблона Neutralino..."
cp -r templates/neutralino-app/* "$APP_DIR/"

# Определение типа приложения и иконки из compose файла
APP_TYPE=$(grep -E "image:|container_name:" "$COMPOSE_FILE" | head -1 | grep -oE "[a-zA-Z]+" | head -1 || echo "webapp")
APP_ID=$(echo "$APP_NAME" | sed 's/-//g' | tr '[:upper:]' '[:lower:]')
APP_TITLE="DESQEMU Desktop - $(echo "$APP_TYPE" | sed 's/./\U&/')"

log_info "🔧 Конфигурация приложения:"
log_info "   • Название: $APP_NAME"
log_info "   • Тип: $APP_TYPE"
log_info "   • ID: $APP_ID"
log_info "   • Порт: $DEFAULT_PORT"

# Замена плейсхолдеров в файлах
log_info "🔄 Обновление конфигурации..."

# package.json
sed -i.bak \
    -e "s/{{APP_NAME}}/$APP_NAME/g" \
    -e "s/{{APP_DESCRIPTION}}/$APP_DESCRIPTION/g" \
    -e "s/{{APP_TYPE}}/$APP_TYPE/g" \
    "$APP_DIR/package.json" && rm "$APP_DIR/package.json.bak"

# neutralino.config.json
sed -i.bak \
    -e "s/{{APP_NAME}}/$APP_NAME/g" \
    -e "s/{{APP_ID}}/$APP_ID/g" \
    -e "s/{{APP_TYPE}}/$APP_TYPE/g" \
    -e "s/{{APP_TITLE}}/$APP_TITLE/g" \
    -e "s/{{DEFAULT_PORT}}/$DEFAULT_PORT/g" \
    "$APP_DIR/neutralino.config.json" && rm "$APP_DIR/neutralino.config.json.bak"

# Копирование Docker Compose файла
log_info "🐳 Копирование Docker Compose конфигурации..."
cp "$COMPOSE_FILE" "$APP_DIR/resources/docker-compose.yml"

# Создание QCOW2 образа с помощью существующих скриптов
log_info "💿 Создание QCOW2 образа из Docker Compose..."
mkdir -p "$APP_DIR/resources/qcow2"

# Сборка кастомного Docker образа с пользовательским compose файлом
log_info "🐳 Сборка кастомного Alpine образа..."

# Создание временного Dockerfile для этого приложения
cat > "$APP_DIR/Dockerfile" << EOF
# Используем базовый DESQEMU Alpine образ
FROM alpine:3.19

# Установка базовых пакетов
RUN apk add --no-cache \\
    docker \\
    docker-compose \\
    podman \\
    bash \\
    curl \\
    wget

# Копирование Docker Compose конфигурации
COPY resources/docker-compose.yml /app/docker-compose.yml

# Создание скрипта автозапуска
RUN echo '#!/bin/sh' > /usr/local/bin/start-app.sh && \\
    echo 'cd /app' >> /usr/local/bin/start-app.sh && \\
    echo 'docker-compose up -d' >> /usr/local/bin/start-app.sh && \\
    echo 'tail -f /dev/null' >> /usr/local/bin/start-app.sh && \\
    chmod +x /usr/local/bin/start-app.sh

# Запуск приложения при старте контейнера
CMD ["/usr/local/bin/start-app.sh"]
EOF

# Сборка Docker образа
DOCKER_IMAGE="desqemu-$APP_NAME:latest"
if command -v docker >/dev/null 2>&1; then
    log_info "🔨 Сборка Docker образа: $DOCKER_IMAGE"
    cd "$APP_DIR"
    docker build -t "$DOCKER_IMAGE" . >/dev/null 2>&1 || {
        log_warning "⚠️ Не удалось собрать Docker образ, создаем заглушку"
        echo "# QCOW2 будет создан в пайплайне из базового образа" > "resources/qcow2/README.md"
        cd - >/dev/null
        return 0
    }
    cd - >/dev/null

    # Конвертация Docker → QCOW2
    log_info "🔄 Конвертация Docker образа в QCOW2..."
    if [[ -x "scripts/docker-to-qcow2.sh" ]]; then
        chmod +x scripts/docker-to-qcow2.sh
        scripts/docker-to-qcow2.sh "$DOCKER_IMAGE" "$APP_DIR/resources/qcow2/app.qcow2" "4G" || {
            log_warning "⚠️ Конвертация не удалась, создаем заглушку"
            echo "# QCOW2: $DOCKER_IMAGE" > "$APP_DIR/resources/qcow2/README.md"
        }
    else
        log_warning "⚠️ Скрипт docker-to-qcow2.sh не найден"
        echo "# QCOW2: $DOCKER_IMAGE (будет создан в пайплайне)" > "$APP_DIR/resources/qcow2/README.md"
    fi

    # Очистка Docker образа
    docker rmi "$DOCKER_IMAGE" >/dev/null 2>&1 || true
else
    log_warning "⚠️ Docker не установлен, QCOW2 будет создан в пайплайне"
    echo "# QCOW2 будет создан в пайплайне из $COMPOSE_FILE" > "$APP_DIR/resources/qcow2/README.md"
fi

# Обновление HTML интерфейса с правильным названием приложения
log_info "🎨 Обновление интерфейса..."
sed -i.bak \
    -e "s/Penpot Desktop/$APP_DESCRIPTION/g" \
    -e "s/penpot/$APP_TYPE/g" \
    "$APP_DIR/resources/index.html" && rm "$APP_DIR/resources/index.html.bak"

# Создание README для приложения
log_info "📖 Создание документации..."
cat > "$APP_DIR/README.md" << EOF
# 🚀 $APP_NAME

$APP_DESCRIPTION - Desktop приложение на базе DESQEMU & Neutralino.js

## 🏃‍♂️ Быстрый старт

\`\`\`bash
# Запуск в режиме разработки
npm run dev

# Сборка приложения
npm run build

# Создание пакета
npm run package
\`\`\`

## 📁 Структура

- \`resources/\` - Веб-интерфейс приложения
- \`resources/qcow2/\` - QCOW2 образы с приложением
- \`resources/docker-compose.yml\` - Конфигурация сервисов
- \`bin/\` - Neutralino бинарники

## 🔧 Конфигурация

- **Тип**: $APP_TYPE
- **Порт**: $DEFAULT_PORT
- **ID**: $APP_ID

Создано автоматически с помощью DESQEMU Desktop App Generator
EOF

log_success "✅ Desktop приложение создано: $APP_DIR"
log_info "📦 Для сборки перейдите в директорию и запустите: npm run build"
log_info "🚀 Для тестирования: npm run dev"

# Показать размер
APP_SIZE=$(du -sh "$APP_DIR" | cut -f1)
log_success "📊 Размер приложения: $APP_SIZE" 
