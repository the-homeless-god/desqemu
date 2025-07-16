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

echo "📝 Создаем release notes для основного релиза..."

cat > release-notes.md << EOF
# 🐳 DESQEMU Alpine Linux с Podman v$ALPINE_VERSION

Готовый к использованию дистрибутив Alpine Linux с Podman и Chromium для DESQEMU.

## 🎯 Что нового:
- Alpine Linux $ALPINE_VERSION ($ARCHITECTURE)
- Podman + Docker CLI + Docker Compose
- QEMU для эмуляции виртуальных машин
- Chromium + X11/VNC для GUI приложений
- Python 3 + Node.js для разработки
- SSH сервер для удаленного доступа
- Готовые скрипты запуска
- 🆕 **Автоматическая публикация в GitHub Container Registry**
- 🆕 **Автоматический парсинг docker-compose.yml**
- 🆕 **Автозапуск браузера на нужном порту**

## 📦 Способы использования:

### 🚀 GitHub Container Registry (самый простой):
\`\`\`bash
docker run -it --privileged \\
  -p 8080:8080 -p 5900:5900 -p 2222:22 \\
  ghcr.io/$REPOSITORY_OWNER/desqemu-alpine:latest
\`\`\`

### 📁 Файлы для скачивания:

**🐳 Docker образ:**
- \`desqemu-alpine-docker-$ALPINE_VERSION-$ARCHITECTURE.tar.gz\` - готовый Docker образ
- \`quick-start-docker.sh\` - скрипт быстрого запуска
- \`quick-start-with-compose.sh\` - скрипт запуска с docker-compose.yml

**📁 Rootfs для chroot:**
- \`desqemu-alpine-rootfs-$ALPINE_VERSION-$ARCHITECTURE.tar.gz\` - файловая система
- \`quick-start-rootfs.sh\` - скрипт для chroot
- \`quick-start-with-compose.sh\` - скрипт запуска с docker-compose.yml

## 🚀 Быстрый старт:

\`\`\`bash
# Из GitHub Container Registry (рекомендуется)
docker pull ghcr.io/$REPOSITORY_OWNER/desqemu-alpine:latest

# Из архивов
./quick-start-docker.sh

# Rootfs вариант (требует root)
sudo ./quick-start-rootfs.sh

# Запуск с вашим docker-compose.yml
./quick-start-with-compose.sh ./my-app/docker-compose.yml
\`\`\`

## 🌐 Доступ:
- Web: http://localhost:8080
- VNC: localhost:5900 (пароль: desqemu)
- SSH: ssh desqemu@localhost -p 2222

## 📊 Размеры:
- Docker образ: ~\$(du -h desqemu-alpine-docker-*.tar.gz 2>/dev/null | cut -f1 || echo "N/A")
- Rootfs: ~\$(du -h desqemu-alpine-rootfs-*.tar.gz 2>/dev/null | cut -f1 || echo "N/A")

## 🔗 GitHub Container Registry:
- **Registry:** ghcr.io/$REPOSITORY_OWNER/desqemu-alpine
- **Tags:** \`latest\`, \`$ALPINE_VERSION\`, \`$ALPINE_VERSION-$ARCHITECTURE\`

---

Создано автоматически GitHub Actions $(date)
EOF

echo "✅ Создан release-notes.md" 
