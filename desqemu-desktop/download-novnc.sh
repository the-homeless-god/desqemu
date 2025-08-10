#!/bin/bash

# Скрипт для скачивания полной версии noVNC

echo "🌐 Скачивание noVNC..."

NOVNC_DIR="resources/js/novnc"
NOVNC_VERSION="1.4.0"

    # Очищаем и создаем директорию
    echo "🧹 Очищаем директорию noVNC..."
    rm -rf "$(dirname "$0")/$NOVNC_DIR"
    mkdir -p "$(dirname "$0")/$NOVNC_DIR"
    echo "✅ Директория создана: $(dirname "$0")/$NOVNC_DIR"

# Скачиваем noVNC
echo "📥 Скачиваем noVNC версии $NOVNC_VERSION..."
wget -O /tmp/novnc.tar.gz "https://github.com/novnc/noVNC/archive/refs/tags/v$NOVNC_VERSION.tar.gz"

if [ $? -eq 0 ]; then
    echo "✅ noVNC скачан успешно"
    
    # Распаковываем
    echo "📦 Распаковываем noVNC..."
    cd /tmp
    tar -xzf novnc.tar.gz
    
    # Копируем файлы
    echo "📋 Копируем файлы noVNC..."
    TARGET_DIR="$(dirname "$0")/$NOVNC_DIR"
    if [ "$TARGET_DIR" = "./$NOVNC_DIR" ]; then
        TARGET_DIR="$NOVNC_DIR"
    fi
    echo "Целевая директория: $TARGET_DIR"
    echo "Содержимое распакованного архива:"
    ls -la "noVNC-$NOVNC_VERSION/"
    
    # Возвращаемся в директорию скрипта и копируем
    cd "$(dirname "$0")"
    cp -r "/tmp/noVNC-$NOVNC_VERSION/." "$TARGET_DIR/"
    
    # Очищаем
    rm -rf /tmp/novnc.tar.gz /tmp/noVNC-$NOVNC_VERSION
    
    echo "✅ noVNC установлен в $NOVNC_DIR"
    echo "📁 Структура файлов:"
    ls -la "$(dirname "$0")/$NOVNC_DIR/"
    echo "📁 Содержимое app/:"
    ls -la "$(dirname "$0")/$NOVNC_DIR/app/" 2>/dev/null || echo "Папка app не найдена"
else
    echo "❌ Ошибка скачивания noVNC"
    exit 1
fi
