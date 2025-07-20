# 🚀 DESQEMU Alpine Linux MicroVM

Проект создания безопасных виртуальных машин на базе Alpine Linux для запуска Docker Compose приложений.

## 🎯 Концепция

Этот проект реализует подход **"Docker-to-MicroVM"**, описанный в статье [MergeBoard: Execute Docker Containers as QEMU MicroVMs](https://mergeboard.com/blog/2-qemu-microvm-docker/).

Основная идея - объединить **безопасность виртуальных машин** с **удобством Docker экосистемы**:

- 🔒 **Полная изоляция** на уровне гипервизора QEMU
- 🐳 **Docker совместимость** - используем существующие образы и compose файлы
- ⚡ **Скорость MicroVM** - быстрый запуск (~200ms для ядра)
- 🎯 **Простота использования** - автоматический парсинг docker-compose.yml

## 📦 Что создается в GitHub Actions

Наш CI/CD pipeline автоматически создает **4 типа артефактов** для каждой архитектуры:

### 1. 🐳 Docker образ (`desqemu-alpine-docker-*.tar.gz`)

Полноценный Docker образ с Alpine Linux и всеми необходимыми инструментами:

- Podman + Docker CLI + Docker Compose
- Chromium + X11/VNC для GUI приложений
- SSH сервер + Python 3 + Node.js
- Автоматический парсинг docker-compose.yml

### 2. 📁 Rootfs архив (`desqemu-alpine-rootfs-*.tar.gz`)

Файловая система для использования в chroot окружениях:

- Готов для распаковки в любую систему
- Содержит все программы и конфигурации
- Может использоваться для создания кастомных образов

### 3. 🚀 QEMU MicroVM (`desqemu-alpine-microvm-*.qcow2`)

**Главный продукт** - готовый к запуску qcow2-образ для QEMU:

- Создан по методике MergeBoard
- Кастомный init-скрипт с автоматическими функциями
- Готов к запуску одной командой
- Полная поддержка сетевых интерфейсов

### 4. 📦 Портативный QEMU архив (`desqemu-portable-microvm-*.tar.gz`)

**Автономная MicroVM** - включает QEMU бинарники и файлы VM:

- Не требует отдельной установки QEMU
- Портативный для разных систем
- Включает скрипты управления (старт/стоп/статус)
- Полная MicroVM среда в одном архиве

## 🏗️ Архитектура решения

```shell
Docker Ecosystem          Security Layer             QEMU MicroVM
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ docker-compose  │  ──▶  │ Alpine Linux    │  ──▶  │ QEMU Hypervisor │
│ Docker images   │       │ + Podman        │       │ + virtio devices│
│ Existing tools  │       │ + init script   │       │ + networking    │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

## 🔧 Автоматические функции MicroVM

Наш кастомный init-скрипт (встроенный в Docker образ) обеспечивает:

### 🌐 Сетевая настройка

- Автоматический DHCP с fallback на статический IP
- Проброс портов на хост (8080, 5900, 2222)
- Настройка hostname и маршрутизации

### 🐳 Docker Compose автозапуск

- Автоматическое обнаружение `/home/desqemu/docker-compose.yml`
- Парсинг портов из compose файла
- Запуск через Podman Compose
- Автоматическое открытие в браузере

### 🔐 Системные сервисы

- SSH сервер с автогенерацией ключей
- Syslog для логирования
- Монтирование виртуальных файловых систем
- Управление процессами

### 🖥️ Автоматический десктоп

- **X11 окружение** с fluxbox оконным менеджером
- **Chromium в полноэкранном режиме** (kiosk mode)
- **VNC сервер** для удаленного доступа
- **Автозапуск** при старте системы

### 🎯 Кастомизация

- Поддержка кастомных `entrypoint.sh` скриптов
- Возможность монтирования папок через 9p
- Инъекция файлов через guestfish

### 🚀 GitHub Action

- **Автоматическая сборка** десктопных приложений из Docker Compose
- **Портативные архивы** с QEMU бинарниками
- **Кроссплатформенность** - x86_64 и aarch64
- **Автоматический десктоп** - X11 + Chromium в kiosk режиме

## 📋 Поддерживаемые архитектуры

GitHub Actions создает образы для:

- **x86_64** (Intel/AMD 64-bit)
- **aarch64** (ARM 64-bit)
- **arm64** (ARM 64-bit alternative)
- **amd64** (AMD 64-bit alternative)

## 🚀 Использование

### 1. GitHub Action (рекомендуется)

Превратите любой Docker Compose приложение в портативное десктопное приложение:

```yaml
# .github/workflows/build.yml
name: Build Desktop App

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        architecture: [x86_64, aarch64]
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Use DESQEMU Desktop App Builder
        uses: the-homeless-god/desqemu@master
        with:
          docker-compose-file: 'docker-compose.yml'
          app-name: 'my-app'
          app-description: 'My Awesome Application'
          app-icon: 'app-icon.svg'
          target-architectures: '${{ matrix.architecture }}'
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: my-app-${{ matrix.architecture }}
          path: |
            ${{ steps.build.outputs.portable-archive }}
            ${{ steps.build.outputs.qcow2-image }}
            ${{ steps.build.outputs.desktop-app }}
```

### 2. GitHub Container Registry

```bash
# Запуск готового образа
docker run -it --privileged \
  -p 8080:8080 -p 5900:5900 -p 2222:22 \
  ghcr.io/the-homeless-god/desqemu-alpine:latest
```

### 2. Портативный QEMU архив (установка не требуется)

```bash
# Скачать портативный архив
curl -O https://raw.githubusercontent.com/the-homeless-god/desqemu/master/utils/download-portable.sh
chmod +x download-portable.sh
./download-portable.sh the-homeless-god/desqemu

# Распаковать и запустить
tar -xzf desqemu-portable-microvm-*.tar.gz
cd x86_64  # или ваша архитектура
./start-microvm.sh
```

### 3. Локальная сборка MicroVM

```bash
# Скачайте артефакты из GitHub Actions
# Запустите готовый скрипт
./run-microvm.sh

### 4. Тестирование автоматического десктопа

```bash
# Запуск теста с автоматическим десктопом
./test-desktop-startup.sh

# Подключение VNC для просмотра десктопа
vncviewer localhost:5900  # пароль: desqemu
```

### 5. Нативные десктопные приложения

```bash
# Создание нативных приложений
./scripts/create-neutralino-desktop.sh \
  --portable-archive my-app-portable-x86_64.tar.gz \
  --app-name "My App" \
  --qcow2 my-app.qcow2

# Результат:
# - my-app.exe (Windows)
# - my-app.dmg (macOS)
# - my-app.AppImage (Linux)
```
```

### С вашим docker-compose.yml

```bash
# Создайте compose файл
echo 'version: "3"
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"' > my-compose.yml

# Инжектируйте в образ
guestfish -a desqemu-alpine-microvm-*.qcow2 -m /dev/sda \
  copy-in my-compose.yml /home/desqemu/

# Запустите
./run-microvm.sh
```

## 🌐 Доступные порты

- **8080** → Ваше веб-приложение (автоопределяется из compose)
- **5900** → VNC сервер (пароль: desqemu)
- **2222** → SSH доступ (пользователь: desqemu)

## 🛠️ Технические детали

### Команда запуска QEMU

```bash
qemu-system-x86_64 \
    -M microvm,x-option-roms=off,isa-serial=off,rtc=off \
    -m 512M \
    -no-acpi \
    -cpu max \
    -nodefaults \
    -no-user-config \
    -nographic \
    -no-reboot \
    -device virtio-serial-device \
    -chardev stdio,id=virtiocon0 \
    -device virtconsole,chardev=virtiocon0 \
    -drive id=root,file=desqemu-alpine-microvm-*.qcow2,format=qcow2,if=none \
    -device virtio-blk-device,drive=root \
    -netdev user,id=mynet0,hostfwd=tcp:127.0.0.1:8080-:8080,hostfwd=tcp:127.0.0.1:5900-:5900,hostfwd=tcp:127.0.0.1:2222-:22 \
    -device virtio-net-device,netdev=mynet0 \
    -device virtio-rng-device
```

### Структура файлов проекта

```shell
desqemu/
├── 📁 scripts/                   # Скрипты сборки и утилиты
│   ├── build-portable.sh        # Основной сборщик портативных архивов
│   ├── create-*.sh             # Генераторы документации и контента
│   ├── test-portable-local.sh   # Инструменты локального тестирования
│   └── README.md               # Документация скриптов
├── 📁 utils/                     # Пользовательские утилиты
│   ├── download-portable.sh     # Скачивание портативных архивов
│   └── README.md               # Документация утилит
├── 📁 examples/                  # Примеры Docker Compose
├── Dockerfile                   # Сборка Alpine образа
├── .github/workflows/
│   └── alpine-podman-distribution.yml  # CI/CD pipeline
└── docs/
    ├── README_RU.md            # Документация (русский)
    └── README_EN.md            # Документация (английский)
```

## 🔍 Отладка и мониторинг

### Логи системы

```bash
# SSH подключение
ssh desqemu@localhost -p 2222

# Просмотр логов
journalctl -f                  # Системные логи
podman logs <container>        # Логи контейнера
dmesg                         # Логи ядра
```

### Мониторинг ресурсов

```bash
htop                          # Процессы и память
podman ps                     # Запущенные контейнеры
podman-compose ps            # Статус compose сервисов
netstat -tlnp                # Открытые порты
```

## 🎯 Примеры использования

### Простое веб-приложение

```yaml
version: '3'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

### Комплексное приложение

```yaml
version: '3'
services:
  frontend:
    image: node:alpine
    ports:
      - "3000:3000"
    depends_on:
      - backend
  
  backend:
    image: python:alpine
    ports:
      - "8000:8000"
    depends_on:
      - database
  
  database:
    image: postgres:alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_PASSWORD: secret
```

## 🔗 Связанные проекты

- **MergeBoard Blog**: [Execute Docker Containers as QEMU MicroVMs](https://mergeboard.com/blog/2-qemu-microvm-docker/)
- **Alpine Linux**: [https://alpinelinux.org/](https://alpinelinux.org/)
- **QEMU**: [https://www.qemu.org/](https://www.qemu.org/)
- **Podman**: [https://podman.io/](https://podman.io/)

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Протестируйте на разных архитектурах
5. Создайте Pull Request

## 📄 Лицензия

Этот проект распространяется под лицензией BSD 3-Clause с дополнительными условиями для коммерческого использования. См. файл [LICENSE](../LICENSE).

**💡 Коммерческое использование**: Если вы используете это программное обеспечение в коммерческих целях, свяжитесь для обсуждения лицензионных условий:

- 📧 Email: <zimtir@mail.ru>  
- 💬 Telegram: t.me/the_homeless_god

**🙏 Обязательное указание автора**: При любом использовании необходимо указывать автора "Marat Zimnurov" и ссылку на исходный репозиторий.

## 👨‍💻 Автор

**Marat Zimnurov** - Создатель и разработчик DESQEMU

- 📧 Email: <zimtir@mail.ru>
- 💬 Telegram: [@the_homeless_god](https://t.me/the_homeless_god)
- 🐙 GitHub: [@the-homeless-god](https://github.com/the-homeless-god)

---

**DESQEMU** - мост между миром контейнеров и виртуальных машин! 🚀
