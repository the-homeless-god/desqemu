# 🧪 Руководство по тестированию DESQEMU

## 📋 Быстрый тест системы

### 1. Локальное тестирование

```bash
# Запустите тест системы
./test-system.sh
```

Этот тест проверит:
- ✅ Наличие всех необходимых файлов
- ✅ Работоспособность основных скриптов
- ✅ Валидность примеров
- ✅ Наличие шаблонов

### 2. Тестирование отдельных компонентов

#### Тестирование QEMU
```bash
# Проверьте/установите QEMU для x86_64
./scripts/download-qemu.sh x86_64

# Проверьте, что QEMU работает
qemu-system-x86_64 --version
```

#### Тестирование сборки
```bash
# Протестируйте главный сборщик
./scripts/build-desktop-app.sh --help
```

## 🚀 Полное тестирование через GitHub Actions

### Шаг 1: Создайте тестовый репозиторий

```bash
# Создайте новую папку
mkdir test-desqemu-app
cd test-desqemu-app

# Инициализируйте git
git init
```

### Шаг 2: Добавьте docker-compose.yml

```yaml
# docker-compose.yml
version: '3.8'

services:
  test-app:
    image: nginx:alpine
    container_name: test-app
    restart: unless-stopped
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    environment:
      - NGINX_HOST=localhost
      - NGINX_PORT=80
```

### Шаг 3: Создайте HTML файл

```bash
mkdir html
```

```html
<!-- html/index.html -->
<!DOCTYPE html>
<html>
<head>
    <title>DESQEMU Test App</title>
</head>
<body>
    <h1>🎉 DESQEMU работает!</h1>
    <p>Это тестовое приложение для проверки DESQEMU GitHub Action.</p>
</body>
</html>
```

### Шаг 4: Создайте GitHub Actions workflow

```bash
mkdir -p .github/workflows
```

```yaml
# .github/workflows/build.yml
name: Test DESQEMU Build

on:
  push:
    branches: [ master ]
  pull_request:
    branches: [ master ]
  workflow_dispatch:

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
          app-name: 'test-desqemu-app'
          app-description: 'Test Application for DESQEMU'
          app-icon: 'app-icon.svg'
          target-architectures: '${{ matrix.architecture }}'
      
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: test-app-${{ matrix.architecture }}
          path: |
            ${{ steps.build.outputs.portable-archive }}
            ${{ steps.build.outputs.qcow2-image }}
            ${{ steps.build.outputs.neutralino-app }}
            ${{ steps.build.outputs.desktop-executables }}
```

### Шаг 5: Запустите тест

```bash
# Добавьте файлы в git
git add .

# Создайте коммит
git commit -m "Add test DESQEMU application"

# Создайте репозиторий на GitHub и добавьте remote
git remote add origin https://github.com/your-username/test-desqemu-app.git

# Запушьте в репозиторий
git push -u origin master
```

### Шаг 6: Проверьте результаты

1. **Перейдите в GitHub репозиторий**
2. **Откройте вкладку Actions**
3. **Дождитесь завершения сборки**
4. **Скачайте артефакты**

## 📦 Тестирование результатов

### Портативный архив

```bash
# Скачайте и распакуйте
curl -LO https://github.com/your-username/test-desqemu-app/releases/download/v1.0.0/test-desqemu-app-portable-x86_64.tar.gz
tar -xzf test-desqemu-app-portable-x86_64.tar.gz
cd test-desqemu-app-portable-x86_64

# Запустите приложение
./start.sh
```

### Нативные приложения

```bash
# Windows
./test-desqemu-app-desktop-x86_64.exe

# macOS
open test-desqemu-app-desktop-x86_64.dmg

# Linux
./test-desqemu-app-desktop-x86_64.AppImage
```

## 🔍 Что проверять

### 1. Автоматический запуск
- ✅ QEMU запускается автоматически
- ✅ Alpine Linux загружается
- ✅ X11 окружение запускается
- ✅ Chromium открывается в полноэкранном режиме
- ✅ Ваше приложение доступно на http://localhost:8080

### 2. Порты и доступ
- ✅ **8080** - ваше веб-приложение
- ✅ **5900** - VNC сервер (пароль: desqemu)
- ✅ **2222** - SSH доступ

### 3. VNC подключение
```bash
# Установите VNC клиент
# macOS: Screen Sharing
# Windows: VNC Viewer
# Linux: vinagre

# Подключитесь к localhost:5900
# Пароль: desqemu
```

### 4. SSH доступ
```bash
# Подключитесь по SSH
ssh -p 2222 desqemu@localhost
# Пароль: desqemu
```

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

### QEMU не установлен
1. **macOS**: `brew install qemu`
2. **Ubuntu/Debian**: `sudo apt install qemu-system-x86`
3. **CentOS/RHEL**: `sudo yum install qemu-system-x86_64`
4. **Windows**: Скачайте с https://www.qemu.org/download/

## 📚 Примеры для тестирования

### Простой nginx
```bash
cd examples/simple-nginx
# Используйте готовый пример
```

### Penpot приложение
```bash
cd examples/penpot-desktop
# Используйте готовый пример
```

## 🎯 Ожидаемые результаты

После успешного тестирования вы должны получить:

1. **Портативные архивы** (.tar.gz) с QEMU и QCOW2
2. **QCOW2 образы** готовых виртуальных машин
3. **Нативные приложения** (.exe, .dmg, .AppImage)
4. **Автоматический запуск** с Chromium в полноэкранном режиме
5. **VNC доступ** для удаленного управления
6. **SSH доступ** для командной строки

## 🎉 Успешное тестирование

Если все работает правильно, вы увидите:
- ✅ Автоматический запуск QEMU
- ✅ Загрузку Alpine Linux
- ✅ Открытие Chromium в полноэкранном режиме
- ✅ Ваше приложение на http://localhost:8080
- ✅ Возможность подключения по VNC
- ✅ SSH доступ к виртуальной машине

## 🔧 Автоустановка QEMU

Система автоматически установит QEMU если он не найден:

- **macOS**: `brew install qemu`
- **Ubuntu/Debian**: `sudo apt install qemu-system-x86`
- **CentOS/RHEL**: `sudo yum install qemu-system-x86_64`
- **Arch Linux**: `sudo pacman -S qemu`
- **Windows**: Ручная установка с https://www.qemu.org/download/ 
