#!/bin/bash

set -e

ALPINE_VERSION="$1"
ARCHITECTURE="$2"

if [ -z "$ALPINE_VERSION" ] || [ -z "$ARCHITECTURE" ]; then
    echo "❌ Не указаны параметры"
    echo "Использование: $0 <alpine_version> <architecture>"
    exit 1
fi

echo "🚀 Создаем quick-start скрипты..."

# Script to quickly run the Docker image
cat > quick-start-docker.sh << 'EOF'
#!/bin/bash

echo "🐳 DESQEMU Alpine Linux - Docker Quick Start"
echo "==========================================="

if ! command -v docker &> /dev/null; then
    echo "❌ Docker не установлен!"
    echo "Установите Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

DOCKER_IMAGE="desqemu-alpine-docker-$ALPINE_VERSION-$ARCHITECTURE.tar.gz"

if [ ! -f "$DOCKER_IMAGE" ]; then
    echo "❌ Файл $DOCKER_IMAGE не найден!"
    echo "Убедитесь что вы распаковали архив полностью."
    exit 1
fi

echo "📦 Загружаем Docker образ..."
docker load < "$DOCKER_IMAGE"

echo "🚀 Запускаем DESQEMU Alpine контейнер..."
echo "📝 Логин: desqemu / Пароль: desqemu"
echo "🌐 Web: http://localhost:8080"
echo "🖥️  VNC: localhost:5900 (пароль: desqemu)"
echo "🔐 SSH: ssh desqemu@localhost -p 2222"
echo ""

docker run -it --privileged --rm \
  -p 8080:8080 \
  -p 5900:5900 \
  -p 2222:22 \
  --name desqemu-alpine \
  desqemu-alpine:latest
EOF

# Replace variables in the script
sed -i "s/\$ALPINE_VERSION/$ALPINE_VERSION/g" quick-start-docker.sh
sed -i "s/\$ARCHITECTURE/$ARCHITECTURE/g" quick-start-docker.sh

chmod +x quick-start-docker.sh

# Script to use rootfs in chroot
cat > quick-start-rootfs.sh << 'EOF'
#!/bin/bash

echo "🐳 DESQEMU Alpine Linux - Rootfs Quick Start"
echo "==========================================="

if [ "$EUID" -ne 0 ]; then
    echo "❌ Этот скрипт требует права root"
    echo "Запустите: sudo $0"
    exit 1
fi

ROOTFS_FILE="desqemu-alpine-rootfs-$ALPINE_VERSION-$ARCHITECTURE.tar.gz"
CHROOT_DIR="/opt/desqemu-alpine"

if [ ! -f "$ROOTFS_FILE" ]; then
    echo "❌ Файл $ROOTFS_FILE не найден!"
    exit 1
fi

echo "📦 Создаем chroot окружение в $CHROOT_DIR..."
mkdir -p "$CHROOT_DIR"
tar -xzf "$ROOTFS_FILE" -C "$CHROOT_DIR"

echo "🔧 Подготавливаем chroot..."
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /proc "$CHROOT_DIR/proc"
mount --bind /sys "$CHROOT_DIR/sys"

echo "🚀 Входим в DESQEMU Alpine chroot..."
echo "📝 Переключитесь на пользователя: su desqemu"
echo "🏠 Домашняя директория: /home/desqemu"
echo ""

chroot "$CHROOT_DIR" /bin/bash

echo "🧹 Очищаем mount points..."
umount "$CHROOT_DIR/dev" 2>/dev/null || true
umount "$CHROOT_DIR/proc" 2>/dev/null || true
umount "$CHROOT_DIR/sys" 2>/dev/null || true
EOF

# Replace variables in the script
sed -i "s/\$ALPINE_VERSION/$ALPINE_VERSION/g" quick-start-rootfs.sh
sed -i "s/\$ARCHITECTURE/$ARCHITECTURE/g" quick-start-rootfs.sh

chmod +x quick-start-rootfs.sh

# Script to run with custom docker-compose.yml
cat > quick-start-with-compose.sh << 'EOF'
#!/bin/bash

echo "🐳 DESQEMU Alpine Linux - Quick Start with Compose"
echo "=================================================="

if [ $# -eq 0 ]; then
    echo "❌ Укажите путь к docker-compose.yml файлу"
    echo "Использование: $0 <path-to-docker-compose.yml>"
    echo ""
    echo "Примеры:"
    echo "  $0 ./penpot-compose.yml"
    echo "  $0 /path/to/my-app/docker-compose.yml"
    exit 1
fi

COMPOSE_FILE="$1"
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Файл $COMPOSE_FILE не найден!"
    exit 1
fi

echo "📋 Используем docker-compose.yml: $COMPOSE_FILE"

# Create a temporary directory for the compose file
TEMP_DIR=$(mktemp -d)
cp "$COMPOSE_FILE" "$TEMP_DIR/docker-compose.yml"

echo "🚀 Запускаем DESQEMU Alpine с вашим compose файлом..."
echo "📝 Логин: desqemu / Пароль: desqemu"
echo "🌐 Приложение будет автоматически открыто в браузере"
echo "🖥️  VNC: localhost:5900 (пароль: desqemu)"
echo "🔐 SSH: ssh desqemu@localhost -p 2222"
echo ""

# Run the container with the compose file mounted
docker run -it --privileged --rm \
  -p 8080:8080 \
  -p 5900:5900 \
  -p 2222:22 \
  -v "$TEMP_DIR:/home/desqemu" \
  --name desqemu-alpine-compose \
  desqemu-alpine:latest

# Clean up
rm -rf "$TEMP_DIR"
EOF

chmod +x quick-start-with-compose.sh

echo "✅ Созданы quick-start скрипты:"
echo "  - quick-start-docker.sh"
echo "  - quick-start-rootfs.sh"
echo "  - quick-start-with-compose.sh" 
