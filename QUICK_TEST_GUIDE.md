# 🚀 Быстрое руководство по тестированию DESQEMU

## 📋 Пошаговое тестирование

### 1. Базовая проверка системы

```bash
# Запустите тест системы
./test-system.sh
```

Этот тест проверит:
- ✅ Наличие всех файлов
- ✅ Работоспособность скриптов
- ✅ Установку QEMU
- ✅ Наличие примеров

### 2. Тестирование QEMU Manager

```bash
# Проверить QEMU
./scripts/qemu-manager.sh check

# Получить версию
./scripts/qemu-manager.sh version

# Протестировать QEMU
./scripts/qemu-manager.sh test
```

### 3. Тестирование сборки

```bash
# Проверить справку
./scripts/build-desktop-app.sh --help

# Создать тестовое приложение
./scripts/build-desktop-app.sh \
  --compose-file examples/test-app/docker-compose.yml \
  --app-name "Test App" \
  --app-description "Test Application" \
  --architectures "x86_64"
```

### 4. Проверка результатов

```bash
# Посмотреть созданные файлы
ls -la build/

# Проверить конфигурацию
cat build/*/app-config.json
```

## 🧪 Полное тестирование

### Локальное тестирование

1. **Создайте тестовое приложение**
```bash
mkdir my-test-app
cd my-test-app
```

2. **Создайте docker-compose.yml**
```yaml
version: '3.8'
services:
  test-app:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

3. **Создайте HTML файл**
```bash
mkdir html
echo "<h1>Hello DESQEMU!</h1>" > html/index.html
```

4. **Запустите сборку**
```bash
../desqemu/scripts/build-desktop-app.sh \
  --compose-file docker-compose.yml \
  --app-name "My Test App" \
  --app-description "My Test Application"
```

### GitHub Actions тестирование

1. **Создайте репозиторий на GitHub**

2. **Добавьте workflow**
```yaml
# .github/workflows/test.yml
name: Test DESQEMU

on:
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup QEMU
        run: |
          ./scripts/qemu-manager.sh check || ./scripts/qemu-manager.sh install
      
      - name: Build Test App
        run: |
          ./scripts/build-desktop-app.sh \
            --compose-file examples/test-app/docker-compose.yml \
            --app-name "Test App" \
            --app-description "Test Application"
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: test-app
          path: build/
```

## 🔍 Что проверять

### ✅ Успешные результаты

1. **QEMU Manager**
```
✅ QEMU найден
📋 Версия: QEMU emulator version 10.0.2
📁 Путь: /opt/homebrew/bin/qemu-system-x86_64
```

2. **Сборка**
```
✅ Build configuration created successfully!
📁 Build directory: build/Test App
🚀 To build: cd build/Test App && ./build-all.sh
```

3. **Созданные файлы**
```
build/
├── Test App/
│   ├── app-config.json
│   ├── build-all.sh
│   ├── README.md
│   └── x86_64/
│       ├── build.sh
│       ├── scripts/
│       └── templates/
```

### ❌ Проблемы и решения

1. **QEMU не найден**
```bash
# Установить QEMU
./scripts/qemu-manager.sh install
```

2. **Node.js не установлен**
```bash
# macOS
brew install node

# Ubuntu
sudo apt install nodejs npm
```

3. **Контейнерные движки (опционально)**
```bash
# Podman (рекомендуется)
# macOS
brew install podman

# Ubuntu
sudo apt install podman

# Docker (альтернатива)
# macOS
brew install docker

# Ubuntu
sudo apt install docker.io
```

## 🎯 Ожидаемые результаты

После успешного тестирования у вас должно быть:

- ✅ Работающий QEMU Manager
- ✅ Функциональный скрипт сборки
- ✅ Созданные build директории
- ✅ Готовые к использованию шаблоны

## 📚 Дополнительная документация

- [README.md](README.md) - основная документация
- [QEMU_MANAGER_README.md](QEMU_MANAGER_README.md) - документация по QEMU Manager
- [TESTING_GUIDE.md](TESTING_GUIDE.md) - подробное руководство по тестированию
- [SYSTEM_OVERVIEW.md](SYSTEM_OVERVIEW.md) - обзор системы

## 🚀 Следующие шаги

1. **Создайте свое приложение**
2. **Настройте GitHub Actions**
3. **Запустите полную сборку**
4. **Протестируйте результаты**

Удачи с тестированием! 🎉 
