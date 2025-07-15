# Multi-stage build for better caching
# Многоэтапная сборка для лучшего кэширования

# Stage 1: Base system with packages
# Этап 1: Базовая система с пакетами
FROM alpine:3.19 AS base

# Install system packages (this layer will be cached)
# Устанавливаем системные пакеты (этот слой будет кэширован)
RUN apk update && apk upgrade && \
    apk add --no-cache \
      podman \
      docker-cli \
      docker-compose \
      qemu-system-x86_64 \
      qemu-img \
      chromium \
      chromium-chromedriver \
      curl \
      wget \
      bash \
      git \
      nano \
      htop \
      openssh \
      openrc \
      shadow \
      sudo \
      dbus \
      python3 \
      py3-pip \
      nodejs \
      npm \
      xvfb \
      x11vnc \
      fluxbox \
      jq \
      netcat-openbsd \
      procps

# Stage 2: Python packages
# Этап 2: Python пакеты
FROM base AS python-deps

# Install Python packages in virtual environment (separate layer for better caching)
# Устанавливаем Python пакеты в виртуальном окружении (отдельный слой для лучшего кэширования)
RUN python3 -m venv /opt/venv && \
    . /opt/venv/bin/activate && \
    pip install podman-compose yq

# Add virtual environment to PATH
# Добавляем виртуальное окружение в PATH
ENV PATH="/opt/venv/bin:$PATH"

# Stage 3: Final image with configuration
# Этап 3: Финальный образ с конфигурацией
FROM python-deps AS final

# Basic image info / Базовая информация об образе
LABEL org.opencontainers.image.title="DESQEMU Alpine with Podman"
LABEL org.opencontainers.image.description="Alpine Linux с предустановленным Podman, QEMU и Chromium для DESQEMU"
LABEL org.opencontainers.image.source="https://github.com/the-homeless-god/desqemu"
LABEL org.opencontainers.image.version="3.19"
LABEL org.opencontainers.image.licenses="BSD-3-Clause"

# Stage 4: User and system configuration
# Этап 4: Пользователи и системная конфигурация
FROM final AS configured

# Create main user for DESQEMU with sudo access
# Создаем основного пользователя для DESQEMU с правами sudo
RUN adduser -D -s /bin/bash desqemu && \
    echo "desqemu:desqemu" | chpasswd && \
    addgroup desqemu wheel && \
    addgroup docker && \
    addgroup desqemu docker && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Setup rootless podman support
# Настройка поддержки rootless podman
RUN echo "desqemu:100000:65536" >> /etc/subuid && \
    echo "desqemu:100000:65536" >> /etc/subgid

# Set root password for admin access / Устанавливаем пароль root для админского доступа
RUN echo "root:root" | chpasswd

# Configure Podman to use common registries
# Настраиваем Podman для использования общих registry
RUN mkdir -p /home/desqemu/.config/containers
COPY --chown=desqemu:desqemu <<REGEOF /home/desqemu/.config/containers/registries.conf
unqualified-search-registries = ["docker.io"]

[[registry]]
location = "docker.io"

[[registry]]
location = "registry.fedoraproject.org"

[[registry]]
location = "quay.io"
REGEOF

# Note: podman machine init will be done in startup script as desqemu user
# Примечание: инициализация podman machine будет выполнена в скрипте запуска от пользователя desqemu

# Stage 5: Scripts and configuration files
# Этап 5: Скрипты и конфигурационные файлы
FROM configured AS scripts

# Create a welcome message that shows what's available
# Создаем приветственное сообщение с информацией о возможностях
COPY --chown=desqemu:desqemu <<PROFEOF /home/desqemu/.profile
echo "🐳 Добро пожаловать в DESQEMU Alpine Linux!"
echo "📦 Podman версия: \$(podman --version)"
echo "🖥️  QEMU версия: \$(qemu-system-x86_64 --version | head -1)"
echo "🌐 Chromium версия: \$(chromium --version)"
echo "🚀 Готов к запуску контейнеров и веб-приложений!"
echo ""
echo "Полезные команды:"
echo "  podman run hello-world                    - тест Podman"
echo "  podman ps                                 - список контейнеров"
echo "  chromium --headless --remote-debugging-port=9222 - headless Chromium"
echo "  startx                                    - запуск X11 окружения"
echo "  ./auto-start-compose.sh                   - автозапуск docker-compose"
echo ""
PROFEOF

# Script to start X11 environment for GUI apps
# Скрипт для запуска X11 окружения для GUI приложений
COPY --chown=desqemu:desqemu <<STARTXEOF /home/desqemu/start-desktop.sh
#!/bin/bash
export DISPLAY=:1
Xvfb :1 -screen 0 1024x768x16 &
sleep 2
fluxbox &
x11vnc -display :1 -forever -usepw -create &
echo "🖥️  Рабочий стол запущен на display :1"
echo "🌐 VNC доступен на порту 5900 (пароль: desqemu)"
STARTXEOF

RUN chmod +x /home/desqemu/start-desktop.sh

# Script to automatically parse docker-compose.yml and start browser
# Скрипт для автоматического парсинга docker-compose.yml и запуска браузера
COPY --chown=desqemu:desqemu auto-start-compose.sh /home/desqemu/auto-start-compose.sh

RUN chmod +x /home/desqemu/auto-start-compose.sh

# Auto-start script for DESQEMU services (web server, VNC setup)
# Скрипт автозапуска сервисов DESQEMU (веб-сервер, настройка VNC)
COPY <<APIEOF /etc/local.d/desqemu-services.start
#!/bin/sh

# Initialize and start podman machine as desqemu user
# Инициализируем и запускаем podman machine от пользователя desqemu
su desqemu -c 'podman machine init --cpus 2 --memory 2048 --disk-size 20 || true'
su desqemu -c 'podman machine start || true'

# Start simple web server for DESQEMU interface
# Запускаем простой веб-сервер для интерфейса DESQEMU
su desqemu -c 'cd /home/desqemu && python3 -m http.server 8080 > /tmp/desqemu-web.log 2>&1 &'

# Set up VNC password for remote desktop access
# Настраиваем пароль VNC для удаленного доступа к рабочему столу
su desqemu -c 'mkdir -p /home/desqemu/.vnc && echo "desqemu" | vncpasswd -f > /home/desqemu/.vnc/passwd && chmod 600 /home/desqemu/.vnc/passwd'

# Auto-start compose if docker-compose.yml exists
# Автозапуск compose если есть docker-compose.yml
if [ -f "/home/desqemu/docker-compose.yml" ]; then
    echo "🚀 Обнаружен docker-compose.yml, запускаем автоматически..."
    su desqemu -c '/home/desqemu/auto-start-compose.sh > /tmp/desqemu-compose.log 2>&1 &'
fi

echo "✅ DESQEMU сервисы запущены"
APIEOF

RUN chmod +x /etc/local.d/desqemu-services.start

# Stage 6: Final image with services
# Этап 6: Финальный образ с сервисами
FROM scripts AS final-image

# Enable services to start automatically / Включаем автозапуск сервисов
RUN rc-update add dbus default && \
    rc-update add sshd default && \
    rc-update add local default

# Open ports for web interface, SSH, and VNC
# Открываем порты для веб-интерфейса, SSH и VNC
EXPOSE 8080 22 5900

# Set working directory and default user
# Устанавливаем рабочую директорию и пользователя по умолчанию
WORKDIR /home/desqemu
USER desqemu

# Default command / Команда по умолчанию
CMD ["/bin/bash", "-l"] 
