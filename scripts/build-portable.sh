#!/bin/bash

set -e

ARCHITECTURE="$1"
if [ -z "$ARCHITECTURE" ]; then
    echo "❌ Не указана архитектура"
    echo "Использование: $0 <architecture>"
    echo ""
    echo "Поддерживаемые архитектуры:"
    echo "  x86_64   - Intel/AMD 64-bit"
    echo "  aarch64  - ARM 64-bit"
    echo "  arm64    - ARM 64-bit (альтернативное название)"
    exit 1
fi

echo "🚀 DESQEMU Portable Builder"
echo "==========================="
echo "Архитектура: $ARCHITECTURE"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$ROOT_DIR"

# Check dependencies
echo "🔧 Проверяем зависимости..."
if ! command -v wget >/dev/null 2>&1; then
    echo "❌ wget не найден! Установите wget"
    exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
    echo "❌ tar не найден! Установите tar"
    exit 1
fi

echo "✅ Зависимости проверены"
echo ""

# Step 1: Download QEMU
echo "📥 Этап 1: Скачивание QEMU бинарников..."
"$SCRIPT_DIR/download-qemu.sh" "$ARCHITECTURE"
echo ""

# Step 2: Create portable archive structure
echo "🏗️  Этап 2: Создание структуры портативного архива..."
"$SCRIPT_DIR/create-portable-archive.sh" "$ARCHITECTURE"
echo ""

# Step 3: Create final archive
echo "📦 Этап 3: Создание итогового архива..."
"$SCRIPT_DIR/create-archive.sh" "$ARCHITECTURE"
echo ""

# Cleanup temporary directories
echo "🧹 Очистка временных файлов..."
rm -rf "qemu-portable/$ARCHITECTURE"
echo "✅ Временные файлы очищены"
echo ""

echo "🎉 Портативная сборка завершена!"
echo ""
echo "📦 Файлы:"
echo "  📁 desqemu-portable-microvm-$ARCHITECTURE.tar.gz"
echo "  🔧 install-desqemu-portable-$ARCHITECTURE.sh"
echo ""
echo "📊 Размер архива: $(du -h desqemu-portable-microvm-$ARCHITECTURE.tar.gz | cut -f1)"
echo ""
echo "🚀 Для тестирования:"
echo "  tar -xzf desqemu-portable-microvm-$ARCHITECTURE.tar.gz"
echo "  cd $ARCHITECTURE"
echo "  ./start-microvm.sh" 
