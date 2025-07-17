#!/bin/bash

# Диагностический скрипт для проверки процессов в контексте Neutralino
# Помогает понять, почему isVMRunning() не находит процессы

echo "🔍 Диагностика процессов для Neutralino..."
echo "=========================================="

# Проверяем различные способы поиска QEMU процессов
echo "1. Проверка через pgrep:"
pgrep -f "qemu-system-x86_64" && echo "✅ QEMU процессы найдены" || echo "❌ QEMU процессы не найдены"

echo ""
echo "2. Проверка через ps aux:"
ps aux | grep qemu | grep -v grep || echo "❌ QEMU процессы не найдены в ps aux"

echo ""
echo "3. Проверка PID файла:"
if [ -f "/tmp/desqemu-penpot.pid" ]; then
    echo "✅ PID файл найден: $(cat /tmp/desqemu-penpot.pid)"
    PID=$(cat /tmp/desqemu-penpot.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✅ Процесс с PID $PID существует"
    else
        echo "❌ Процесс с PID $PID не существует"
    fi
else
    echo "❌ PID файл не найден"
fi

echo ""
echo "4. Проверка портов:"
echo "VNC порт 5900:"
lsof -i :5900 2>/dev/null || echo "Порт 5900 не открыт"

echo ""
echo "5. Проверка через which и whereis:"
which qemu-system-x86_64 2>/dev/null || echo "qemu-system-x86_64 не найден в PATH"
whereis qemu-system-x86_64 2>/dev/null || echo "whereis не нашел qemu-system-x86_64"

echo ""
echo "6. Проверка прав доступа к /tmp:"
ls -la /tmp/desqemu-penpot.pid 2>/dev/null || echo "PID файл недоступен"

echo ""
echo "7. Тестовая команда pgrep (как в коде):"
pgrep -f "qemu-system-x86_64" > /dev/null 2>&1
echo "Exit code: $?"

echo ""
echo "8. Проверка через ls PID файла (как в коде):"
ls -la /tmp/desqemu-penpot.pid > /dev/null 2>&1
echo "Exit code: $?"

echo ""
echo "🔍 Диагностика завершена" 
