#!/bin/bash

# Скрипт для полного перезапуска VNC с правильными настройками

echo "🔄 Полный перезапуск VNC системы"
echo "================================"

# Останавливаем все процессы
echo "🛑 Останавливаем все процессы..."
pkill -f "qemu-system-x86_64" 2>/dev/null || true
pkill -f "novnc_proxy" 2>/dev/null || true
pkill -f "websockify" 2>/dev/null || true
sleep 3

# Проверяем, что порты свободны
echo "📊 Проверяем порты..."
lsof -i :5901 -i :6901 || echo "✅ Порты свободны"

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

# Запускаем noVNC прокси
echo "🌐 Запускаем noVNC прокси..."
./start-novnc-proxy.sh

sleep 2

# Проверяем noVNC
echo "📊 Проверяем noVNC..."
lsof -i :6901

# Тестируем веб-интерфейс
echo "🌐 Тестируем веб-интерфейс..."
curl -s -o /dev/null -w "%{http_code}" http://localhost:6901/vnc.html

if [ $? -eq 0 ]; then
    echo "✅ noVNC веб-интерфейс доступен"
else
    echo "❌ noVNC веб-интерфейс недоступен"
fi

echo ""
echo "🎯 Перезапуск завершен!"
echo "======================="
echo ""
echo "🔗 Доступные интерфейсы:"
echo "   • VNC: localhost:5901"
echo "   • noVNC веб-интерфейс: http://localhost:6901/vnc.html"
echo ""
echo "🧪 Для тестирования в браузере:"
echo "   open http://localhost:6901/vnc.html?host=localhost&port=6901"
echo ""
echo "🛑 Для остановки:"
echo "   pkill -f 'qemu-system-x86_64' && pkill -f novnc_proxy" 
