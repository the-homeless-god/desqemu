#!/bin/bash

# Скрипт для настройки пароля VNC в Alpine Linux

echo "🔐 Настройка пароля VNC в Alpine Linux"
echo "======================================="

# Проверяем, запущен ли QEMU
QEMU_PID=$(pgrep -f "qemu-system-x86_64")
if [ -z "$QEMU_PID" ]; then
    echo "❌ QEMU не запущен. Запускаем..."
    qemu-system-x86_64 -m 1G -smp 2 -vnc :1,password=on -drive file=desqemu-desktop/resources/qcow2/alpine-bootable.qcow2,format=qcow2,if=virtio -daemonize
    sleep 3
    QEMU_PID=$(pgrep -f "qemu-system-x86_64")
fi

echo "✅ QEMU запущен (PID: $QEMU_PID)"

# Создаем expect скрипт для настройки пароля
cat > setup_vnc_password.exp << 'EOF'
#!/usr/bin/expect -f

# Подключаемся к QEMU монитору
spawn telnet localhost 5555

# Ждем приглашения монитора
expect "QEMU.*monitor"

# Устанавливаем пароль VNC
send "change vnc password\r"
expect "Password:"
send "desqemu123\r"
expect "Confirm:"
send "desqemu123\r"

# Проверяем статус VNC
send "info vnc\r"
expect "VNC server"

# Выходим из монитора
send "quit\r"
expect eof
EOF

echo "🔧 Настраиваем пароль VNC..."
expect setup_vnc_password.exp

echo ""
echo "✅ Пароль VNC настроен!"
echo "🔑 Пароль: desqemu123"
echo ""
echo "🌐 Для подключения:"
echo "   • VNC клиент: localhost:5901"
echo "   • Веб-интерфейс: http://localhost:6901"
echo ""
echo "🔧 Для запуска websockify:"
echo "   websockify 6901 localhost:5901 &" 
