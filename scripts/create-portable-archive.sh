#!/bin/bash

set -e

ARCHITECTURE="$1"
if [ -z "$ARCHITECTURE" ]; then
    echo "❌ Не указана архитектура"
    echo "Использование: $0 <architecture>"
    exit 1
fi

echo "🚀 Создаем портативный архив QEMU для $ARCHITECTURE..."

# Create portable structure
mkdir -p "desqemu-portable/$ARCHITECTURE"
cd "desqemu-portable/$ARCHITECTURE"

# Copy QEMU binaries
if [ -d "../../qemu-portable/$ARCHITECTURE/usr/bin" ]; then
    mkdir -p bin
    cp -r "../../qemu-portable/$ARCHITECTURE/usr/bin/"* bin/ 2>/dev/null || true
    echo "✅ Скопированы QEMU бинарники"
fi

if [ -d "../../qemu-portable/$ARCHITECTURE/usr/libexec" ]; then
    mkdir -p libexec  
    cp -r "../../qemu-portable/$ARCHITECTURE/usr/libexec/"* libexec/ 2>/dev/null || true
    echo "✅ Скопированы QEMU libexec"
fi

if [ -d "../../qemu-portable/$ARCHITECTURE/usr/share/qemu" ]; then
    mkdir -p share/qemu
    cp -r "../../qemu-portable/$ARCHITECTURE/usr/share/qemu/"* share/qemu/ 2>/dev/null || true
    echo "✅ Скопированы QEMU данные"
fi

# Copy microvm files
if [ -f "../../alpine-vm.qcow2" ]; then
    cp "../../alpine-vm.qcow2" ./
    echo "✅ Скопирован alpine-vm.qcow2"
fi

if [ -f "../../kernel/bzImage" ]; then
    cp "../../kernel/bzImage" ./
    echo "✅ Скопирован kernel/bzImage"
fi

if [ -f "../../initramfs-virt" ]; then
    cp "../../initramfs-virt" ./
    echo "✅ Скопирован initramfs-virt"
fi

# Create startup scripts
cat > start-microvm.sh << 'EOF'
#!/bin/bash

echo "🚀 DESQEMU Portable MicroVM Launcher"
echo "===================================="

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set QEMU paths
export PATH="$SCRIPT_DIR/bin:$PATH"
export QEMU_SYSTEM_DIR="$SCRIPT_DIR/libexec"

# Default parameters
MEMORY=${MEMORY:-512M}
CPU_CORES=${CPU_CORES:-2}
VNC_PORT=${VNC_PORT:-5900}
SSH_PORT=${SSH_PORT:-2222}
WEB_PORT=${WEB_PORT:-8080}

echo "💾 Память: $MEMORY"
echo "🔧 CPU ядер: $CPU_CORES" 
echo "🌐 VNC порт: $VNC_PORT"
echo "🔐 SSH порт: $SSH_PORT"
echo "🌍 Web порт: $WEB_PORT"
echo ""

# Check if qemu-system-x86_64 exists
if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "❌ QEMU не найден в $SCRIPT_DIR/bin"
    echo "Убедитесь что архив распакован правильно"
    exit 1
fi

# Check if VM file exists
if [ ! -f "$SCRIPT_DIR/alpine-vm.qcow2" ]; then
    echo "❌ Файл alpine-vm.qcow2 не найден"
    echo "Убедитесь что архив распакован правильно"
    exit 1
fi

echo "🚀 Запускаем микровм..."
echo "📝 VNC пароль: desqemu"
echo "🔐 SSH: ssh desqemu@localhost -p $SSH_PORT"
echo "🌐 Web: http://localhost:$WEB_PORT"
echo ""
echo "Для остановки нажмите Ctrl+C"
echo ""

# Launch QEMU
qemu-system-x86_64 \
  -enable-kvm \
  -machine q35,accel=kvm:tcg \
  -cpu host \
  -smp $CPU_CORES \
  -m $MEMORY \
  -drive file="$SCRIPT_DIR/alpine-vm.qcow2",format=qcow2,if=virtio \
  -kernel "$SCRIPT_DIR/bzImage" \
  -initrd "$SCRIPT_DIR/initramfs-virt" \
  -append "console=ttyS0 root=/dev/vda1 rw quiet" \
  -netdev user,id=net0,hostfwd=tcp::$SSH_PORT-:22,hostfwd=tcp::$WEB_PORT-:8080 \
  -device virtio-net-pci,netdev=net0 \
  -vnc :$(($VNC_PORT - 5900)) \
  -vga virtio \
  -display vnc \
  -daemonize \
  -pidfile "$SCRIPT_DIR/qemu.pid" \
  -serial stdio
EOF

chmod +x start-microvm.sh

cat > stop-microvm.sh << 'EOF'
#!/bin/bash

echo "🛑 Останавливаем DESQEMU MicroVM..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/qemu.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "🔄 Останавливаем процесс QEMU (PID: $PID)..."
        kill "$PID"
        rm -f "$PID_FILE"
        echo "✅ MicroVM остановлена"
    else
        echo "⚠️  Процесс QEMU уже не запущен"
        rm -f "$PID_FILE"
    fi
else
    echo "⚠️  PID файл не найден. Возможно MicroVM уже остановлена"
fi
EOF

chmod +x stop-microvm.sh

cat > check-status.sh << 'EOF'
#!/bin/bash

echo "📊 DESQEMU MicroVM Status"
echo "========================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PID_FILE="$SCRIPT_DIR/qemu.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        echo "✅ MicroVM запущена (PID: $PID)"
        echo "🌐 VNC: localhost:5900"
        echo "🔐 SSH: ssh desqemu@localhost -p 2222"  
        echo "🌍 Web: http://localhost:8080"
    else
        echo "❌ MicroVM не запущена"
        rm -f "$PID_FILE"
    fi
else
    echo "❌ MicroVM не запущена"
fi
EOF

chmod +x check-status.sh

# Create README
cat > README.md << EOF
# 🚀 DESQEMU Portable MicroVM

Портативная микровм с Alpine Linux + Podman + Chromium.
Не требует установленного QEMU - все включено в архив!

## 🎯 Что включено:

- **QEMU** - эмулятор виртуальных машин
- **Alpine Linux MicroVM** - готовая микровм
- **Podman + Docker CLI** - контейнеры
- **Chromium** - веб-браузер
- **VNC + SSH** - удаленный доступ

## 🚀 Быстрый запуск:

\`\`\`bash
# Запустить микровм
./start-microvm.sh

# Проверить статус
./check-status.sh

# Остановить микровм
./stop-microvm.sh
\`\`\`

## 🔧 Настройка:

Переменные окружения для \`start-microvm.sh\`:

\`\`\`bash
# Изменить память (по умолчанию 512M)
MEMORY=1G ./start-microvm.sh

# Изменить количество ядер (по умолчанию 2)
CPU_CORES=4 ./start-microvm.sh

# Изменить порты
VNC_PORT=5901 SSH_PORT=2223 WEB_PORT=8081 ./start-microvm.sh
\`\`\`

## 🌐 Доступ:

После запуска микровм доступна по адресам:

- **VNC:** localhost:5900 (пароль: desqemu)
- **SSH:** ssh desqemu@localhost -p 2222 (пароль: desqemu)
- **Web:** http://localhost:8080

## 📋 Системные требования:

- Linux $ARCHITECTURE
- 1+ GB свободной памяти
- KVM поддержка (опционально, для лучшей производительности)

## 🆘 Устранение проблем:

\`\`\`bash
# Если не запускается с KVM, отредактируйте start-microvm.sh:
# Замените: -enable-kvm -machine q35,accel=kvm:tcg
# На: -machine q35,accel=tcg

# Проверить доступность портов:
netstat -tuln | grep -E ':(5900|2222|8080)'

# Логи QEMU будут в консоли
\`\`\`

---

**Архитектура:** $ARCHITECTURE
**Создано:** $(date)
**DESQEMU:** https://github.com/the-homeless-god/desqemu
EOF

echo "✅ Создана структура портативного архива для $ARCHITECTURE"
cd "../.." 
