# 🚀 DESQEMU - GitHub Action для создания десктопных приложений

Превратите любой Docker Compose приложение в портативное десктопное приложение с автоматическим запуском.

## 🎯 Что это дает

- **📦 Портативные приложения** - включает QEMU бинарники, не требует установки
- **🖥️ Автоматический десктоп** - X11 + Chromium в полноэкранном режиме
- **🔒 Полная изоляция** - виртуальная машина с QEMU
- **🐳 Docker совместимость** - использует существующие docker-compose.yml
- **📱 Нативные приложения** - .exe, .dmg, .AppImage файлы

## 🚀 Быстрый старт

### 1. Клонирование репозитория
```bash
git clone https://github.com/the-homeless-god/desqemu.git
cd desqemu
```

### 2. Проверка окружения
```bash
./test-system.sh
```

### 3. Проверка QEMU
```bash
# Проверить доступность QEMU
./scripts/qemu-manager.sh check

# Установить QEMU если нужно
./scripts/qemu-manager.sh install
```

### 4. Проверка контейнерных движков (опционально)
```bash
# Определить доступный движок (Docker/Podman)
./scripts/container-manager.sh detect

# Использовать Podman для compose
./scripts/container-manager.sh -e podman compose up -d

# Использовать Docker для compose
./scripts/container-manager.sh -e docker compose up -d
```

### 4. Создание десктопного приложения
```bash
./scripts/build-desktop-app.sh \
  --compose-file examples/nginx-compose.yml \
  --app-name "My App" \
  --app-description "My Desktop Application"
```

### 5. Использование в своем проекте

Создайте GitHub Actions workflow:

```yaml
name: Build Desktop App

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        architecture: [x86_64, aarch64]
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Setup QEMU
        run: |
          ./scripts/qemu-manager.sh check || ./scripts/qemu-manager.sh install
      
      - name: Build Desktop Application
        run: |
          ./scripts/build-desktop-app.sh \
            --compose-file docker-compose.yml \
            --app-name "my-app" \
            --app-description "My Awesome Application"
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: my-app-${{ matrix.architecture }}
          path: build/*/portable-*.tar.gz
```

## 📦 Результат

После успешной сборки вы получите:

### Портативные архивы
- `my-app-portable-x86_64.tar.gz` - для Intel/AMD
- `my-app-portable-aarch64.tar.gz` - для ARM

### QCOW2 образы
- `my-app-x86_64.qcow2` - образ виртуальной машины
- `my-app-aarch64.qcow2` - образ для ARM

### Нативные десктопные приложения
- `my-app-desktop-x86_64.exe` - Windows исполняемый файл
- `my-app-desktop-x86_64.dmg` - macOS приложение
- `my-app-desktop-x86_64.AppImage` - Linux приложение

## 🏃‍♂️ Как использовать

### Портативный архив

```bash
# Скачайте и распакуйте
curl -LO https://github.com/your-repo/releases/download/v1.0.0/my-app-portable-x86_64.tar.gz
tar -xzf my-app-portable-x86_64.tar.gz
cd my-app-portable-x86_64

# Запустите приложение
./start.sh
```

### Нативные десктопные приложения

```bash
# Windows
my-app-desktop-x86_64.exe

# macOS
open my-app-desktop-x86_64.dmg

# Linux
./my-app-desktop-x86_64.AppImage
```

## 🖥️ Автоматический десктоп

При запуске приложения автоматически:

1. **Запускается X11 окружение**
2. **Открывается Chromium в полноэкранном режиме**
3. **Запускается VNC сервер для удаленного доступа**
4. **Никаких логинов - сразу рабочий стол!**

## 🌐 Порты

По умолчанию пробрасываются порты:

- **8080** → Ваше веб-приложение
- **5900** → VNC сервер (пароль: `desqemu`)
- **2222** → SSH доступ

## ⚙️ Конфигурация

### Параметры GitHub Action

| Параметр | Описание | Обязательный | По умолчанию |
|----------|----------|--------------|--------------|
| `docker-compose-file` | Путь к docker-compose.yml | ✅ | `docker-compose.yml` |
| `app-name` | Название приложения | ✅ | `desqemu-app` |
| `app-description` | Описание приложения | ❌ | `DESQEMU Desktop Application` |
| `app-icon` | Путь к иконке (SVG) | ❌ | `app-icon.svg` |
| `target-architectures` | Архитектуры (через запятую) | ❌ | `x86_64,aarch64` |
| `qemu-version` | Версия QEMU | ❌ | `8.2.0` |
| `alpine-version` | Версия Alpine Linux | ❌ | `3.22.0` |

## 🔧 Поддерживаемые приложения

### Веб-приложения
- **WordPress** - CMS платформа
- **Nextcloud** - файловое хранилище
- **Penpot** - дизайн и прототипирование
- **Gitea** - Git сервер
- **Jitsi** - видеоконференции
- **Rocket.Chat** - чат платформа

### API сервисы
- **PostgreSQL** - база данных
- **Redis** - кэш сервер
- **Elasticsearch** - поисковый движок
- **Kafka** - потоковая платформа

### Инструменты разработки
- **Jenkins** - CI/CD сервер
- **SonarQube** - анализ кода
- **Grafana** - мониторинг
- **Prometheus** - метрики

## 📚 Примеры

Смотрите папку `examples/` для готовых примеров:

- `examples/simple-nginx/` - Простой nginx пример
- `examples/penpot-desktop/` - Penpot приложение

## 🔧 QEMU Manager

DESQEMU использует универсальный скрипт `scripts/qemu-manager.sh` для управления QEMU во всех частях проекта:

### Команды
```bash
# Проверить QEMU
./scripts/qemu-manager.sh check

# Установить QEMU
./scripts/qemu-manager.sh install

# Получить версию
./scripts/qemu-manager.sh version

# Протестировать
./scripts/qemu-manager.sh test
```

### Поддерживаемые платформы
- **macOS** - Homebrew (`brew install qemu`)
- **Ubuntu/Debian** - APT (`sudo apt install qemu-system-x86`)
- **CentOS/RHEL** - YUM (`sudo yum install qemu-system-x86_64`)
- **Fedora** - DNF (`sudo dnf install qemu-system-x86_64`)
- **Arch Linux** - Pacman (`sudo pacman -S qemu`)

Подробная документация: [QEMU_MANAGER_README.md](QEMU_MANAGER_README.md)

## 🐳 Container Manager

DESQEMU поддерживает как Docker, так и Podman для локальной разработки:

### Команды
```bash
# Определить доступный движок
./scripts/container-manager.sh detect

# Использовать Podman
./scripts/container-manager.sh -e podman compose up -d

# Использовать Docker
./scripts/container-manager.sh -e docker compose up -d

# Очистить образы и контейнеры
./scripts/container-manager.sh clean
```

### Поддерживаемые движки
- **Podman** - рекомендуемый (безопаснее, не требует root)
- **Docker** - классический вариант
- **Автоопределение** - автоматически выбирает доступный движок

## 🛠️ Устранение проблем

### QEMU не найден
```bash
# Проверить установку
./scripts/qemu-manager.sh check

# Установить автоматически
./scripts/qemu-manager.sh install
```

### Сборка не запускается
1. Проверьте синтаксис docker-compose.yml
2. Убедитесь, что образы доступны
3. Проверьте логи GitHub Actions

### Приложение не запускается
1. Проверьте порты в docker-compose.yml
2. Убедитесь, что приложение слушает на правильном порту
3. Проверьте логи через VNC (порт 5900)

### VNC не подключается
1. Проверьте, что порт 5900 проброшен
2. Используйте пароль: `desqemu`
3. Проверьте файрвол

## 🤝 Поддержка

- **GitHub Issues**: https://github.com/the-homeless-god/desqemu/issues
- **Документация**: https://github.com/the-homeless-god/desqemu
- **Примеры**: https://github.com/the-homeless-god/desqemu/tree/master/examples

## 📄 Лицензия

MIT License - см. [LICENSE](LICENSE) файл. 
