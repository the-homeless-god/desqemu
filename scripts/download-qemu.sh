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
# Note: Don't hardcode version, use latest available

# For x86_64 host - download all QEMU system emulators
if [ "$ARCHITECTURE" = "x86_64" ]; then
    # Download QEMU for x86_64 host
    echo "🔽 Скачиваем QEMU для x86_64..."
    
    # Try to find the actual available packages first
    if ! wget -q --spider "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/" 2>/dev/null; then
        echo "❌ Не удается подключиться к Alpine репозиторию"
        exit 1
    fi
    
    # Download without hardcoded version - get latest
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/" -O - | grep -o 'qemu-system-x86_64-[^"]*\.apk' | head -1 | xargs -I {} wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/{}" -O qemu-system.apk || {
        echo "❌ Не удалось скачать qemu-system-x86_64"
        exit 1
    }
    
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/" -O - | grep -o 'qemu-img-[^"]*\.apk' | head -1 | xargs -I {} wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/{}" -O qemu-img.apk || {
        echo "❌ Не удалось скачать qemu-img"
        exit 1
    }
elif [ "$ARCHITECTURE" = "aarch64" ] || [ "$ARCHITECTURE" = "arm64" ]; then
    # Download QEMU for aarch64 host  
    echo "🔽 Скачиваем QEMU для aarch64..."
    
    # Try to find the actual available packages first
    if ! wget -q --spider "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/" 2>/dev/null; then
        echo "❌ Не удается подключиться к Alpine репозиторию"
        exit 1
    fi
    
    # Download without hardcoded version - get latest
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/" -O - | grep -o 'qemu-system-x86_64-[^"]*\.apk' | head -1 | xargs -I {} wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/{}" -O qemu-system.apk || {
        echo "❌ Не удалось скачать qemu-system-x86_64"
        exit 1
    }
    
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/" -O - | grep -o 'qemu-img-[^"]*\.apk' | head -1 | xargs -I {} wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/{}" -O qemu-img.apk || {
        echo "❌ Не удалось скачать qemu-img"
        exit 1
    }
    
    wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/" -O - | grep -o 'qemu-system-aarch64-[^"]*\.apk' | head -1 | xargs -I {} wget -q "https://dl-cdn.alpinelinux.org/alpine/v3.19/main/aarch64/{}" -O qemu-system-aarch64.apk || {
        echo "❌ Не удалось скачать qemu-system-aarch64"
        exit 1
    }
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
