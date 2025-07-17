# Устранение проблем с DESQEMU Desktop

## Проблема: Приложение застревает на экране загрузки

### Симптомы
- Приложение показывает "Запускаем Penpot..." и не прогрессирует
- Логи показывают ошибки с отсутствующими файлами

### Решение
1. **Проверьте логи**: `tail -20 neutralinojs.log`
2. **Убедитесь, что все файлы на месте**:
   ```bash
   ls -la resources/icons/
   ls -la resources/js/
   ```
3. **Перезапустите приложение**: `neu run`

### Исправленные проблемы
- ✅ Убрали ссылку на отсутствующий `penpot-logo.svg`
- ✅ Исправили методы `showLoadingOverlay` и `hideLoadingOverlay`
- ✅ Добавили метод `showVNCDisplay`
- ✅ Обновили названия с Penpot на DESQEMU

## Проблема: QEMU не найден

### Решение
```bash
# macOS
brew install qemu

# Linux
sudo apt install qemu-system-x86

# Windows
# Скачайте с https://www.qemu.org/download/#windows
```

## Проблема: QCOW2 образ не найден

### Решение
```bash
# Создайте образ Alpine Linux
./install-alpine-to-qcow2.sh
```

## Проблема: noVNC не работает

### Решение
```bash
# Проверьте noVNC
ls -la resources/js/novnc/utils/novnc_proxy

# Установите права
chmod +x resources/js/novnc/utils/novnc_proxy

# Протестируйте отдельно
./test-novnc-integration.sh
```

## Проблема: Приложение не запускается

### Диагностика
```bash
# Проверьте все файлы
./test-app.sh

# Проверьте логи
tail -f neutralinojs.log

# Проверьте процессы
ps aux | grep neu
```

### Решение
1. **Остановите все процессы**:
   ```bash
   pkill -f "neu run"
   pkill -f "qemu-system-x86_64"
   pkill -f "novnc_proxy"
   ```

2. **Очистите кэш**:
   ```bash
   rm -rf .tmp/
   neu run
   ```

## Проблема: VNC не отображается

### Диагностика
```bash
# Проверьте процессы
ps aux | grep -E "(qemu|novnc)"

# Проверьте порты
lsof -i :5901 -i :6901

# Проверьте веб-интерфейс
curl -s http://localhost:6901
```

### Решение
1. **Перезапустите VM**:
   ```bash
   pkill -f "qemu-system-x86_64"
   ./run-alpine-vm-vnc.sh
   ```

2. **Перезапустите noVNC**:
   ```bash
   pkill -f novnc_proxy
   ./start-novnc-proxy.sh
   ```

## Полезные команды

### Проверка состояния
```bash
# Все процессы
ps aux | grep -E "(neu|qemu|novnc)"

# Порты
lsof -i :5901 -i :6901

# Логи
tail -f neutralinojs.log
```

### Остановка всего
```bash
pkill -f "neu run"
pkill -f "qemu-system-x86_64"
pkill -f "novnc_proxy"
```

### Перезапуск
```bash
# Остановите все
pkill -f "neu run" && pkill -f "qemu-system-x86_64" && pkill -f "novnc_proxy"

# Запустите заново
neu run
```

## Тестирование

### Полное тестирование
```bash
./test-app.sh
```

### Тестирование noVNC
```bash
./test-novnc-integration.sh
```

### Тестирование VNC
```bash
./run-alpine-vm-vnc.sh
```

## Логи

### Neutralino логи
```bash
tail -f neutralinojs.log
```

### QEMU логи (если запущен без -daemonize)
```bash
# QEMU логи будут в stdout
```

### noVNC логи
```bash
./resources/js/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6901 --verbose
``` 
