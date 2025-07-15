#!/bin/bash

echo "🐳 DESQEMU Auto-Start Compose Service"
echo "====================================="

COMPOSE_FILE="/home/desqemu/docker-compose.yml"
BROWSER_PORT="8080"
WAIT_TIMEOUT=300

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ docker-compose.yml не найден в /home/desqemu/"
    echo "📝 Создайте docker-compose.yml файл и перезапустите систему"
    exit 1
fi

echo "📋 Анализируем docker-compose.yml..."

# Extract all exposed ports from docker-compose.yml
# Извлекаем все открытые порты из docker-compose.yml
PORTS=$(yq eval '.services[].ports[]' "$COMPOSE_FILE" 2>/dev/null | grep -o '[0-9]\+:[0-9]\+' | cut -d: -f2 | sort -u)

if [ -z "$PORTS" ]; then
    echo "⚠️  Порт не найден в docker-compose.yml, используем порт по умолчанию: 8080"
    PORTS="8080"
fi

echo "🔍 Найденные порты: $PORTS"

# Start the compose stack
# Запускаем стек compose
echo "🚀 Запускаем Docker Compose..."
cd /home/desqemu
# Use docker-compose since we're inside a container
# Используем docker-compose так как мы внутри контейнера
docker-compose up -d

# Wait for services to be ready
# Ждем готовности сервисов
echo "⏳ Ждем готовности сервисов (максимум ${WAIT_TIMEOUT}с)..."

for port in $PORTS; do
    echo "🔍 Проверяем порт $port..."
    timeout $WAIT_TIMEOUT bash -c "until nc -z localhost $port; do sleep 2; done"
    if [ $? -eq 0 ]; then
        echo "✅ Порт $port готов!"
        BROWSER_PORT=$port
        break
    fi
done

# Start X11 environment
# Запускаем X11 окружение
echo "🖥️  Запускаем графическое окружение..."
export DISPLAY=:1
Xvfb :1 -screen 0 1024x768x16 &
sleep 2
fluxbox &
x11vnc -display :1 -forever -usepw -create &

echo "🖥️  Рабочий стол запущен на display :1"
echo "🌐 VNC доступен на порту 5900 (пароль: desqemu)"
# Wait a bit for X11 to be ready
sleep 3

# Start browser with the detected port
# Запускаем браузер с обнаруженным портом
echo "🌐 Запускаем Chromium на порту $BROWSER_PORT..."
chromium --no-sandbox --disable-dev-shm-usage \
  --disable-web-security --disable-features=VizDisplayCompositor \
  --remote-debugging-port=9222 \
  "http://localhost:$BROWSER_PORT" &

echo "✅ DESQEMU готов! Приложение доступно на http://localhost:$BROWSER_PORT"
echo "🖥️  VNC доступен на порту 5900 (пароль: desqemu)"

# Keep the script running to maintain the session
# Держим скрипт запущенным для поддержания сессии
while true; do
    sleep 10
    # Check if compose services are still running
    if ! docker-compose ps | grep -q "Up"; then
        echo "⚠️  Один из сервисов остановился"
        break
    fi
done 
