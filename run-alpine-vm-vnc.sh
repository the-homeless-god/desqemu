#!/bin/bash

# Обновленный скрипт для запуска Alpine VM с VNC
# Учитывает проблемы с паролем VNC

echo "🐧 Запуск Alpine VM с VNC"
echo "========================="

# Останавливаем предыдущие процессы
pkill -f "qemu-system-x86_64" 2>/dev/null || true
pkill -f websockify 2>/dev/null || true
sleep 2

# Проверяем наличие QCOW2 файла
QCOW2_FILE="desqemu-desktop/resources/qcow2/alpine-bootable.qcow2"
if [ ! -f "$QCOW2_FILE" ]; then
    echo "❌ QCOW2 файл не найден: $QCOW2_FILE"
    echo "💡 Создайте образ с помощью: ./install-alpine-to-qcow2.sh"
    exit 1
fi

echo "✅ QCOW2 файл найден: $QCOW2_FILE"

# Запускаем QEMU с VNC (сначала без пароля для тестирования)
echo "🚀 Запускаем QEMU с VNC..."
qemu-system-x86_64 \
    -m 1G \
    -smp 2 \
    -vnc :1 \
    -drive file="$QCOW2_FILE",format=qcow2,if=virtio \
    -daemonize

sleep 3

# Проверяем, что QEMU запустился
QEMU_PID=$(pgrep -f "qemu-system-x86_64")
if [ -z "$QEMU_PID" ]; then
    echo "❌ QEMU не запустился"
    exit 1
fi

echo "✅ QEMU запущен (PID: $QEMU_PID)"

# Проверяем порт VNC
echo "📊 Проверяем VNC порт..."
lsof -i :5901

# Запускаем websockify
echo "🌐 Запускаем websockify..."
websockify 6901 localhost:5901 &
sleep 2

echo "📊 Проверяем websockify порт..."
lsof -i :6901

echo ""
echo "🎯 VM запущена успешно!"
echo "======================="
echo ""
echo "🔗 Способы подключения:"
echo "   1. VNC клиент: localhost:5901 (без пароля)"
echo "   2. Веб-интерфейс: http://localhost:6901"
echo "   3. macOS Screen Sharing: vnc://localhost:5901"
echo ""
echo "🔧 Если нужен пароль VNC:"
echo "   ./setup-vnc-password.sh"
echo ""
echo "🛑 Для остановки:"
echo "   pkill -f 'qemu-system-x86_64' && pkill -f websockify"
echo ""
echo "📝 Если веб-интерфейс не работает:"
echo "   1. Проверьте, что порты 5901 и 6901 свободны"
echo "   2. Попробуйте другой браузер"
echo "   3. Проверьте настройки брандмауэра" 
