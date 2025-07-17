#!/bin/bash
echo "🛑 Останавливаем тестовую VM..."
pkill -f "qemu-system-x86_64"
pkill -f "websockify"
rm -f /tmp/test-vnc-vm.pid
echo "✅ Тестовая VM остановлена"
