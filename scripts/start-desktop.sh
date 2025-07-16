#!/bin/bash
export DISPLAY=:1
Xvfb :1 -screen 0 1024x768x16 &
sleep 2
fluxbox &
x11vnc -display :1 -forever -usepw -create &
echo "🖥️  Рабочий стол запущен на display :1"
echo "🌐 VNC доступен на порту 5900 (пароль: desqemu)" 
