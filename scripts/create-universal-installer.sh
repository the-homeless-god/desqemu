#!/bin/bash

set -e

echo "🛠️  Создаем универсальный установщик..."

cat > install-desqemu-portable.sh << 'EOF'
#!/bin/bash

echo "🚀 DESQEMU Portable MicroVM Universal Installer"
echo "==============================================="

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

ARCHIVE="desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz"
INSTALL_DIR="$HOME/desqemu-portable"

if [ ! -f "$ARCHIVE" ]; then
    echo "❌ Архив $ARCHIVE не найден!"
    echo ""
    echo "📥 Попытка скачать архив из GitHub Releases..."
    
    # Try to download from GitHub releases
    REPO="${GITHUB_REPO:-}"
    TAG="${GITHUB_TAG:-latest}"
    
    if [ -z "$REPO" ]; then
        echo "❌ Переменная GITHUB_REPO не задана"
        echo "Установите переменную окружения:"
        echo "  export GITHUB_REPO=\"the-homeless-god/desqemu\""
        echo "  $0"
        echo ""
        echo "Или скачайте архив вручную:"
        echo "  wget https://github.com/the-homeless-god/desqemu/releases/download/TAG/desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz"
        exit 1
    fi
    
    if [ "$TAG" = "latest" ]; then
        DOWNLOAD_URL="https://github.com/$REPO/releases/latest/download/desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz"
    else
        DOWNLOAD_URL="https://github.com/$REPO/releases/download/$TAG/desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz"
    fi
    
    echo "📦 Скачиваем: $DOWNLOAD_URL"
    
    if command -v wget >/dev/null 2>&1; then
        wget -O "$ARCHIVE" "$DOWNLOAD_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -L -o "$ARCHIVE" "$DOWNLOAD_URL"
    else
        echo "❌ Не найден wget или curl для скачивания"
        echo "Установите один из них или скачайте архив вручную"
        exit 1
    fi
    
    if [ ! -f "$ARCHIVE" ]; then
        echo "❌ Скачивание не удалось"
        exit 1
    fi
    
    echo "✅ Архив скачан"
fi

echo "📦 Устанавливаем DESQEMU Portable в $INSTALL_DIR..."

# Create install directory
mkdir -p "$INSTALL_DIR"

# Extract archive
echo "📦 Распаковываем архив..."
tar -xzf "$ARCHIVE" -C "$INSTALL_DIR"

# Create symlinks in PATH
if [ -d "$HOME/.local/bin" ]; then
    BIN_DIR="$HOME/.local/bin"
else
    BIN_DIR="$HOME/bin"
    mkdir -p "$BIN_DIR"
fi

echo "🔗 Создаем ссылки в $BIN_DIR..."
ln -sf "$INSTALL_DIR/$DOWNLOAD_ARCH/start-microvm.sh" "$BIN_DIR/desqemu-start"
ln -sf "$INSTALL_DIR/$DOWNLOAD_ARCH/stop-microvm.sh" "$BIN_DIR/desqemu-stop"
ln -sf "$INSTALL_DIR/$DOWNLOAD_ARCH/check-status.sh" "$BIN_DIR/desqemu-status"

echo "✅ Установка завершена!"
echo ""
echo "🚀 Для запуска используйте:"
echo "  desqemu-start     # Запуск микровм"
echo "  desqemu-status    # Проверка статуса"
echo "  desqemu-stop      # Остановка микровм"
echo ""
echo "📁 Файлы установлены в: $INSTALL_DIR"

# Check if BIN_DIR is in PATH
if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
    echo ""
    echo "🔧 Добавьте $BIN_DIR в PATH:"
    echo "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> ~/.bashrc"
    echo "  source ~/.bashrc"
    echo ""
    echo "Или выполните команды напрямую:"
    echo "  $BIN_DIR/desqemu-start"
else
    echo "✅ $BIN_DIR уже в PATH"
fi
EOF

chmod +x install-desqemu-portable.sh

echo "✅ Создан универсальный установщик: install-desqemu-portable.sh" 
