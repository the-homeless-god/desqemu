#!/bin/bash

echo "🚀 DESQEMU Alpine Linux MicroVM Runner"
echo "====================================="

QCOW2_IMAGE="QCOW2_IMAGE_PLACEHOLDER"
QEMU_ARCH="QEMU_ARCH_PLACEHOLDER"
MEMORY="512M"

if [ ! -f "$QCOW2_IMAGE" ]; then
    echo "❌ QCOW2 образ не найден: $QCOW2_IMAGE"
    echo "Убедитесь что файл находится в текущей директории."
    exit 1
fi

if ! command -v qemu-system-$QEMU_ARCH &> /dev/null; then
    echo "❌ QEMU для архитектуры $QEMU_ARCH не установлен!"
    echo "Установите: sudo apt-get install qemu-system-$QEMU_ARCH"
    exit 1
fi

echo "💾 Образ: $QCOW2_IMAGE ($(du -h $QCOW2_IMAGE | cut -f1))"
echo "🧠 Память: $MEMORY"
echo "🌐 Порты: 8080→8080, 5900→5900, 2222→22"
echo ""
echo "🔗 После запуска:"
echo "   Web: http://localhost:8080"
echo "   VNC: localhost:5900"
echo "   SSH: ssh desqemu@localhost -p 2222"
echo ""

# Determine if we can use KVM (Linux only)
KVM_OPTS=""
if [[ "$OSTYPE" == "linux-gnu"* ]] && [ -r /dev/kvm ]; then
    KVM_OPTS="-enable-kvm -cpu host"
    echo "🚀 Используем KVM ускорение"
else
    KVM_OPTS="-cpu max"
    echo "⚠️ KVM недоступен, используем эмуляцию"
fi

echo "▶️ Запускаем QEMU MicroVM..."

# Start QEMU MicroVM with networking
qemu-system-$QEMU_ARCH \
    -M microvm,x-option-roms=off,isa-serial=off,rtc=off \
    -m $MEMORY \
    -no-acpi \
    $KVM_OPTS \
    -nodefaults \
    -no-user-config \
    -nographic \
    -no-reboot \
    -device virtio-serial-device \
    -chardev stdio,id=virtiocon0 \
    -device virtconsole,chardev=virtiocon0 \
    -drive id=root,file=$QCOW2_IMAGE,format=qcow2,if=none \
    -device virtio-blk-device,drive=root \
    -netdev user,id=mynet0,hostfwd=tcp:127.0.0.1:8080-:8080,hostfwd=tcp:127.0.0.1:5900-:5900,hostfwd=tcp:127.0.0.1:2222-:22 \
    -device virtio-net-device,netdev=mynet0 \
    -device virtio-rng-device 
