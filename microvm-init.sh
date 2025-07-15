#!/bin/bash

# DESQEMU Alpine Linux MicroVM Init Script
# Based on MergeBoard approach: https://mergeboard.com/blog/2-qemu-microvm-docker/

echo "🚀 DESQEMU Alpine MicroVM starting..."

# Mount essential filesystems
mount -t proc proc /proc
mount -t sysfs sysfs /sys
mount -t devtmpfs devtmpfs /dev
mount -t tmpfs tmpfs /tmp
mount -t tmpfs tmpfs /run

# Create necessary directories
mkdir -p /dev/pts /dev/shm
mount -t devpts devpts /dev/pts
mount -t tmpfs tmpfs /dev/shm

# Setup network (if available)
if [ -e /sys/class/net/eth0 ]; then
    echo "🌐 Настраиваем сеть..."
    ip link set eth0 up
    # Try DHCP first, fallback to static
    if ! udhcpc -i eth0 -n -q; then
        echo "⚠️ DHCP failed, using static IP..."
        ip addr add 10.0.2.15/24 dev eth0
        ip route add default via 10.0.2.2
    fi
fi

# Setup hostname
echo "desqemu-alpine" > /proc/sys/kernel/hostname

# Start basic services
echo "🛠️ Запускаем базовые сервисы..."

# Start syslog if available
if [ -x /sbin/syslogd ]; then
    /sbin/syslogd
fi

# Start SSH daemon if available
if [ -x /usr/sbin/sshd ]; then
    # Generate host keys if they don't exist
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A
    fi
    /usr/sbin/sshd -D &
    echo "🔐 SSH сервер запущен"
fi

# Start Podman service
if [ -x /usr/bin/podman ]; then
    echo "🐳 Podman доступен"
fi

# Check for docker-compose.yml in home directory
if [ -f /home/desqemu/docker-compose.yml ]; then
    echo "📋 Найден docker-compose.yml, запускаем..."
    cd /home/desqemu
    
    # Parse first service port for browser
    FIRST_PORT=$(grep -A 10 "ports:" docker-compose.yml | grep -E "^\s*-\s*\"?[0-9]+:" | head -1 | sed 's/.*"\?\([0-9]\+\):.*/\1/')
    
    # Start docker-compose
    if [ -x /usr/bin/docker-compose ]; then
        su desqemu -c "docker-compose up -d"
        echo "🚀 Docker Compose запущен"
        
        # Start browser if X11 available and port found
        if [ -n "$FIRST_PORT" ] && [ -x /usr/bin/chromium ]; then
            echo "🌐 Открываем браузер на порту $FIRST_PORT..."
            su desqemu -c "DISPLAY=:0 chromium --no-sandbox --disable-dev-shm-usage http://localhost:$FIRST_PORT &"
        fi
    elif [ -x /usr/bin/podman-compose ]; then
        su desqemu -c "podman-compose up -d"
        echo "🚀 Podman Compose запущен"
    fi
fi

# Check for custom entrypoint
if [ -f /home/desqemu/entrypoint.sh ]; then
    echo "🎯 Выполняем кастомный entrypoint..."
    su desqemu -c "cd /home/desqemu && bash entrypoint.sh &"
fi

echo "✅ DESQEMU Alpine MicroVM ready!"
echo "🌐 Web: http://localhost:8080"
echo "🖥️ VNC: localhost:5900"
echo "🔐 SSH: ssh desqemu@localhost -p 2222"

# Start shell for interactive use
exec /bin/bash 
