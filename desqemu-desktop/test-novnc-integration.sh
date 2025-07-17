#!/bin/bash

# Скрипт для тестирования интеграции noVNC в Neutralino приложение

echo "🧪 Тестирование интеграции noVNC в Neutralino"
echo "=============================================="

# Останавливаем предыдущие процессы
pkill -f "qemu-system-x86_64" 2>/dev/null || true
pkill -f "novnc_proxy" 2>/dev/null || true
sleep 2

# Проверяем наличие noVNC
NOVNC_DIR="resources/js/novnc"
PROXY_SCRIPT="$NOVNC_DIR/utils/novnc_proxy"

if [ ! -f "$PROXY_SCRIPT" ]; then
    echo "❌ noVNC прокси не найден: $PROXY_SCRIPT"
    exit 1
fi

echo "✅ noVNC найден: $PROXY_SCRIPT"

# Запускаем VM с VNC
echo "🚀 Запускаем VM с VNC..."
qemu-system-x86_64 -m 1G -smp 2 -vnc :1 \
    -drive file=resources/qcow2/alpine-bootable.qcow2,format=qcow2,if=virtio \
    -daemonize

sleep 3

# Проверяем, что QEMU запустился
QEMU_PID=$(pgrep -f "qemu-system-x86_64")
if [ -z "$QEMU_PID" ]; then
    echo "❌ QEMU не запустился"
    exit 1
fi

echo "✅ QEMU запущен (PID: $QEMU_PID)"

# Проверяем VNC порт
echo "📊 Проверяем VNC порт..."
lsof -i :5901

# Запускаем noVNC прокси
echo "🌐 Запускаем noVNC прокси..."
"$PROXY_SCRIPT" --vnc localhost:5901 --listen 6901 &
NOVNC_PID=$!

sleep 2

# Проверяем noVNC порт
echo "📊 Проверяем noVNC порт..."
lsof -i :6901

# Тестируем веб-интерфейс
echo "🌐 Тестируем веб-интерфейс noVNC..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:6901

if [ $? -eq 0 ]; then
    echo "✅ noVNC веб-интерфейс доступен"
else
    echo "❌ noVNC веб-интерфейс недоступен"
fi

echo ""
echo "🎯 Тестирование завершено!"
echo "========================"
echo ""
echo "🔗 Доступные интерфейсы:"
echo "   • VNC: localhost:5901"
echo "   • noVNC веб-интерфейс: http://localhost:6901"
echo ""
echo "🧪 Для тестирования Neutralino приложения:"
echo "   cd desqemu-desktop && neu run"
echo ""
echo "🛑 Для остановки:"
echo "   pkill -f 'qemu-system-x86_64' && pkill -f novnc_proxy" 
