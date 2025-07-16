#!/bin/bash

set -e

ARCHITECTURE="$1"
if [ -z "$ARCHITECTURE" ]; then
    echo "❌ Не указана архитектура"
    echo "Использование: $0 <architecture>"
    exit 1
fi

echo "📦 Скачиваем QEMU для $ARCHITECTURE..."

# Create directory for QEMU
mkdir -p "qemu-portable/$ARCHITECTURE"
cd "qemu-portable/$ARCHITECTURE"

# Download QEMU static binaries from Alpine packages
QEMU_VERSION="8.2.0"

# For x86_64 host - download all QEMU system emulators
if [ "$ARCHITECTURE" = "x86_64" ]; then
    # Download QEMU for x86_64 host
    echo "🔽 Скачиваем QEMU для x86_64..."
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/qemu-system-x86_64-${QEMU_VERSION}-r0.apk" -O qemu-system.apk
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/qemu-img-${QEMU_VERSION}-r0.apk" -O qemu-img.apk
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/qemu-system-arm-${QEMU_VERSION}-r0.apk" -O qemu-system-arm.apk
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/qemu-system-aarch64-${QEMU_VERSION}-r0.apk" -O qemu-system-aarch64.apk
elif [ "$ARCHITECTURE" = "aarch64" ] || [ "$ARCHITECTURE" = "arm64" ]; then
    # Download QEMU for aarch64 host  
    echo "🔽 Скачиваем QEMU для aarch64..."
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/qemu-system-x86_64-${QEMU_VERSION}-r0.apk" -O qemu-system.apk
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/qemu-img-${QEMU_VERSION}-r0.apk" -O qemu-img.apk
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/qemu-system-aarch64-${QEMU_VERSION}-r0.apk" -O qemu-system-aarch64.apk
else
    echo "❌ Неподдерживаемая архитектура: $ARCHITECTURE"
    exit 1
fi

# Extract APK files (they are just tar.gz archives)
echo "📦 Распаковываем APK файлы..."
for apk in *.apk; do
    if [ -f "$apk" ]; then
        echo "  📦 Распаковываем $apk..."
        tar -xzf "$apk" 2>/dev/null || true
    fi
done

# Clean up APK files
rm -f *.apk

echo "✅ QEMU бинарники скачаны для $ARCHITECTURE"
cd "../.." 
