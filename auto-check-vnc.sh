#!/bin/bash

# Автоматизированная проверка VNC через QEMU монитор
# Использует expect для автоматического взаимодействия с монитором

echo "🤖 Автоматическая проверка VNC через QEMU монитор..."
echo "=================================================="

# Проверяем наличие expect
if ! command -v expect >/dev/null 2>&1; then
    echo "❌ expect не установлен. Установите: brew install expect"
    exit 1
fi

# Останавливаем предыдущие процессы
pkill -f "qemu-system-x86_64" 2>/dev/null || true

# Создаем временный QCOW2 файл
TEST_QCOW2="test-vnc-auto.qcow2"
if [ ! -f "$TEST_QCOW2" ]; then
    echo "📦 Создаем тестовый QCOW2 файл..."
    qemu-img create -f qcow2 "$TEST_QCOW2" 1G
fi

# Создаем expect скрипт
cat > /tmp/check_vnc.exp << 'EOF'
#!/usr/bin/expect -f

set timeout 10

# Запускаем QEMU
spawn qemu-system-x86_64 -m 1G -smp 2 -vnc :1,password=on -monitor stdio -drive file=test-vnc-auto.qcow2,format=qcow2,if=virtio

# Ждем появления монитора
expect "QEMU 10.0.2 monitor - type 'help' for more information"
expect "(qemu)"

# Проверяем информацию о VNC
send "info vnc\r"
expect "(qemu)"

# Проверяем информацию о сети
send "info network\r"
expect "(qemu)"

# Проверяем информацию о USB
send "info usb\r"
expect "(qemu)"

# Проверяем информацию о дисках
send "info block\r"
expect "(qemu)"

# Проверяем информацию о мониторах
send "info mtree\r"
expect "(qemu)"

# Выходим
send "quit\r"
expect eof
EOF

echo "🚀 Запускаем автоматическую проверку..."
chmod +x /tmp/check_vnc.exp
/tmp/check_vnc.exp

echo ""
echo "✅ Автоматическая проверка завершена"
echo "📋 Результаты выше показывают состояние VNC и других компонентов" 
