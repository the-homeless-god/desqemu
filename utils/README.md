# 🛠️ Утилиты DESQEMU

Папка с утилитарными скриптами для пользователей DESQEMU.

## 📥 download-portable.sh

Скрипт для автоматического скачивания портативных архивов DESQEMU с GitHub Releases.

### Использование

```bash
# Скачать в текущую папку
curl -O https://raw.githubusercontent.com/the-homeless-god/desqemu/master/utils/download-portable.sh
chmod +x download-portable.sh

# Скачать последний релиз
./download-portable.sh the-homeless-god/desqemu

# Скачать конкретную версию
./download-portable.sh the-homeless-god/desqemu v1.0.0
```

### Особенности

- ✅ Автоматическое определение архитектуры (x86_64, aarch64, arm64)
- ✅ Скачивание последнего релиза или конкретной версии
- ✅ Проверка целостности загруженных файлов
- ✅ Подробные инструкции после скачивания

### Что скачивается

- `desqemu-portable-microvm-{arch}.tar.gz` - портативный архив с QEMU и микровм
- `install-desqemu-portable.sh` - универсальный установщик

### Пример вывода

```shell
📥 DESQEMU Portable Downloader
==============================
🖥️  Обнаружена архитектура: x86_64 → x86_64
🔍 Получаем информацию о последнем релизе...
🏷️  Используем тег: v1.0.0
📦 Скачиваем портативный архив...
✅ Скачивание завершено!

🚀 Для запуска:
  tar -xzf desqemu-portable-microvm-x86_64.tar.gz
  cd x86_64
  ./start-microvm.sh
```

## 🚀 Быстрый старт

После скачивания и установки:

```bash
# Распаковать и запустить
tar -xzf desqemu-portable-microvm-*.tar.gz
cd x86_64  # или ваша архитектура
./start-microvm.sh

# Доступ к микровм:
# VNC: localhost:5900 (пароль: desqemu)
# SSH: ssh desqemu@localhost -p 2222
# Web: http://localhost:8080
```
