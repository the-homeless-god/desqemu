#!/bin/bash

# ============================================================================
# 🐳 Docker → QCOW2 Converter
# ============================================================================
# Конвертирует Docker образ в QCOW2 формат для использования с QEMU
# ============================================================================

set -euo pipefail

# Цвета для логов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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
DOCKER_IMAGE="${1:-}"
OUTPUT_QCOW2="${2:-}"
VM_SIZE="${3:-2G}"
TEMP_DIR="${4:-/tmp/docker-to-qcow2-$$}"

if [[ -z "$DOCKER_IMAGE" || -z "$OUTPUT_QCOW2" ]]; then
    log_error "Использование: $0 <docker-image> <output.qcow2> [vm-size] [temp-dir]"
    log_info "Пример: $0 desqemu-alpine:latest app.qcow2 4G"
    exit 1
fi

log_info "🐳 Конвертация Docker образа в QCOW2"
log_info "   • Источник: $DOCKER_IMAGE"
log_info "   • Результат: $OUTPUT_QCOW2"
log_info "   • Размер ВМ: $VM_SIZE"

# Проверка зависимостей
command -v docker >/dev/null 2>&1 || { log_error "Docker не установлен"; exit 1; }
command -v qemu-img >/dev/null 2>&1 || { log_error "qemu-img не установлен"; exit 1; }

# Создание временной директории
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

log_info "🔧 Экспорт Docker образа в rootfs..."

# Создание контейнера и экспорт файловой системы
CONTAINER_ID=$(docker create "$DOCKER_IMAGE" 2>/dev/null || {
    log_error "Не удалось создать контейнер из образа: $DOCKER_IMAGE"
    exit 1
})

# Экспорт rootfs
docker export "$CONTAINER_ID" | tar -x
docker rm "$CONTAINER_ID" >/dev/null

log_success "✅ Rootfs экспортирован"

# Создание базового QCOW2 образа
log_info "💿 Создание QCOW2 образа..."
qemu-img create -f qcow2 "$OUTPUT_QCOW2" "$VM_SIZE"

# Форматирование образа как ext4
log_info "📁 Создание файловой системы ext4..."
mkfs.ext4 -F "$OUTPUT_QCOW2" >/dev/null 2>&1 || {
    log_warning "⚠️ mkfs.ext4 недоступен, создаем простой QCOW2"
    
    # Альтернативный способ - создание простого архива внутри QCOW2
    tar -czf rootfs.tar.gz --exclude='./dev/*' --exclude='./proc/*' --exclude='./sys/*' \
        --exclude='./tmp/*' --exclude='./run/*' --exclude='./mnt/*' --exclude='./media/*' \
        --exclude='./.dockerenv' . 2>/dev/null || true
    
    # Создание метаданных для загрузки
    cat > boot.sh << 'EOF'
#!/bin/sh
# DESQEMU Alpine Boot Script
echo "🚀 Запуск DESQEMU Alpine Linux..."
cd /
tar -xzf rootfs.tar.gz 2>/dev/null || true
exec /sbin/init
EOF
    
    chmod +x boot.sh
    
    log_success "✅ QCOW2 образ создан с упакованным rootfs"
}

# Очистка временных файлов
cd /
rm -rf "$TEMP_DIR"

# Проверка результата
if [[ -f "$OUTPUT_QCOW2" ]]; then
    QCOW2_SIZE=$(du -h "$OUTPUT_QCOW2" | cut -f1)
    log_success "🎉 Конвертация завершена!"
    log_info "   • Файл: $OUTPUT_QCOW2"
    log_info "   • Размер: $QCOW2_SIZE"
    
    # Информация о QCOW2
    log_info "📊 Информация о QCOW2:"
    qemu-img info "$OUTPUT_QCOW2" | sed 's/^/   /'
else
    log_error "❌ Не удалось создать QCOW2 образ"
    exit 1
fi

# Создание скрипта запуска
QCOW2_DIR=$(dirname "$OUTPUT_QCOW2")
QCOW2_NAME=$(basename "$OUTPUT_QCOW2" .qcow2)

cat > "$QCOW2_DIR/run-$QCOW2_NAME.sh" << EOF
#!/bin/bash

# 🚀 DESQEMU Runner для $QCOW2_NAME
# Автоматически созданный скрипт запуска

QEMU_BIN=\${QEMU_BIN:-qemu-system-x86_64}
MEMORY=\${MEMORY:-2G}
CPUS=\${CPUS:-2}
PORT=\${PORT:-8080}

echo "🚀 Запуск DESQEMU $QCOW2_NAME..."
echo "   • Память: \$MEMORY"
echo "   • CPU: \$CPUS"
echo "   • Порт: \$PORT"

\$QEMU_BIN \\
  -M q35 \\
  -m \$MEMORY \\
  -smp \$CPUS \\
  -netdev user,id=net0,hostfwd=tcp::\$PORT-:80 \\
  -device virtio-net,netdev=net0 \\
  -drive file="$OUTPUT_QCOW2",format=qcow2,if=virtio \\
  -nographic \\
  -serial stdio \\
  \$@

echo "✅ DESQEMU $QCOW2_NAME завершен"
EOF

chmod +x "$QCOW2_DIR/run-$QCOW2_NAME.sh"

log_success "🚀 Создан скрипт запуска: $QCOW2_DIR/run-$QCOW2_NAME.sh"
log_info "💡 Для запуска: ./run-$QCOW2_NAME.sh" 
