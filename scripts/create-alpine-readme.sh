#!/bin/bash

set -e

ALPINE_VERSION="$1"
ARCHITECTURE="$2"
REPOSITORY_OWNER="$3"

if [ -z "$ALPINE_VERSION" ] || [ -z "$ARCHITECTURE" ] || [ -z "$REPOSITORY_OWNER" ]; then
    echo "❌ Не указаны параметры"
    echo "Использование: $0 <alpine_version> <architecture> <repository_owner>"
    exit 1
fi

echo "📚 Создаем README для Alpine дистрибутива..."

cat > DESQEMU-Alpine-README.md << EOF
# 🐳 DESQEMU Alpine Linux с Podman и Chromium

Кастомизированный дистрибутив Alpine Linux, оптимизированный для DESQEMU.

## 📋 Что включено:

- **Alpine Linux $ALPINE_VERSION** ($ARCHITECTURE)
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

## 👤 Пользователи:

- **root** (пароль: root) - администратор
- **desqemu** (пароль: desqemu) - основной пользователь

## 🚀 Использование:

### Из GitHub Container Registry (рекомендуется):
\`\`\`bash
# Скачать и запустить напрямую из GitHub
docker run -it --privileged \\
  -p 8080:8080 \\
  -p 5900:5900 \\
  -p 2222:22 \\
  ghcr.io/$REPOSITORY_OWNER/desqemu-alpine:latest

# Или скачать локально
docker pull ghcr.io/$REPOSITORY_OWNER/desqemu-alpine:latest

# Запуск с вашим docker-compose.yml
./quick-start-with-compose.sh ./my-app/docker-compose.yml
\`\`\`

### Как Docker образ из архива:
\`\`\`bash
# Загрузить образ
docker load < desqemu-alpine-docker-$ALPINE_VERSION-$ARCHITECTURE.tar.gz

# Запустить контейнер
docker run -it --privileged \\
  -p 8080:8080 \\
  -p 5900:5900 \\
  -p 2222:22 \\
  desqemu-alpine:latest
\`\`\`

### Как rootfs:
\`\`\`bash
# Распаковать в chroot окружение
sudo mkdir /opt/desqemu-alpine
sudo tar -xzf desqemu-alpine-rootfs-$ALPINE_VERSION-$ARCHITECTURE.tar.gz -C /opt/desqemu-alpine

# Войти в chroot
sudo chroot /opt/desqemu-alpine /bin/bash
\`\`\`

## 🌐 Доступные порты:

- **8080** - Веб-интерфейс DESQEMU
- **5900** - VNC сервер (пароль: desqemu)
- **22** - SSH сервер

## 📦 Тестирование:

\`\`\`bash
# Тест Podman
podman run hello-world

# Тест Chromium (headless)
chromium --headless --remote-debugging-port=9222

# Запуск графического окружения
./start-desktop.sh

# Тест с docker-compose.yml
echo 'version: "3"
services:
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"' > test-compose.yml
./quick-start-with-compose.sh test-compose.yml
\`\`\`

## 🔧 Интеграция с DESQEMU:

Этот дистрибутив готов для использования с DESQEMU для создания
нативных десктопных приложений из Docker Compose файлов с полной
поддержкой веб-интерфейсов через Chromium.

---

**Создано:** $(date)
**Версия:** DESQEMU Alpine $ALPINE_VERSION
**Архитектура:** $ARCHITECTURE
**GitHub Registry:** ghcr.io/$REPOSITORY_OWNER/desqemu-alpine
**Размер:** rootfs ~\$(du -h desqemu-alpine-rootfs-*.tar.gz 2>/dev/null | cut -f1 || echo "N/A"), docker ~\$(du -h desqemu-alpine-docker-*.tar.gz 2>/dev/null | cut -f1 || echo "N/A")
EOF

echo "✅ Создан DESQEMU-Alpine-README.md" 
