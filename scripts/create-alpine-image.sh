#!/bin/bash

set -e

# Парсинг аргументов
ALPINE_VERSION="3.22.0"
ARCH="x86_64"
OUTPUT_DIR="."

# Функция для вывода справки
show_help() {
    cat << EOF
Alpine Image Creator

Usage: $0 [OPTIONS]

Options:
    --version VERSION    Alpine version (default: 3.22.0)
    --arch ARCH         Target architecture (default: x86_64)
    --output DIR        Output directory (default: current)
    --help              Show this help message

Examples:
    $0 --version 3.22.0 --arch x86_64
    $0 --version 3.22.0 --arch aarch64 --output ./images
EOF
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            ALPINE_VERSION="$2"
            shift 2
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

echo "🏔️  Creating Alpine Linux image..."
echo "📦 Version: $ALPINE_VERSION"
echo "🏗️  Architecture: $ARCH"
echo "📁 Output: $OUTPUT_DIR"

# Создаем выходную директорию
mkdir -p "$OUTPUT_DIR"

# Определяем имя файла ISO
ISO_FILE="alpine-standard-$ALPINE_VERSION-$ARCH.iso"
ISO_URL="https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_VERSION%.*}/releases/$ARCH/$ISO_FILE"

# Проверяем, есть ли уже ISO файл
if [[ ! -f "$ISO_FILE" ]]; then
    echo "📥 Downloading Alpine ISO..."
    curl -L -o "$ISO_FILE" "$ISO_URL"
else
    echo "✅ Alpine ISO already exists: $ISO_FILE"
fi

# Создаем QCOW2 образ
QCOW2_FILE="$OUTPUT_DIR/alpine-$ARCH.qcow2"

echo "🔧 Creating QCOW2 image..."
qemu-img create -f qcow2 "$QCOW2_FILE" 10G

echo "✅ Alpine image created successfully!"
echo "📁 QCOW2 file: $QCOW2_FILE"
echo "📁 ISO file: $ISO_FILE" 
