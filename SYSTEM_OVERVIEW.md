# 🔍 Схема работы DESQEMU

## 📋 Архитектура системы

```
Пользователь
    ↓
GitHub Repository (docker-compose.yml)
    ↓
GitHub Action (the-homeless-god/desqemu@master)
    ↓
scripts/build-desktop-app.sh
    ↓
1. Скачивание QEMU бинарников
2. Создание Alpine образа
3. Конвертация Docker → QCOW2
4. Создание портативных архивов
5. Создание нативных приложений
    ↓
Результат:
- Портативные архивы (.tar.gz)
- QCOW2 образы
- Нативные приложения (.exe, .dmg, .AppImage)
```

## 🚀 Процесс сборки

### 1. Входные данные
- `docker-compose.yml` - приложение пользователя
- `app-name` - название приложения
- `app-description` - описание
- `app-icon` - иконка (опционально)

### 2. GitHub Action выполняет:
```bash
# Скачивание QEMU
./scripts/download-qemu.sh --arch x86_64 --version 8.2.0

# Создание Alpine образа
./scripts/create-alpine-image.sh --version 3.22.0 --arch x86_64

# Конвертация Docker Compose в QCOW2
./scripts/docker-compose-to-qcow2.sh --compose-file docker-compose.yml

# Создание портативного архива
./scripts/create-portable-archive.sh --qcow2 app.qcow2 --qemu-dir qemu-x86_64

# Создание нативного приложения
./scripts/create-neutralino-desktop.sh --portable-archive app-portable.tar.gz --app-name "My App"
```

### 3. Результат
- **Портативные архивы**: включают QEMU + QCOW2
- **QCOW2 образы**: готовые виртуальные машины
- **Нативные приложения**: .exe, .dmg, .AppImage

## 🖥️ Автоматический десктоп

### В Alpine Linux VM:
```bash
# Автозапуск при старте системы
scripts/desqemu-services.start
    ↓
scripts/start-desktop.sh
    ↓
1. Xvfb :1 -screen 0 1280x800x24 -ac &
2. fluxbox &
3. chromium --kiosk --app="http://localhost:8080" &
4. x11vnc -display :1 -forever -usepw -create -shared -rfbport 5900 -passwd desqemu &
```

### Результат:
- **X11 окружение** с fluxbox
- **Chromium в kiosk режиме** на http://localhost:8080
- **VNC сервер** на localhost:5900 (пароль: desqemu)
- **SSH доступ** на localhost:2222

## 📦 Структура файлов

```
desqemu/
├── action.yml                    # GitHub Action конфигурация
├── scripts/
│   ├── build-desktop-app.sh     # Главный сборщик
│   ├── create-neutralino-desktop.sh  # Создание нативных приложений
│   ├── start-desktop.sh         # Автозапуск десктопа
│   └── ...
├── templates/
│   └── neutralino-app/          # Шаблон для нативных приложений
├── .github/workflows/
│   └── build-desktop-app.yml    # Основной workflow
└── examples/
    ├── simple-nginx/            # Простой пример
    └── penpot-desktop/          # Penpot пример
```

## 🔧 Ключевые компоненты

### 1. GitHub Action (`action.yml`)
- Входные параметры для настройки сборки
- Выходные параметры для артефактов
- Composite action для переиспользования

### 2. Главный сборщик (`scripts/build-desktop-app.sh`)
- Парсинг параметров
- Создание конфигурации
- Генерация скриптов сборки для каждой архитектуры

### 3. Создание нативных приложений (`scripts/create-neutralino-desktop.sh`)
- Распаковка портативного архива
- Копирование шаблона Neutralino
- Встраивание QEMU бинарников
- Сборка для всех платформ

### 4. Автоматический десктоп (`scripts/start-desktop.sh`)
- Запуск X11 окружения
- Запуск оконного менеджера
- Запуск Chromium в kiosk режиме
- Запуск VNC сервера

## 🌐 Порты и доступ

| Порт | Сервис | Описание |
|------|--------|----------|
| 8080 | Веб-приложение | Основное приложение пользователя |
| 5900 | VNC сервер | Удаленный доступ к десктопу (пароль: desqemu) |
| 2222 | SSH | Командная строка (пользователь: desqemu) |

## 🔒 Безопасность

- **Полная изоляция**: каждое приложение в отдельной VM
- **QEMU гипервизор**: аппаратная виртуализация
- **Alpine Linux**: минимальная поверхность атаки
- **Автоматические обновления**: через GitHub Actions 
