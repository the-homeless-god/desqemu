#!/bin/bash

# Простой скрипт для установки Alpine Linux в QCOW2 образ
# Запускает установку Alpine Linux в интерактивном режиме

echo "🐧 Установка Alpine Linux в QCOW2 образ..."
echo "=========================================="

QCOW2_FILE="desqemu-desktop/resources/qcow2/alpine-bootable.qcow2"
ALPINE_ISO="/tmp/alpine-standard-3.22.0-x86_64.iso"

if [ ! -f "$ALPINE_ISO" ]; then
    echo "❌ Alpine Linux ISO не найден: $ALPINE_ISO"
    echo "💡 Скачайте ISO: curl -L -o $ALPINE_ISO https://dl-cdn.alpinelinux.org/alpine/v3.22/releases/x86_64/alpine-standard-3.22.0-x86_64.iso"
    exit 1
fi

if [ ! -f "$QCOW2_FILE" ]; then
    echo "❌ QCOW2 файл не найден: $QCOW2_FILE"
    echo "💡 Создайте QCOW2: qemu-img create -f qcow2 $QCOW2_FILE 2G"
    exit 1
fi

echo "✅ Alpine Linux ISO найден: $ALPINE_ISO"
echo "✅ QCOW2 файл найден: $QCOW2_FILE"
echo ""
echo "🚀 Запускаем установку Alpine Linux..."
echo "💡 Следуйте инструкциям на экране:"
echo "   • Hostname: desqemu"
echo "   • Network: eth0, DHCP"
echo "   • Password: desqemu"
echo "   • Timezone: UTC"
echo "   • Mirror: 1 (по умолчанию)"
echo "   • User: нет"
echo "   • SSH: openssh"
echo "   • Disk: sda, sys"
echo "   • Config: floppy"
echo ""
echo "⏳ Запуск QEMU с Alpine Linux ISO..."

qemu-system-x86_64 \
    -m 1G \
    -smp 2 \
    -drive file="$QCOW2_FILE",format=qcow2 \
    -cdrom "$ALPINE_ISO" \
    -boot d \
    -nographic

echo ""
echo "✅ Установка завершена!"
echo "🚀 Для тестирования:"
echo "qemu-system-x86_64 -m 1G -smp 2 -drive file=$QCOW2_FILE,format=qcow2 -nographic" 
