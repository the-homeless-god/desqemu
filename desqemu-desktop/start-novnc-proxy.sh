#!/bin/bash

# Скрипт для запуска noVNC прокси из Neutralino приложения

# Настройки
VNC_HOST="localhost"
VNC_PORT="5900"
NOVNC_PORT="6900"

echo "🌐 Запуск noVNC прокси..."
echo "=========================="

# Ищем noVNC прокси в разных местах
PROXY_SCRIPT=""
for path in "novnc_proxy" "/usr/bin/novnc_proxy" "resources/js/novnc/utils/novnc_proxy" "/usr/local/bin/novnc_proxy"; do
    if [ -f "$path" ] && [ -x "$path" ]; then
        PROXY_SCRIPT="$path"
        break
    elif command -v "$path" >/dev/null 2>&1; then
        PROXY_SCRIPT="$path"
        break
    fi
done

if [ -z "$PROXY_SCRIPT" ]; then
    echo "❌ noVNC прокси не найден"
    echo "💡 Установите noVNC: apk add novnc websockify"
    exit 1
fi

echo "✅ Найден noVNC прокси: $PROXY_SCRIPT"

# Останавливаем предыдущий прокси
pkill -f "novnc_proxy" 2>/dev/null || true
pkill -f "websockify" 2>/dev/null || true
sleep 1

# Проверяем, что VNC сервер запущен
if ! lsof -i :$VNC_PORT >/dev/null 2>&1; then
    echo "❌ VNC сервер не запущен на порту $VNC_PORT"
    echo "💡 Сначала запустите start-desktop.sh для запуска VNC"
    exit 1
fi

echo "✅ VNC сервер найден на порту $VNC_PORT"

# Запускаем noVNC прокси с веб-сервером
echo "🚀 Запускаем noVNC прокси на порту $NOVNC_PORT..."
cd "$(dirname "$0")/resources/js/novnc"
./utils/novnc_proxy --vnc "$VNC_HOST:$VNC_PORT" --listen "$NOVNC_PORT" --web . &

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
