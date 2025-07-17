#!/bin/bash

# Скрипт для тестирования VNC с паролем и без пароля

echo "🔍 Тестирование VNC с паролем и без пароля"
echo "============================================="

# Останавливаем предыдущие процессы
pkill -f "qemu-system-x86_64" 2>/dev/null || true
pkill -f websockify 2>/dev/null || true

# Ждем завершения процессов
sleep 2

echo ""
echo "1️⃣ Тест 1: VNC БЕЗ пароля"
echo "---------------------------"

# Запускаем QEMU без пароля
echo "🚀 Запускаем QEMU с VNC без пароля..."
qemu-system-x86_64 -m 1G -smp 2 -vnc :1 -drive file=desqemu-desktop/resources/qcow2/alpine-bootable.qcow2,format=qcow2,if=virtio -daemonize

sleep 3

echo "✅ QEMU запущен"
echo "📊 Проверяем порт 5901..."
lsof -i :5901

echo ""
echo "🌐 Запускаем websockify..."
websockify 6901 localhost:5901 &
sleep 2

echo "📊 Проверяем порт 6901..."
lsof -i :6901

echo ""
echo "🔗 Открываем веб-интерфейс..."
open http://localhost:6901

echo ""
echo "⏳ Ждем 10 секунд для тестирования..."
sleep 10

echo ""
echo "2️⃣ Тест 2: VNC С паролем"
echo "-------------------------"

# Останавливаем предыдущий QEMU
pkill -f "qemu-system-x86_64" 2>/dev/null || true
pkill -f websockify 2>/dev/null || true
sleep 2

# Запускаем QEMU с паролем
echo "🚀 Запускаем QEMU с VNC и паролем..."
qemu-system-x86_64 -m 1G -smp 2 -vnc :1,password=on -drive file=desqemu-desktop/resources/qcow2/alpine-bootable.qcow2,format=qcow2,if=virtio -daemonize

sleep 3

echo "✅ QEMU запущен с паролем"
echo "📊 Проверяем порт 5901..."
lsof -i :5901

echo ""
echo "🌐 Запускаем websockify..."
websockify 6901 localhost:5901 &
sleep 2

echo "📊 Проверяем порт 6901..."
lsof -i :6901

echo ""
echo "🔗 Открываем веб-интерфейс..."
open http://localhost:6901

echo ""
echo "📝 Инструкции для тестирования:"
echo "================================"
echo "1. В первом тесте (без пароля) - должно работать сразу"
echo "2. Во втором тесте (с паролем) - потребуется ввести пароль"
echo "3. Пароль по умолчанию: password"
echo ""
echo "🔧 Для остановки всех процессов:"
echo "pkill -f 'qemu-system-x86_64' && pkill -f websockify" 
