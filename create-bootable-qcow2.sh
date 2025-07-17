#!/bin/bash

# Скрипт для создания загружаемого QCOW2 образа с Alpine Linux
# Создает полноценную VM с загружаемой операционной системой

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
OUTPUT_QCOW2="${1:-desqemu-desktop/resources/qcow2/alpine-bootable.qcow2}"
VM_SIZE="${2:-2G}"

log_info "🐧 Создание загружаемого QCOW2 образа с Alpine Linux"
log_info "   • Результат: $OUTPUT_QCOW2"
log_info "   • Размер ВМ: $VM_SIZE"

# Проверка зависимостей
command -v qemu-img >/dev/null 2>&1 || { log_error "qemu-img не установлен"; exit 1; }

# Создание директории
mkdir -p "$(dirname "$OUTPUT_QCOW2")"

log_info "💿 Создание QCOW2 образа..."
qemu-img create -f qcow2 "$OUTPUT_QCOW2" "$VM_SIZE"

log_info "📥 Скачивание Alpine Linux ISO..."
ALPINE_ISO="/tmp/alpine-standard-3.22.0-x86_64.iso"
if [ ! -f "$ALPINE_ISO" ]; then
    curl -L -o "$ALPINE_ISO" "https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86_64/alpine-standard-3.22.0-x86_64.iso"
fi

log_info "🔧 Установка Alpine Linux в QCOW2..."
# Создаем скрипт автоматической установки
cat > /tmp/alpine-auto-install.exp << 'EOF'
#!/usr/bin/expect -f
set timeout -1
spawn qemu-system-x86_64 -m 1G -smp 2 -drive file=OUTPUT_QCOW2,format=qcow2 -cdrom ALPINE_ISO -boot d -nographic -serial stdio
expect "login:"
send "root\r"
expect "#"
send "setup-alpine\r"
expect "Enter system hostname"
send "desqemu\r"
expect "Which one do you want to initialize?"
send "eth0\r"
expect "Ip address for eth0?"
send "dhcp\r"
expect "Do you want to do any manual network configuration?"
send "n\r"
expect "New password:"
send "desqemu\r"
expect "Retype new password:"
send "desqemu\r"
expect "Which timezone are you in?"
send "UTC\r"
expect "HTTP/FTP proxy URL?"
send "\r"
expect "Enter mirror number (1-50) or URL to add"
send "1\r"
expect "Setup a user?"
send "no\r"
expect "Which ssh server?"
send "openssh\r"
expect "Which disk(s) would you like to use?"
send "sda\r"
expect "How would you like to use it?"
send "sys\r"
expect "WARNING: Erase the above disk(s) and continue?"
send "y\r"
expect "Enter where to store configs"
send "floppy\r"
expect "Enter apk cache directory"
send "\r"
expect "WARNING: Reboot required"
send "y\r"
expect eof
EOF

# Заменяем плейсхолдеры в скрипте
sed -i.bak "s|OUTPUT_QCOW2|$OUTPUT_QCOW2|g" /tmp/alpine-auto-install.exp
sed -i.bak "s|ALPINE_ISO|$ALPINE_ISO|g" /tmp/alpine-auto-install.exp

log_info "🚀 Запуск автоматической установки Alpine Linux..."
chmod +x /tmp/alpine-auto-install.exp

# Проверяем, есть ли expect
if command -v expect >/dev/null 2>&1; then
    /tmp/alpine-auto-install.exp
    log_success "✅ Alpine Linux установлен"
else
    log_warning "⚠️ expect не установлен, установка вручную"
    log_info "💡 Установите expect: brew install expect"
    log_info "💡 Или запустите установку вручную:"
    echo "qemu-system-x86_64 -m 1G -smp 2 -drive file=$OUTPUT_QCOW2,format=qcow2 -cdrom $ALPINE_ISO -boot d"
fi

# Очистка
rm -f /tmp/alpine-auto-install.exp*

# Проверка результата
if [[ -f "$OUTPUT_QCOW2" ]]; then
    QCOW2_SIZE=$(du -h "$OUTPUT_QCOW2" | cut -f1)
    log_success "🎉 Загружаемый QCOW2 образ создан!"
    log_info "   • Файл: $OUTPUT_QCOW2"
    log_info "   • Размер: $QCOW2_SIZE"
    
    # Информация о QCOW2
    log_info "📊 Информация о QCOW2:"
    qemu-img info "$OUTPUT_QCOW2" | sed 's/^/   /'
    
    log_info "🚀 Для тестирования:"
    echo "qemu-system-x86_64 -m 1G -smp 2 -drive file=$OUTPUT_QCOW2,format=qcow2 -nographic"
else
    log_error "❌ Не удалось создать QCOW2 образ"
    exit 1
fi 
