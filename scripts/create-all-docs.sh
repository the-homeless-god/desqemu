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

echo "📚 Создаем всю документацию и скрипты для Alpine дистрибутива..."

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create Alpine README
echo "📖 Создаем Alpine README..."
"$SCRIPT_DIR/create-alpine-readme.sh" "$ALPINE_VERSION" "$ARCHITECTURE" "$REPOSITORY_OWNER"

# Create release notes
echo "📝 Создаем release notes..."
"$SCRIPT_DIR/create-release-notes.sh" "$ALPINE_VERSION" "$ARCHITECTURE" "$REPOSITORY_OWNER"

# Create quick-start scripts
echo "🚀 Создаем quick-start скрипты..."
"$SCRIPT_DIR/create-quick-start-scripts.sh" "$ALPINE_VERSION" "$ARCHITECTURE"

echo "✅ Вся документация и скрипты созданы!"
echo ""
echo "📁 Созданные файлы:"
echo "  📖 DESQEMU-Alpine-README.md"
echo "  📝 release-notes.md"
echo "  🚀 quick-start-docker.sh"
echo "  🚀 quick-start-rootfs.sh"
echo "  🚀 quick-start-with-compose.sh" 
