#!/bin/bash

echo "🧪 DESQEMU Portable Local Test"
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

echo "🖥️  Тестируем архитектуру: $DOWNLOAD_ARCH"

# Build portable archive
echo ""
echo "🔨 Создаем портативный архив..."
if [ ! -f "scripts/build-portable.sh" ]; then
    echo "❌ Скрипт scripts/build-portable.sh не найден!"
    echo "Убедитесь что вы находитесь в корне проекта DESQEMU"
    exit 1
fi

scripts/build-portable.sh "$DOWNLOAD_ARCH"

# Test archive
ARCHIVE="desqemu-portable-microvm-$DOWNLOAD_ARCH.tar.gz"
if [ ! -f "$ARCHIVE" ]; then
    echo "❌ Архив $ARCHIVE не создан!"
    exit 1
fi

echo ""
echo "📦 Тестируем архив..."
echo "📊 Размер архива: $(du -h $ARCHIVE | cut -f1)"

# Create test directory
TEST_DIR="test-portable-$DOWNLOAD_ARCH"
rm -rf "$TEST_DIR"
mkdir "$TEST_DIR"
cd "$TEST_DIR"

# Extract archive
echo "📦 Распаковываем архив..."
tar -xzf "../$ARCHIVE"

if [ ! -d "$DOWNLOAD_ARCH" ]; then
    echo "❌ Архив не содержит директорию $DOWNLOAD_ARCH!"
    exit 1
fi

cd "$DOWNLOAD_ARCH"

# Check files
echo ""
echo "📋 Проверяем структуру архива..."
REQUIRED_FILES=(
    "start-microvm.sh"
    "stop-microvm.sh" 
    "check-status.sh"
    "README.md"
    "alpine-vm.qcow2"
    "bzImage"
    "initramfs-virt"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file отсутствует!"
        exit 1
    fi
done

# Check QEMU binaries
if [ -d "bin" ]; then
    QEMU_COUNT=$(find bin -name "qemu-*" | wc -l)
    echo "✅ bin/ (найдено $QEMU_COUNT QEMU бинарников)"
else
    echo "❌ Директория bin/ отсутствует!"
    exit 1
fi

# Check if scripts are executable
for script in start-microvm.sh stop-microvm.sh check-status.sh; do
    if [ -x "$script" ]; then
        echo "✅ $script исполняемый"
    else
        echo "❌ $script не исполняемый!"
        exit 1
    fi
done

echo ""
echo "🎉 Все проверки пройдены!"
echo ""
echo "🚀 Для запуска микровм:"
echo "  cd test-portable-$DOWNLOAD_ARCH/$DOWNLOAD_ARCH"
echo "  ./start-microvm.sh"
echo ""
echo "📝 После запуска доступ по:"
echo "  VNC: localhost:5900 (пароль: desqemu)"
echo "  SSH: ssh desqemu@localhost -p 2222"
echo "  Web: http://localhost:8080"
echo ""
echo "🛑 Для остановки:"
echo "  ./stop-microvm.sh"

# Go back to root
cd "../.."

echo ""
echo "🧹 Для очистки тестовых файлов:"
echo "  rm -rf $TEST_DIR $ARCHIVE install-desqemu-portable-$DOWNLOAD_ARCH.sh" 
