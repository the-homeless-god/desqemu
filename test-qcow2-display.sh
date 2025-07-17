#!/bin/bash

# Скрипт для тестирования QCOW2 файла с графическим дисплеем
# Проверяет, что VM может запуститься и показать дисплей

echo "🧪 Тестирование QCOW2 файла с дисплеем..."
echo "=========================================="

# Проверяем наличие QCOW2 файла
QCOW2_FILE="desqemu-desktop/resources/qcow2/penpot-microvm.qcow2"

if [ ! -f "$QCOW2_FILE" ]; then
    echo "❌ Ошибка: QCOW2 файл не найден: $QCOW2_FILE"
    exit 1
fi

echo "✅ QCOW2 файл найден: $QCOW2_FILE"
echo "📊 Размер файла: $(du -h "$QCOW2_FILE" | cut -f1)"

# Проверяем QEMU
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "❌ Ошибка: QEMU не установлен"
    exit 1
fi

echo "✅ QEMU найден: $(qemu-system-x86_64 --version | head -1)"

# Определяем доступные дисплеи
echo "🔍 Проверяем доступные дисплеи..."
qemu-system-x86_64 -display help 2>&1 | grep -E "(cocoa|sdl|gtk)" || echo "Нет стандартных дисплеев"

# Запускаем VM с графическим дисплеем
echo ""
echo "🚀 Запускаем VM с графическим дисплеем..."
echo "💡 Используйте Ctrl+C для остановки"
echo ""

# Команда QEMU с графическим дисплеем (пробуем разные варианты)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS - используем cocoa
    echo "🍎 Используем cocoa дисплей для macOS"
    qemu-system-x86_64 \
        -m 1G \
        -smp 2 \
        -netdev user,id=net0,hostfwd=tcp::8080-:8080,hostfwd=tcp::5900-:5900,hostfwd=tcp::6900-:6900,hostfwd=tcp::2222-:22 \
        -device e1000,netdev=net0 \
        -vnc :0,password=on \
        -display cocoa \
        -drive file="$QCOW2_FILE",format=qcow2,if=virtio
else
    # Linux - используем sdl
    echo "🐧 Используем SDL дисплей для Linux"
    qemu-system-x86_64 \
        -m 1G \
        -smp 2 \
        -netdev user,id=net0,hostfwd=tcp::8080-:8080,hostfwd=tcp::5900-:5900,hostfwd=tcp::6900-:6900,hostfwd=tcp::2222-:22 \
        -device e1000,netdev=net0 \
        -vnc :0,password=on \
        -display sdl \
        -drive file="$QCOW2_FILE",format=qcow2,if=virtio
fi

echo ""
echo "✅ Тест завершен" 
