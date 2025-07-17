#!/bin/bash

# Скрипт для тестирования DESQEMU Desktop приложения

echo "🧪 Тестирование DESQEMU Desktop приложения"
echo "=========================================="

# Останавливаем предыдущие процессы
pkill -f "neu run" 2>/dev/null || true
sleep 2

# Проверяем наличие необходимых файлов
echo "📁 Проверяем файлы..."
if [ ! -f "resources/index.html" ]; then
    echo "❌ resources/index.html не найден"
    exit 1
fi

if [ ! -f "resources/js/app.js" ]; then
    echo "❌ resources/js/app.js не найден"
    exit 1
fi

if [ ! -f "resources/icons/appIcon.png" ]; then
    echo "❌ resources/icons/appIcon.png не найден"
    exit 1
fi

if [ ! -f "resources/js/novnc/utils/novnc_proxy" ]; then
    echo "❌ noVNC прокси не найден"
    exit 1
fi

echo "✅ Все необходимые файлы найдены"

# Проверяем QEMU
echo "🔧 Проверяем QEMU..."
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "✅ QEMU найден"
else
    echo "❌ QEMU не найден"
    echo "💡 Установите QEMU: brew install qemu"
fi

# Проверяем QCOW2 образ
echo "📦 Проверяем QCOW2 образ..."
if [ -f "resources/qcow2/alpine-bootable.qcow2" ]; then
    echo "✅ QCOW2 образ найден"
else
    echo "❌ QCOW2 образ не найден"
    echo "💡 Создайте образ: ./install-alpine-to-qcow2.sh"
fi

echo ""
echo "🚀 Запускаем приложение..."
echo "=========================="
echo ""
echo "📝 Инструкции:"
echo "1. Приложение должно открыться в новом окне"
echo "2. Нажмите 'Запустить VM' для запуска виртуальной машины"
echo "3. Нажмите 'Показать дисплей VM' для отображения VNC"
echo ""
echo "🛑 Для остановки: Ctrl+C"

# Запускаем приложение
neu run 
