#!/bin/bash

# Настройка X11 окружения
export DISPLAY=:1

echo "🖥️ Запуск X11 окружения..."

# Запуск виртуального X-сервера с большим разрешением
Xvfb :1 -screen 0 1280x800x24 -ac &
sleep 3

# Запуск оконного менеджера
echo "🎨 Запуск оконного менеджера fluxbox..."
fluxbox &
sleep 2

# Запуск Chromium в полноэкранном режиме
echo "🌐 Запуск Chromium в полноэкранном режиме..."
chromium --no-sandbox \
         --disable-gpu \
         --disable-dev-shm-usage \
         --disable-web-security \
         --disable-features=VizDisplayCompositor \
         --kiosk \
         --start-maximized \
         --app="http://localhost:8080" &
sleep 2

# Запуск VNC сервера
echo "📺 Запуск VNC сервера..."
x11vnc -display :1 \
        -forever \
        -usepw \
        -create \
        -shared \
        -rfbport 5900 \
        -passwd desqemu &
sleep 1

echo "✅ Рабочий стол запущен на display :1"
echo "🌐 VNC доступен на порту 5900 (пароль: desqemu)"
echo "🔗 Chromium открыт в полноэкранном режиме на http://localhost:8080"

# Держим скрипт активным
while true; do
    sleep 10
    # Проверяем, что Xvfb и fluxbox еще работают
    if ! pgrep -x "Xvfb" > /dev/null; then
        echo "❌ Xvfb остановлен, перезапуск..."
        Xvfb :1 -screen 0 1280x800x24 -ac &
        sleep 2
    fi
    if ! pgrep -x "fluxbox" > /dev/null; then
        echo "❌ fluxbox остановлен, перезапуск..."
        fluxbox &
        sleep 1
    fi
done 
