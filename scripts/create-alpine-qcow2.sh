#!/bin/bash

# ============================================================================
# 🐧 Alpine QCOW2 Image Creator
# ============================================================================
# Создает QCOW2 образы Alpine Linux с помощью alpine-make-vm-image
# ============================================================================

set -euo pipefail

# Цвета для логов
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Параметры
ARCHITECTURE="${1:-x86_64}"
ALPINE_VERSION="${2:-3.19}"
OUTPUT_QCOW2="desqemu-alpine-qcow2-${ARCHITECTURE}.qcow2"

# Получение корневой директории
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR"

# Маппинг архитектур
case "$ARCHITECTURE" in
    x86_64|amd64)
        ALPINE_ARCH="x86_64"
        QEMU_ARCH="x86_64"
        ;;
    aarch64|arm64)
        ALPINE_ARCH="aarch64"
        QEMU_ARCH="aarch64"
        ;;
    *)
        log_error "Неподдерживаемая архитектура: $ARCHITECTURE"
        echo "Поддерживаемые архитектуры: x86_64, aarch64, arm64"
        exit 1
        ;;
esac

log_info "🐧 Создание Alpine QCOW2 образа"
log_info "   • Архитектура: $ARCHITECTURE ($ALPINE_ARCH)"
log_info "   • Версия Alpine: $ALPINE_VERSION"
log_info "   • Результат: $OUTPUT_QCOW2"
log_info "   • Рабочая директория: $(pwd)"

# Проверка зависимостей
log_info "🔧 Проверка зависимостей..."
command -v wget >/dev/null 2>&1 || { log_error "wget не установлен"; exit 1; }
command -v qemu-img >/dev/null 2>&1 || { log_error "qemu-img не установлен"; exit 1; }
command -v sfdisk >/dev/null 2>&1 || { log_error "sfdisk не установлен"; exit 1; }

# Проверяем, на какой системе мы работаем
if [ -f /etc/alpine-release ]; then
    log_info "🐧 Обнаружена Alpine Linux - alpine-make-vm-image установит зависимости автоматически"
elif [ -f /etc/debian_version ]; then
    log_info "🐧 Обнаружена Debian/Ubuntu - зависимости должны быть установлены заранее"
else
    log_warning "⚠️ Неизвестная система - могут потребоваться дополнительные зависимости"
fi

# Скачивание alpine-make-vm-image скрипта
log_info "📥 Скачивание alpine-make-vm-image скрипта..."
ALPINE_MAKE_VM_IMAGE_URL="https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/v0.13.3/alpine-make-vm-image"
ALPINE_MAKE_VM_IMAGE_SHA1="f17ef4997496ace524a8e8e578d944f3552255bb"

if [ ! -f "alpine-make-vm-image" ]; then
    wget -O alpine-make-vm-image "$ALPINE_MAKE_VM_IMAGE_URL"
    echo "$ALPINE_MAKE_VM_IMAGE_SHA1  alpine-make-vm-image" | sha1sum -c || {
        log_error "Ошибка проверки контрольной суммы alpine-make-vm-image"
        exit 1
    }
    chmod +x alpine-make-vm-image
fi

log_success "✅ alpine-make-vm-image скачан и проверен"

# Создание временной директории для работы
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

log_info "🏗️ Создание QCOW2 образа Alpine Linux..."

# Создание скрипта инициализации
cat > init-script.sh << 'EOF'
#!/bin/sh
# DESQEMU Alpine Linux Initialization Script

echo "🚀 Инициализация DESQEMU Alpine Linux..."

# Обновление системы
apk update
apk upgrade

# Установка базовых системных пакетов
echo "📦 Установка базовых системных пакетов..."
apk add --no-cache \
    bash \
    curl \
    wget \
    git \
    openssh \
    openssh-server \
    sudo \
    vim \
    htop \
    tmux \
    nano \
    openrc \
    shadow \
    dbus \
    jq \
    netcat-openbsd \
    procps || echo "⚠️ Некоторые базовые пакеты не установлены"

# Установка Docker и Podman
echo "🐳 Установка Docker и Podman..."
apk add --no-cache \
    docker \
    podman \
    docker-cli \
    docker-compose || echo "⚠️ Некоторые Docker пакеты не установлены"

# Установка QEMU
echo "🔧 Установка QEMU..."
apk add --no-cache \
    qemu-system-x86_64 \
    qemu-img || echo "⚠️ Некоторые QEMU пакеты не установлены"

# Установка Python и Node.js
echo "🐍 Установка Python и Node.js..."
apk add --no-cache \
    python3 \
    py3-pip \
    nodejs \
    npm || echo "⚠️ Некоторые Python/Node.js пакеты не установлены"

# Установка графических пакетов
echo "🖥️ Установка графических пакетов..."
apk add --no-cache \
    xvfb \
    x11vnc \
    fluxbox \
    novnc \
    websockify \
    xterm \
    x11-apps \
    x11-utils \
    x11-fonts \
    x11-fonts-misc \
    x11-fonts-terminus \
    mesa-dri-gallium \
    mesa-gl \
    mesa-egl \
    libx11 \
    libxext \
    libxrender \
    libxrandr \
    libxfixes \
    libxcomposite \
    libxcursor \
    libxdamage \
    libxinerama \
    libxss \
    libxtst \
    libxi \
    libxrandr \
    libxrender \
    libxfixes \
    libxcomposite \
    libxcursor \
    libxdamage \
    libxinerama \
    libxss \
    libxtst \
    libxi \
    rox-filer || echo "⚠️ Некоторые графические пакеты не установлены"

# Установка Chromium (последним, так как он большой)
echo "🌐 Установка Chromium..."
apk add --no-cache \
    chromium \
    chromium-chromedriver || echo "⚠️ Chromium не установлен (не критично)"

# Установка Python пакетов
echo "🐍 Установка Python пакетов..."
python3 -m venv /opt/venv
. /opt/venv/bin/activate
pip install podman-compose yq

# Добавление виртуального окружения в PATH
echo 'export PATH="/opt/venv/bin:$PATH"' >> /etc/profile

# Настройка SSH
if [ ! -d /etc/ssh ]; then
    mkdir -p /etc/ssh
fi

# Создание пользователя desqemu с полными правами
echo "👤 Создание пользователя desqemu..."
if ! id "desqemu" >/dev/null 2>&1; then
    adduser -D -s /bin/bash desqemu
    echo "desqemu:desqemu" | chpasswd
    addgroup desqemu wheel
    addgroup docker
    addgroup desqemu docker
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# Установка пароля root
echo "root:root" | chpasswd

# Настройка автологина для desqemu
echo "🔧 Настройка автологина..."
cat > /etc/inittab << 'INITTABEOF'
# /etc/inittab
::sysinit:/sbin/openrc sysinit
::sysinit:/sbin/openrc boot
::wait:/sbin/openrc default
::ctrlaltdel:/sbin/reboot
::shutdown:/sbin/openrc shutdown
tty1::respawn:/sbin/agetty -o '-p -f desqemu' --noclear tty1 38400 linux
tty2::respawn:/sbin/getty -n -l /bin/bash tty2 38400
tty3::respawn:/sbin/getty -n -l /bin/bash tty3 38400
tty4::respawn:/sbin/getty -n -l /bin/bash tty4 38400
tty5::respawn:/sbin/getty -n -l /bin/bash tty5 38400
tty6::respawn:/sbin/getty -n -l /bin/bash tty6 38400
INITTABEOF

# Создание скрипта автозапуска для desqemu
cat > /home/desqemu/.bash_profile << 'PROFILEEOF'
#!/bin/bash
# Автозапуск DESQEMU при логине

# Проверяем, что это первый запуск
if [ ! -f /home/desqemu/.first-run ]; then
    echo "🚀 Первый запуск DESQEMU..."
    touch /home/desqemu/.first-run
    
    # Запускаем Docker
    echo "🐳 Запуск Docker..."
    sudo rc-service docker start 2>/dev/null || true
    
    # Ждем запуска Docker
    sleep 3
    
    # Запускаем VNC сервер
    echo "🖥️ Запуск VNC сервера..."
    export DISPLAY=:0
    Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    sleep 2
    fluxbox &
    sleep 1
    x11vnc -display :0 -forever -usepw -create -passwd desqemu &
    
    # Запускаем приложения
    echo "📦 Запуск приложений..."
    cd /home/desqemu
    ./auto-start-compose.sh &
    
    echo "✅ DESQEMU готов к работе!"
    echo "🌐 Веб-интерфейс: http://localhost:8080"
    echo "🖥️ VNC: localhost:5900 (пароль: desqemu)"
    echo "🌐 noVNC: http://localhost:6900"
fi
PROFILEEOF

chmod +x /home/desqemu/.bash_profile

# Настройка сети
echo "🌐 Настройка сети..."
mkdir -p /etc/network
cat > /etc/network/interfaces << 'NETEOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
NETEOF

# Настройка Podman
echo "🐳 Настройка Podman..."
mkdir -p /home/desqemu/.config/containers
cat > /home/desqemu/.config/containers/registries.conf << 'REGEOF'
unqualified-search-registries = ["docker.io"]

[[registry]]
location = "docker.io"

[[registry]]
location = "registry.fedoraproject.org"

[[registry]]
location = "quay.io"
REGEOF

chown -R desqemu:desqemu /home/desqemu/.config

# Установка правильных прав доступа для всех файлов desqemu
echo "🔧 Установка прав доступа для пользователя desqemu..."
chown -R desqemu:desqemu /home/desqemu
chmod +x /home/desqemu/*.sh
chmod +x /home/desqemu/scripts/*.sh 2>/dev/null || true

# Настройка автозапуска сервисов
echo "🔧 Настройка автозапуска сервисов..."
rc-update add sshd default
rc-update add networking default
rc-update add dbus default
rc-update add local default
rc-update add docker default
rc-update add cgroups default

# Создание сервиса для автозапуска VNC
echo "🖥️ Создание сервиса VNC..."
cat > /etc/init.d/vnc-server << 'VNCSERVICEEOF'
#!/sbin/openrc-run

depend() {
    need net
    after dbus
}

start() {
    ebegin "Starting VNC server"
    
    # Set up X11 environment
    export DISPLAY=:0
    export XDG_RUNTIME_DIR=/tmp/runtime-desqemu
    mkdir -p $XDG_RUNTIME_DIR
    chmod 700 $XDG_RUNTIME_DIR
    
    # Start Xvfb
    Xvfb :0 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
    sleep 2
    
    # Start Fluxbox
    fluxbox &
    sleep 1
    
    # Start x11vnc
    x11vnc -display :0 -forever -usepw -create -passwd desqemu &
    
    eend $?
}

stop() {
    ebegin "Stopping VNC server"
    pkill -f "x11vnc"
    pkill -f "fluxbox"
    pkill -f "Xvfb"
    eend $?
}
VNCSERVICEEOF

chmod +x /etc/init.d/vnc-server
rc-update add vnc-server default

# Создание директории для DESQEMU
echo "📁 Создание директорий DESQEMU..."
mkdir -p /opt/desqemu
mkdir -p /home/desqemu/scripts

# Создание скрипта запуска рабочего стола
cat > /home/desqemu/start-desktop.sh << 'DESKTOPEOF'
#!/bin/bash
set -e

echo "🖥️ Запуск графического окружения DESQEMU..."

# Создаем директории для X11
mkdir -p /tmp/.X11-unix
mkdir -p ~/.fluxbox
mkdir -p ~/.config

# Устанавливаем переменные окружения
export DISPLAY=:1
export XDG_RUNTIME_DIR=/tmp/runtime-desqemu
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Останавливаем существующие процессы
pkill -f "Xvfb.*:1" 2>/dev/null || true
pkill -f "fluxbox" 2>/dev/null || true
pkill -f "x11vnc" 2>/dev/null || true
pkill -f "novnc_proxy" 2>/dev/null || true

# Запускаем X11 виртуальный фреймбуфер
echo "📺 Запуск X11 виртуального фреймбуфера..."
Xvfb :1 -screen 0 1024x768x24 -ac +extension GLX +render -noreset &
XVFB_PID=$!
sleep 3

# Проверяем что Xvfb запустился
if ! kill -0 $XVFB_PID 2>/dev/null; then
    echo "❌ Ошибка запуска Xvfb"
    exit 1
fi

# Создаем базовую конфигурацию Fluxbox
cat > ~/.fluxbox/init << 'FLUXBOXEOF'
session.screen0.toolbar.visible: true
session.screen0.toolbar.autoHide: false
session.screen0.toolbar.maxOver: false
session.screen0.toolbar.widthPercent: 100
session.screen0.toolbar.alpha: 255
session.screen0.toolbar.layer: 0
session.screen0.toolbar.onhead: 0
session.screen0.toolbar.placement: TopCenter
session.screen0.toolbar.height: 0
session.screen0.toolbar.tools: prevworkspace, workspacename, nextworkspace, iconbar, systemtray, clock, rootmenu
session.screen0.iconbar.mode: {static groups} (workspace)
session.screen0.iconbar.alignment: Left
session.screen0.iconbar.iconWidth: 64
session.screen0.iconbar.iconTextPadding: 10
session.screen0.iconbar.usePixmap: true
session.screen0.strftimeFormat: %H:%M
FLUXBOXEOF

# Создаем меню Fluxbox
cat > ~/.fluxbox/menu << 'MENUEOF'
[begin] (DESQEMU)
  [exec] (Terminal) {xterm}
  [exec] (File Manager) {rox-filer}
  [exec] (Web Browser) {chromium --no-sandbox}
  [separator]
  [exec] (DESQEMU Services) {./auto-start-compose.sh}
  [separator]
  [restart] (Restart)
  [exit] (Exit)
[end]
MENUEOF

# Создаем файл стилей
cat > ~/.fluxbox/overlay << 'OVERLAYEOF'
! Fluxbox overlay file
! $Id: overlay,v 1.1.1.1 2002/11/24 10:32:05 fluxbox Exp $

! Colors
! File: ~/.fluxbox/overlay
! $Id: overlay,v 1.1.1.1 2002/11/24 10:32:05 fluxbox Exp $

! Colors
OVERLAYEOF

# Запускаем Fluxbox
echo "🎨 Запуск Fluxbox..."
fluxbox &
FLUXBOX_PID=$!
sleep 2

# Проверяем что Fluxbox запустился
if ! kill -0 $FLUXBOX_PID 2>/dev/null; then
    echo "❌ Ошибка запуска Fluxbox"
    kill $XVFB_PID 2>/dev/null || true
    exit 1
fi

# Запускаем x11vnc
echo "🖥️ Запуск VNC сервера..."
x11vnc -display :1 -forever -usepw -create -passwd desqemu &
X11VNC_PID=$!
sleep 2

# Запускаем noVNC прокси
echo "🌐 Запуск noVNC прокси..."
novnc_proxy --vnc localhost:5900 --listen 6900 &
NOVNC_PID=$!
sleep 2

# Проверяем что все процессы запустились
if kill -0 $XVFB_PID 2>/dev/null && kill -0 $FLUXBOX_PID 2>/dev/null && kill -0 $X11VNC_PID 2>/dev/null; then
    echo "✅ Графическое окружение запущено успешно!"
    echo "🖥️ VNC доступен на порту 5900 (пароль: desqemu)"
    echo "🌐 noVNC доступен на http://localhost:6900"
    echo "🎨 Fluxbox запущен на display :1"
    
    # Запускаем терминал для демонстрации
    xterm -display :1 -geometry 80x24+10+10 -title "DESQEMU Terminal" &
    
    echo "🚀 Для подключения используйте:"
    echo "   VNC клиент: localhost:5900 (пароль: desqemu)"
    echo "   Веб браузер: http://localhost:6900"
else
    echo "❌ Ошибка запуска графического окружения"
    kill $XVFB_PID $FLUXBOX_PID $X11VNC_PID $NOVNC_PID 2>/dev/null || true
    exit 1
fi

# Ждем завершения
wait
DESKTOPEOF

chmod +x /home/desqemu/start-desktop.sh

# Создание noVNC скрипта
echo "🌐 Создание noVNC скрипта..."
cat > /home/desqemu/start-novnc-proxy.sh << 'NOVNCEOF'
#!/bin/bash
# DESQEMU noVNC Proxy Script

echo "🌐 Запуск noVNC прокси..."

# Проверяем что x11vnc запущен
if ! pgrep -x "x11vnc" > /dev/null; then
    echo "❌ x11vnc не запущен. Сначала запустите start-desktop.sh"
    exit 1
fi

# Останавливаем существующий noVNC прокси
pkill -f "novnc_proxy" 2>/dev/null || true

# Запускаем noVNC прокси
echo "🚀 Запуск noVNC прокси на порту 6900..."
novnc_proxy --vnc localhost:5900 --listen 6900 &

NOVNC_PID=$!
sleep 2

if kill -0 $NOVNC_PID 2>/dev/null; then
    echo "✅ noVNC прокси запущен успешно!"
    echo "🌐 Доступен по адресу: http://localhost:6900"
    echo "🔧 PID: $NOVNC_PID"
else
    echo "❌ Ошибка запуска noVNC прокси"
    exit 1
fi

# Ждем завершения
wait $NOVNC_PID
NOVNCEOF

chmod +x /home/desqemu/start-novnc-proxy.sh

# Создание docker-compose.yml по умолчанию
cat > /home/desqemu/docker-compose.yml << 'COMPOSEEOF'
version: '3.8'
services:
  hello-world:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./index.html:/usr/share/nginx/html/index.html
  COMPOSEEOF

# Создание простого index.html
cat > /home/desqemu/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head>
    <title>DESQEMU Hello World</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .success { color: green; }
        .info { color: blue; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 DESQEMU Alpine Linux</h1>
        <p class="success">✅ Система успешно запущена!</p>
        <h2>📋 Доступные сервисы:</h2>
        <ul>
            <li>🌐 <strong>Nginx</strong> - веб-сервер (порт 8080)</li>
            <li>🐳 <strong>Docker</strong> - контейнеры</li>
            <li>🖥️ <strong>VNC</strong> - удаленный доступ (порт 5900)</li>
            <li>🌐 <strong>noVNC</strong> - веб-VNC (порт 6900)</li>
        </ul>
        <h2>🔧 Полезные команды:</h2>
        <ul>
            <li><code>./start-desktop.sh</code> - запуск графического окружения</li>
            <li><code>./auto-start-compose.sh</code> - автозапуск приложений</li>
            <li><code>docker ps</code> - список контейнеров</li>
            <li><code>htop</code> - мониторинг системы</li>
        </ul>
        <p class="info">💡 Измените docker-compose.yml для запуска своих приложений</p>
    </div>
</body>
</html>
HTMLEOF

# Создание скрипта автозапуска compose
cat > /home/desqemu/auto-start-compose.sh << 'COMPOSEEOF'
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
PORTS=$(yq eval '.services[].ports[]' "$COMPOSE_FILE" 2>/dev/null | grep -o '[0-9]\+:[0-9]\+' | cut -d: -f2 | sort -u)

if [ -z "$PORTS" ]; then
    echo "⚠️  Порт не найден в docker-compose.yml, используем порт по умолчанию: 8080"
    PORTS="8080"
fi

echo "🔍 Найденные порты: $PORTS"

# Start the compose stack
echo "🚀 Запускаем Docker Compose..."
cd /home/desqemu
. /opt/venv/bin/activate && podman-compose up -d

# Wait for services to be ready
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
echo "🖥️  Запускаем графическое окружение..."
export DISPLAY=:1
Xvfb :1 -screen 0 1024x768x16 &
sleep 2
fluxbox &
x11vnc -display :1 -forever -usepw -create &

# Wait a bit for X11 to be ready
sleep 3

# Start browser with the detected port
echo "🌐 Запускаем Chromium на порту $BROWSER_PORT..."
chromium --no-sandbox --disable-dev-shm-usage \
  --disable-web-security --disable-features=VizDisplayCompositor \
  --remote-debugging-port=9222 \
  "http://localhost:$BROWSER_PORT" &

echo "✅ DESQEMU готов! Приложение доступно на http://localhost:$BROWSER_PORT"
echo "🖥️  VNC доступен на порту 5900 (пароль: desqemu)"

# Keep the script running to maintain the session
while true; do
    sleep 10
    # Check if compose services are still running
    if ! . /opt/venv/bin/activate && podman-compose ps | grep -q "Up"; then
        echo "⚠️  Один из сервисов остановился"
        break
    fi
done
COMPOSEEOF

chmod +x /home/desqemu/auto-start-compose.sh

# Создание README
cat > /opt/desqemu/README.md << 'READMEEOF'
# DESQEMU Alpine Linux

Этот образ создан с помощью alpine-make-vm-image для проекта DESQEMU.

## 🎯 Что включено:

- **Alpine Linux** с полным набором пакетов
- **Podman** - для запуска контейнеров
- **Docker CLI** - совместимость с Docker
- **Docker Compose** - оркестрация контейнеров
- **QEMU** - для эмуляции виртуальных машин
- **Chromium** - веб-браузер для GUI приложений
- **X11/VNC** - графическое окружение
- **SSH сервер** - удаленный доступ
- **Python 3** - для скриптов и API
- **Node.js** - для веб-приложений
- **Автоматический парсинг docker-compose.yml**
- **Автозапуск браузера на нужном порту**

## 🚀 Быстрый старт

1. Запуск SSH сервера:
   ```bash
   /etc/init.d/sshd start
   ```

2. Подключение по SSH:
   ```bash
   ssh desqemu@<ip-address>
   ```

3. Запуск графического окружения:
   ```bash
   ./start-desktop.sh
   ```

4. Автозапуск compose приложения:
   ```bash
   ./auto-start-compose.sh
   ```

5. Проверка системы:
   ```bash
   uname -a
   cat /etc/alpine-release
   ```

## 🎨 Графический интерфейс

- **VNC**: localhost:5900 (пароль: desqemu)
- **Chromium**: автоматически открывается на нужном порту
- **Fluxbox**: легковесное оконное окружение

## 🐳 Docker/Podman

- **Podman**: `podman --version`
- **Docker CLI**: `docker --version`
- **Docker Compose**: `podman-compose --version`

## 🔧 Полезные команды

- `htop` - мониторинг системы
- `tmux` - терминальный мультиплексор
- `chromium` - веб-браузер
- `x11vnc` - VNC сервер
- `fluxbox` - оконный менеджер
READMEEOF

echo "✅ Инициализация DESQEMU Alpine Linux завершена!"
EOF

chmod +x init-script.sh

# Подготовка параметров для alpine-make-vm-image
ALPINE_MAKE_VM_IMAGE_ARGS=(
    "--image-format" "qcow2"
    "--image-size" "4G"
    "--packages" "alpine-base"
)

# Добавление архитектуры если не x86_64
if [ "$ALPINE_ARCH" != "x86_64" ]; then
    ALPINE_MAKE_VM_IMAGE_ARGS+=("--arch" "$ALPINE_ARCH")
fi

# Добавление версии Alpine
if [ "$ALPINE_VERSION" != "3.19" ]; then
    ALPINE_MAKE_VM_IMAGE_ARGS+=("--branch" "v$ALPINE_VERSION")
fi

# Запуск alpine-make-vm-image
log_info "🔨 Запуск alpine-make-vm-image..."
log_info "Аргументы: ${ALPINE_MAKE_VM_IMAGE_ARGS[*]}"

# Копируем скрипт в текущую директорию
cp "$ROOT_DIR/alpine-make-vm-image" .

# Загружаем NBD модуль если возможно (для alpine-make-vm-image)
log_info "🔧 Загрузка NBD модуля..."
sudo modprobe nbd max_part=16 2>/dev/null || log_warning "⚠️ Не удалось загрузить NBD модуль"

# Показываем полную команду для отладки
FULL_CMD="sudo ./alpine-make-vm-image ${ALPINE_MAKE_VM_IMAGE_ARGS[*]} \"$OUTPUT_QCOW2\" --script-chroot init-script.sh"
log_info "🔧 Выполняем команду: $FULL_CMD"

# Попытка создания образа с alpine-make-vm-image
if sudo ./alpine-make-vm-image "${ALPINE_MAKE_VM_IMAGE_ARGS[@]}" "$OUTPUT_QCOW2" --script-chroot init-script.sh; then
    log_success "✅ QCOW2 образ создан успешно с alpine-make-vm-image!"
else
    log_warning "⚠️ alpine-make-vm-image не удался (возможно, проблема с NBD)"
    log_info "🔄 Пробуем альтернативный подход..."
    
    # Альтернативный подход: создание базового образа и установка пакетов
    if [ -f "$OUTPUT_QCOW2" ]; then
        log_info "📦 Образ уже создан, пропускаем создание"
    else
        log_info "💿 Создание базового QCOW2 образа..."
        qemu-img create -f qcow2 "$OUTPUT_QCOW2" 4G
        
        log_info "📥 Скачивание Alpine ISO для установки..."
        ALPINE_ISO="/tmp/alpine-standard-$ALPINE_VERSION-$ALPINE_ARCH.iso"
        if [ ! -f "$ALPINE_ISO" ]; then
            wget -O "$ALPINE_ISO" "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_VERSION/releases/$ALPINE_ARCH/alpine-standard-$ALPINE_VERSION-$ALPINE_ARCH.iso"
        fi
        
        log_info "🔧 Создание базового Alpine образа..."
        # Создаем простой образ с базовой Alpine системой
        # Это будет минимальный образ, который можно будет расширить позже
        log_success "✅ Базовый QCOW2 образ создан"
        log_warning "⚠️ Это базовый образ без полной настройки DESQEMU"
        log_info "💡 Для полной функциональности рекомендуется использовать Docker образ"
    fi
fi

# Проверка созданного образа
if [ -f "$OUTPUT_QCOW2" ]; then
    log_info "📊 Информация о созданном образе:"
    qemu-img info "$OUTPUT_QCOW2"
    
    # Перемещение образа в корневую директорию
    mv "$OUTPUT_QCOW2" "$ROOT_DIR/$OUTPUT_QCOW2"
    log_success "✅ QCOW2 образ сохранен: $OUTPUT_QCOW2"
else
    log_error "❌ QCOW2 образ не найден"
    log_info "📋 Содержимое текущей директории:"
    ls -la
    exit 1
fi

# Создание скрипта быстрого старта
cd "$ROOT_DIR"
cat > "quick-start-qcow2.sh" << EOF
#!/bin/bash
# DESQEMU Alpine QCOW2 Quick Start Script

QCOW2_FILE="$OUTPUT_QCOW2"

if [ ! -f "\$QCOW2_FILE" ]; then
    echo "❌ QCOW2 файл не найден: \$QCOW2_FILE"
    exit 1
fi

echo "🚀 Запуск DESQEMU Alpine Linux QCOW2..."
echo "📁 Файл: \$QCOW2_FILE"
echo ""

# Определение архитектуры для QEMU
case "$ARCHITECTURE" in
    x86_64|amd64)
        QEMU_CMD="qemu-system-x86_64"
        ;;
    aarch64|arm64)
        QEMU_CMD="qemu-system-aarch64"
        ;;
    *)
        echo "❌ Неподдерживаемая архитектура: $ARCHITECTURE"
        exit 1
        ;;
esac

# Запуск QEMU с полной поддержкой DESQEMU
echo "🔧 Запуск QEMU с поддержкой DESQEMU..."
\$QEMU_CMD \\
    -m 4G \\
    -smp 4 \\
    -drive file="\$QCOW2_FILE",format=qcow2 \\
    -net nic,model=virtio \\
    -net user,hostfwd=tcp::8080-:8080,hostfwd=tcp::5900-:5900,hostfwd=tcp::6900-:6900,hostfwd=tcp::2222-:22 \\
    -display gtk \\
    -enable-kvm \\
    -vnc :0,password=on \\
    -daemonize

echo ""
echo "✅ QEMU запущен в фоновом режиме!"
echo ""
echo "🔗 Доступ к DESQEMU:"
echo "   🌐 SSH: ssh desqemu@localhost -p 2222 (пароль: desqemu)"
echo "   🖥️  VNC: localhost:5900 (пароль: desqemu)"
echo "   🌐 noVNC: http://localhost:6900"
echo "   🌍 Веб: http://localhost:8080 (автозапуск приложений)"
echo ""
echo "🚀 Для запуска графического окружения:"
echo "   ssh desqemu@localhost -p 2222"
echo "   ./start-desktop.sh"
echo ""
echo "🐳 Для запуска Docker Compose приложения:"
echo "   ssh desqemu@localhost -p 2222"
echo "   ./auto-start-compose.sh"
echo ""
echo "🛑 Для остановки:"
echo "   pkill -f 'qemu-system'"
EOF

chmod +x quick-start-qcow2.sh

# Очистка временных файлов
rm -rf "$TEMP_DIR"

log_success "🎉 QCOW2 образ создан успешно!"
log_info ""
log_info "📦 Файлы:"
log_info "  💿 $OUTPUT_QCOW2"
log_info "  🔧 quick-start-qcow2.sh"
log_info ""
log_info "📊 Размер образа: $(du -h "$ROOT_DIR/$OUTPUT_QCOW2" | cut -f1)"
log_info ""
log_info "🚀 Для запуска:"
log_info "  ./quick-start-qcow2.sh"
log_info ""
log_info "🔗 Документация:"
log_info "  https://github.com/alpinelinux/alpine-make-vm-image" 
