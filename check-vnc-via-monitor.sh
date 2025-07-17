#!/bin/bash

# Скрипт для проверки VNC через QEMU монитор
# Запускает QEMU с монитором и проверяет состояние VNC

echo "🔍 Проверка VNC через QEMU монитор..."
echo "======================================"

# Останавливаем предыдущие процессы
pkill -f "qemu-system-x86_64" 2>/dev/null || true

# Создаем временный QCOW2 файл для тестирования
TEST_QCOW2="test-vnc-monitor.qcow2"
if [ ! -f "$TEST_QCOW2" ]; then
    echo "📦 Создаем тестовый QCOW2 файл..."
    qemu-img create -f qcow2 "$TEST_QCOW2" 1G
fi

echo "🚀 Запускаем QEMU с монитором..."
echo "💡 Введите команды в мониторе:"
echo "   info vnc"
echo "   info usb"
echo "   info network"
echo "   quit"
echo ""

# Запускаем QEMU с монитором
qemu-system-x86_64 \
    -m 1G \
    -smp 2 \
    -vnc :1,password=on \
    -monitor stdio \
    -drive file="$TEST_QCOW2",format=qcow2,if=virtio

echo ""
echo "✅ Проверка завершена" 
