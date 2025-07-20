# 🚀 DESQEMU - GitHub Action для создания десктопных приложений

Превратите любой Docker Compose приложение в портативное десктопное приложение с автоматическим запуском.

## 🎯 Что это дает

- **📦 Портативные приложения** - включает QEMU бинарники, не требует установки
- **🖥️ Автоматический десктоп** - X11 + Chromium в полноэкранном режиме
- **🔒 Полная изоляция** - виртуальная машина с QEMU
- **🐳 Docker совместимость** - использует существующие docker-compose.yml
- **📱 Нативные приложения** - .exe, .dmg, .AppImage файлы

## 🚀 Быстрый старт

### 1. Создайте репозиторий с вашим приложением

```bash
mkdir my-app
cd my-app
```

### 2. Добавьте docker-compose.yml

```yaml
version: '3.8'

services:
  my-app:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./data:/usr/share/nginx/html
```

### 3. Создайте GitHub Actions workflow

Создайте файл `.github/workflows/build.yml`:

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
            ${{ steps.build.outputs.neutralino-app }}
            ${{ steps.build.outputs.desktop-executables }}
```

### 4. Запустите сборку

```bash
git add .
git commit -m "Add desktop app configuration"
git push origin master
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

## 🛠️ Устранение проблем

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
