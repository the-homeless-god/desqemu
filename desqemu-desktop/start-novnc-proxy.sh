#!/bin/bash

# Скрипт для запуска noVNC прокси из Neutralino приложения

NOVNC_DIR="resources/js/novnc"
PROXY_SCRIPT="$NOVNC_DIR/utils/novnc_proxy"
VNC_HOST="localhost"
VNC_PORT="5901"
NOVNC_PORT="6901"

echo "🌐 Запуск noVNC прокси..."
echo "=========================="

# Проверяем наличие noVNC
if [ ! -f "$PROXY_SCRIPT" ]; then
    echo "❌ noVNC прокси не найден: $PROXY_SCRIPT"
    exit 1
fi

# Останавливаем предыдущий прокси
pkill -f "novnc_proxy" 2>/dev/null || true
pkill -f "websockify" 2>/dev/null || true
sleep 1

# Проверяем, что VNC сервер запущен
if ! lsof -i :$VNC_PORT >/dev/null 2>&1; then
    echo "❌ VNC сервер не запущен на порту $VNC_PORT"
    echo "💡 Запустите VM с VNC: ./run-alpine-vm-vnc.sh"
    exit 1
fi

echo "✅ VNC сервер найден на порту $VNC_PORT"

# Запускаем noVNC прокси
echo "🚀 Запускаем noVNC прокси на порту $NOVNC_PORT..."
"$PROXY_SCRIPT" --vnc "$VNC_HOST:$VNC_PORT" --listen "$NOVNC_PORT" &

# Ждем запуска прокси
sleep 2

# Проверяем, что прокси запустился
if lsof -i :$NOVNC_PORT >/dev/null 2>&1; then
    echo "✅ noVNC прокси запущен на порту $NOVNC_PORT"
    echo "🌐 Веб-интерфейс: http://localhost:$NOVNC_PORT"
    echo "🔗 VNC адрес: $VNC_HOST:$VNC_PORT"
else
    echo "❌ Не удалось запустить noVNC прокси"
    exit 1
fi

echo ""
echo "📝 Для остановки:"
echo "   pkill -f novnc_proxy" 
