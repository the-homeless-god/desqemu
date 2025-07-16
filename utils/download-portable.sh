#!/bin/bash

echo "📥 DESQEMU Portable Downloader"
echo "=============================="

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        DOWNLOAD_ARCH="x86_64"
        ;;
    aarch64|arm64)
        DOWNLOAD_ARCH="aarch64"
        ;;
    *)
        echo "❌ Неподдерживаемая архитектура: $ARCH"
        echo "Поддерживаются: x86_64, aarch64, arm64"
        exit 1
        ;;
esac

echo "🖥️  Обнаружена архитектура: $ARCH → $DOWNLOAD_ARCH"

# Get latest release info from GitHub API
REPO="$1"
if [ -z "$REPO" ]; then
    echo "❌ Укажите репозиторий в формате owner/repo"
    echo "Использование: $0 owner/repo [tag]"
    echo ""
    echo "Примеры:"
    echo "  $0 the-homeless-god/desqemu"
    echo "  $0 the-homeless-god/desqemu v1.0.0"
    exit 1
fi

TAG="$2"
if [ -z "$TAG" ]; then
    echo "🔍 Получаем информацию о последнем релизе..."
    TAG=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$TAG" ]; then
        echo "❌ Не удалось получить информацию о релизе"
        echo "Укажите тег вручную: $0 $REPO v1.0.0"
        exit 1
    fi
fi

echo "🏷️  Используем тег: $TAG"

# Download URLs
ARCHIVE_URL="https://github.com/$REPO/releases/download/$TAG-portable/desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz"
INSTALLER_URL="https://github.com/$REPO/releases/download/$TAG-portable/install-desqemu-portable.sh"

echo "📦 Скачиваем портативный архив..."
echo "URL: $ARCHIVE_URL"

if ! wget -q --show-progress "$ARCHIVE_URL"; then
    echo "❌ Ошибка скачивания архива"
    echo "Проверьте что релиз $TAG-portable существует"
    exit 1
fi

echo "📥 Скачиваем установщик..."
if ! wget -q "$INSTALLER_URL"; then
    echo "⚠️  Установщик не найден, но архив скачан"
else
    chmod +x install-desqemu-portable.sh
fi

echo ""
echo "✅ Скачивание завершено!"
echo ""
echo "🚀 Для запуска:"
echo "  # Быстрый запуск"
echo "  tar -xzf desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz"
echo "  cd $DOWNLOAD_ARCH"
echo "  ./start-microvm.sh"
echo ""
echo "  # Или установка в систему"
if [ -f "install-desqemu-portable.sh" ]; then
    echo "  ./install-desqemu-portable.sh"
else
    echo "  # (установщик не найден)"
fi
echo ""
echo "📊 Размер архива: $(du -h desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz | cut -f1)" 
