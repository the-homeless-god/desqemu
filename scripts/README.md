# 🛠️ DESQEMU Build Scripts

Коллекция скриптов для создания портативных архивов DESQEMU с встроенным QEMU.

## 📋 Структура скриптов

### 🏗️ Основные скрипты сборки

- **`build-portable.sh`** - главный скрипт сборки портативного архива
- **`download-qemu.sh`** - скачивание QEMU бинарников из Alpine репозитория  
- **`create-portable-archive.sh`** - создание структуры портативного архива
- **`create-archive.sh`** - упаковка в итоговый tar.gz архив

### 🛠️ Утилиты

- **`create-universal-installer.sh`** - создание универсального установщика
- **`test-portable-local.sh`** - локальное тестирование портативных архивов

### 🐳 Docker скрипты (из Dockerfile)

- **`auto-start-compose.sh`** - автоматический запуск docker-compose с GUI
- **`start-desktop.sh`** - запуск X11/VNC окружения  
- **`desqemu-services.start`** - init скрипт системных сервисов
- **`user-profile.sh`** - приветственное сообщение для пользователя

### 📚 Документация и контент

- **`create-alpine-readme.sh`** - генерация README для Alpine дистрибутива
- **`create-release-notes.sh`** - создание release notes основного релиза
- **`create-portable-release-notes.sh`** - создание release notes портативных архивов
- **`create-quick-start-scripts.sh`** - генерация quick-start скриптов
- **`create-all-docs.sh`** - объединяющий скрипт для создания всей документации

## 🚀 Использование

### Локальная сборка

```bash
# Сборка для текущей архитектуры
./scripts/build-portable.sh x86_64

# Сборка для ARM64
./scripts/build-portable.sh aarch64
```

### Поддерживаемые архитектуры

- **x86_64** - Intel/AMD 64-bit
- **aarch64** - ARM 64-bit  
- **arm64** - ARM 64-bit (альтернативное название)

### Тестирование

```bash
# Полный тест локальной сборки
./test-portable-local.sh
```

## 📦 Результат сборки

После выполнения создаются файлы:

- `desqemu-portable-microvm-{arch}.tar.gz` - портативный архив
- `install-desqemu-portable-{arch}.sh` - установщик для конкретной архитектуры
- `install-desqemu-portable.sh` - универсальный установщик

## 🔧 Структура портативного архива

```
{architecture}/
├── bin/                    # QEMU бинарники
│   ├── qemu-system-x86_64
│   ├── qemu-img
│   └── ...
├── libexec/               # QEMU helper'ы
├── share/qemu/            # QEMU данные (BIOS, etc.)
├── alpine-vm.qcow2        # Готовая микровм
├── bzImage                # Kernel
├── initramfs-virt         # Initramfs
├── start-microvm.sh       # Скрипт запуска
├── stop-microvm.sh        # Скрипт остановки
├── check-status.sh        # Проверка статуса
└── README.md              # Документация
```

## 🌐 GitHub Actions интеграция

Скрипты интегрированы с GitHub Actions workflow в `.github/workflows/alpine-podman-distribution.yml`:

```yaml
- name: 🚀 Создание портативного архива
  run: |
    chmod +x scripts/build-portable.sh
    scripts/build-portable.sh ${{ matrix.architecture }}
```

## 🔍 Отладка

### Проверка скачанных QEMU файлов

```bash
# После выполнения download-qemu.sh
ls -la qemu-portable/{architecture}/usr/bin/qemu-*
```

### Проверка структуры архива

```bash
# Распаковать и посмотреть
tar -tzf desqemu-portable-microvm-x86_64.tar.gz | head -20
```

### Ручной запуск этапов

```bash
# Пошагово
scripts/download-qemu.sh x86_64
scripts/create-portable-archive.sh x86_64  
scripts/create-archive.sh x86_64
```

## 📝 Требования

- **wget** - для скачивания QEMU пакетов
- **tar** - для упаковки/распаковки
- **bash 4+** - для выполнения скриптов

### Установка на разных системах

```bash
# Ubuntu/Debian
sudo apt-get install wget tar

# CentOS/RHEL
sudo yum install wget tar

# macOS
brew install wget gnu-tar
```

## 🐛 Устранение проблем

### QEMU не скачивается

```bash
# Проверить доступность Alpine репозитория
wget -q --spider https://dl-cdn.alpinelinux.org/alpine/v3.19/main/x86_64/

# Проверить версию QEMU в скрипте
grep QEMU_VERSION scripts/download-qemu.sh
```

### Архив не создается

```bash
# Проверить права на запись
ls -la desqemu-portable/

# Проверить место на диске
df -h .
```

### Ошибки в портативном архиве

```bash
# Проверить целостность
tar -tzf desqemu-portable-microvm-x86_64.tar.gz > /dev/null
```

## 🐳 Использование Docker скриптов

### 🚀 auto-start-compose.sh

```bash
# Внутри контейнера
/home/desqemu/auto-start-compose.sh

# Что делает:
# - Анализирует docker-compose.yml
# - Извлекает порты из compose файла  
# - Запускает podman-compose up -d
# - Ожидает готовности сервисов
# - Запускает X11/VNC окружение
# - Открывает Chromium на нужном порту
```

### 🖥️ start-desktop.sh

```bash
# Запуск графического окружения
/home/desqemu/start-desktop.sh

# Доступ через VNC: localhost:5900 (пароль: desqemu)
```

### ⚙️ desqemu-services.start  

```bash
# Системный init скрипт (запускается автоматически)
# - Инициализирует podman machine
# - Запускает веб-сервер на :8080
# - Настраивает VNC пароль
# - Автозапуск compose если есть файл

# Проверить размер
du -h desqemu-portable-microvm-x86_64.tar.gz
```
