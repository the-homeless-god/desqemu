#!/bin/bash

# Скрипт для тестирования VNC подключения к VM
# Запускает VM в фоне и проверяет VNC доступность

echo "🔌 Тестирование VNC подключения к VM..."
echo "========================================"

# Проверяем наличие QCOW2 файла
QCOW2_FILE="desqemu-desktop/resources/qcow2/penpot-microvm.qcow2"

if [ ! -f "$QCOW2_FILE" ]; then
    echo "❌ Ошибка: QCOW2 файл не найден: $QCOW2_FILE"
    exit 1
fi

echo "✅ QCOW2 файл найден: $QCOW2_FILE"

# Проверяем QEMU
if ! command -v qemu-system-x86_64 &> /dev/null; then
    echo "❌ Ошибка: QEMU не установлен"
    exit 1
fi

echo "✅ QEMU найден: $(qemu-system-x86_64 --version | head -1)"

# Останавливаем предыдущие процессы
echo "🧹 Очищаем предыдущие процессы..."
pkill -f "qemu-system-x86_64" 2>/dev/null || true
pkill -f "websockify" 2>/dev/null || true

# Запускаем VM в фоне
echo ""
echo "🚀 Запускаем VM в фоне с VNC..."
echo ""

# Команда QEMU с VNC
qemu-system-x86_64 \
    -m 1G \
    -smp 2 \
    -netdev user,id=net0,hostfwd=tcp::8080-:8080,hostfwd=tcp::5900-:5900,hostfwd=tcp::6900-:6900,hostfwd=tcp::2222-:22 \
    -device e1000,netdev=net0 \
    -vnc :0,password=on \
    -daemonize \
    -pidfile /tmp/test-vnc-vm.pid \
    -drive file="$QCOW2_FILE",format=qcow2,if=virtio

# Ждем запуска
echo "⏳ Ждем запуска VM..."
sleep 5

# Проверяем PID файл
if [ -f "/tmp/test-vnc-vm.pid" ]; then
    echo "✅ VM запущена, PID: $(cat /tmp/test-vnc-vm.pid)"
else
    echo "❌ VM не запустилась"
    exit 1
fi

# Проверяем процессы
echo "🔍 Проверяем процессы QEMU:"
ps aux | grep qemu | grep -v grep || echo "QEMU процессы не найдены"

# Проверяем порты
echo ""
echo "🔍 Проверяем открытые порты:"
echo "VNC порт 5900:"
lsof -i :5900 2>/dev/null || echo "Порт 5900 не открыт"

echo ""
echo "Web порт 8080:"
lsof -i :8080 2>/dev/null || echo "Порт 8080 не открыт"

# Запускаем websockify для тестирования
echo ""
echo "🔌 Запускаем websockify прокси..."
if command -v ~/Library/Python/3.9/bin/websockify &> /dev/null; then
    ~/Library/Python/3.9/bin/websockify --web=/dev/null 6900 localhost:5900 &
    WEBSOCKIFY_PID=$!
    echo "✅ WebSockify запущен, PID: $WEBSOCKIFY_PID"
    
    # Проверяем WebSocket порт
    echo "🔍 Проверяем WebSocket порт 6900:"
    lsof -i :6900 2>/dev/null || echo "Порт 6900 не открыт"
else
    echo "⚠️  websockify не найден"
fi

echo ""
echo "📋 Информация для подключения:"
echo "   VNC: localhost:5900 (пароль: vnc)"
echo "   WebSocket: localhost:6900"
echo "   Web: http://localhost:8080"
echo ""
echo "💡 Для остановки выполните: ./stop-test-vm.sh"

# Создаем скрипт остановки
cat > stop-test-vm.sh << 'EOF'
#!/bin/bash
echo "🛑 Останавливаем тестовую VM..."
pkill -f "qemu-system-x86_64"
pkill -f "websockify"
rm -f /tmp/test-vnc-vm.pid
echo "✅ Тестовая VM остановлена"
EOF

chmod +x stop-test-vm.sh 
