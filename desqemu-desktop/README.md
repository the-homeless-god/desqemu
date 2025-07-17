# 🚀 DESQEMU Desktop - Penpot

> **Прототип концепции "Docker-to-Desktop"** с использованием Neutralino.js + QEMU MicroVM

![DESQEMU Desktop](https://img.shields.io/badge/DESQEMU-Desktop-6366f1?style=for-the-badge)
![Neutralino.js](https://img.shields.io/badge/Neutralino.js-4.14.1-blue?style=for-the-badge)
![QEMU](https://img.shields.io/badge/QEMU-MicroVM-red?style=for-the-badge)

## 🎯 Концепция

Превращаем **любое Docker Compose приложение** в **нативное desktop приложение**:

```
Docker Compose → QCOW2 MicroVM → Neutralino Desktop App → Native .exe/.app/.deb
```

## ✨ Что это дает?

- 🖥️ **Нативные desktop приложения** из любого веб-сервиса
- 🪶 **Легковесность** - 180MB vs 2GB+ у Electron
- 🔒 **Безопасность VM** - полная изоляция на уровне QEMU
- 🌍 **Кроссплатформенность** - macOS, Windows, Linux
- 🚀 **Простота** - один клик для запуска

## 🎨 Демо: Penpot Desktop

Этот прототип превращает [Penpot](https://penpot.app) (веб-дизайн платформа) в нативное desktop приложение.

### Скриншоты

```
┌─────────────────────────────────────┐
│ 🚀 Penpot Desktop  [Powered by DESQEMU] │ 
├─────────────────────────────────────┤
│ 🔧 QEMU Status: ✅ Доступен         │
│    Версия: 8.1.0                   │
│    Путь: /usr/bin/qemu-system-x86_64│
├─────────────────────────────────────┤
│ 🎨 Penpot MicroVM: 🟢 Запущена     │
│    ▶️ Запустить Penpot             │
│    🌍 Открыть Penpot (localhost:8080)│
│    🖥️ VNC подключение              │
└─────────────────────────────────────┘
```

## 🛠️ Установка и запуск

### Предварительные требования

```bash
# 1. Установите Node.js
# https://nodejs.org/

# 2. Установите Neutralino CLI
npm install -g @neutralinojs/neu

# 3. Установите QEMU (опционально - приложение может установить автоматически)
# macOS: brew install qemu
# Linux: sudo apt install qemu-system-x86
# Windows: https://www.qemu.org/download/
```

### Запуск прототипа

```bash
# 1. Клонируйте и перейдите в папку
cd desqemu-desktop

# 2. Настройте Neutralino
npm run setup

# 3. Запустите в режиме разработки
npm run dev

# Или запустите как desktop приложение
npm start
```

### Сборка для продакшена

```bash
# Сборка для всех платформ
npm run build

# Упаковка в архив
npm run package

# Результат в dist/
# - desqemu-desktop-linux_x64
# - desqemu-desktop-win_x64.exe  
# - desqemu-desktop-mac_x64.app
```

## 🏗️ Архитектура

### Компоненты

```
┌──────────────────────────────────────┐
│           Desktop App                │
│         (Neutralino.js)              │
├──────────────────────────────────────┤
│        QEMU Manager                  │
│    • Проверка/установка QEMU        │
│    • Управление процессами           │
│    • Мониторинг состояния            │
├──────────────────────────────────────┤
│         QCOW2 Assets                 │
│    • penpot-microvm.qcow2           │
│    • Embedded в приложение           │
├──────────────────────────────────────┤
│       QEMU MicroVM                   │
│    • Alpine Linux + Podman          │
│    • Auto-start Penpot              │
│    • Port forwarding                 │
└──────────────────────────────────────┘
```

### Процесс запуска

1. **Проверка QEMU** - `qemu-system-x86_64 --version`
2. **Автоустановка** - `brew install qemu` / `apt install qemu`
3. **Запуск VM** - `qemu-system-x86_64 -drive penpot.qcow2`
4. **Автооткрытие** - `http://localhost:8080`
5. **Мониторинг** - отслеживание процесса

## 📁 Структура проекта

```
desqemu-desktop/
├── 📄 neutralino.config.json    # Конфигурация Neutralino
├── 📄 package.json              # npm скрипты и зависимости
├── 📁 resources/                # Ресурсы приложения
│   ├── 📄 index.html           # Главный UI
│   ├── 📁 css/
│   │   └── 📄 style.css        # Современные стили
│   ├── 📁 js/
│   │   ├── 📄 neutralino.js    # Neutralino клиент
│   │   └── 📄 app.js          # Основная логика
│   ├── 📁 icons/               # Иконки приложения
│   └── 📁 qcow2/              # QCOW2 образы
│       └── 📄 penpot-microvm.qcow2
├── 📁 extensions/               # Расширения (пусто)
└── 📁 dist/                    # Собранные бинарники
```

## 🚀 Возможности

### ✅ Реализовано

- 🔍 **Автопроверка QEMU** - определение версии и пути
- 📥 **Автоустановка** - для macOS/Linux через пакетные менеджеры  
- 🖥️ **UI управления** - современный интерфейс с состояниями
- 🚀 **Запуск VM** - через `Neutralino.os.spawnProcess()`
- 📊 **Мониторинг** - отслеживание процессов QEMU
- 🌐 **Автооткрытие** - браузера на нужном порту
- 📋 **Логирование** - детальные логи операций
- 🔄 **Управление** - старт/стоп/рестарт VM

### 🔨 Планируется

- 📦 **QCOW2 bundling** - включение образов в бинарник
- 🎯 **Автосоздание** - генерация desktop apps из docker-compose.yml
- 🍎 **macOS подписывание** - для App Store
- 🪟 **Windows installer** - MSI/NSIS пакеты
- 🐧 **Linux packaging** - .deb/.rpm/.AppImage
- 🔧 **Настройки VM** - память, CPU, порты
- 📱 **Уведомления** - системные нотификации

## 🌟 Примеры использования

### Создание "WordPress Desktop"

```bash
# 1. Создаем QCOW2 из docker-compose.yml
./create-microvm.sh wordpress-compose.yml

# 2. Создаем Neutralino приложение  
./create-desktop-app.sh wordpress-microvm.qcow2 "WordPress Desktop"

# 3. Собираем для всех платформ
./build-desktop-app.sh

# Результат:
# - wordpress-desktop.exe     (Windows)
# - WordPress Desktop.app     (macOS)  
# - wordpress-desktop.deb     (Linux)
```

### Поддерживаемые приложения

Любое веб-приложение с Docker Compose:

- 🎨 **Penpot** - дизайн платформа
- 📝 **Ghost** - блог платформа  
- 🗂️ **NextCloud** - файловое хранилище
- 📊 **Grafana** - мониторинг дашборды
- 🎵 **Funkwhale** - музыкальный стриминг
- 🔐 **Bitwarden** - менеджер паролей

## 🔧 API Reference

### QEMU Manager

```javascript
const app = new DesqemuApp();

// Проверка QEMU
await app.checkQemuStatus();

// Установка QEMU
await app.installQemu();

// Управление VM
await app.startMicroVM();
await app.stopMicroVM();
await app.restartMicroVM();

// Мониторинг
const isRunning = await app.isVMRunning();
```

### Neutralino API Usage

```javascript
// Выполнение команд
const result = await Neutralino.os.execCommand('qemu-system-x86_64 --version');

// Запуск процессов  
const process = await Neutralino.os.spawnProcess('qemu-system-x86_64 ...');

// Системная информация
const platform = await Neutralino.os.getEnv('OS');

// Открытие ссылок
await Neutralino.os.open('http://localhost:8080');
```

## 🤝 Расширение концепции

### Для других приложений

1. **Скопируйте** структуру `desqemu-desktop/`
2. **Замените** QCOW2 образ на свой
3. **Настройте** `neutralino.config.json`
4. **Обновите** UI и логику в `app.js`
5. **Соберите** для целевых платформ

### Интеграция с CI/CD

```yaml
# .github/workflows/build-desktop.yml
name: Build Desktop App
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
      - run: npm install -g @neutralinojs/neu
      - run: npm run setup && npm run build
      - uses: actions/upload-artifact@v3
        with:
          name: desktop-binaries
          path: dist/
```

## 📈 Преимущества vs альтернативы

| Решение | Размер | Скорость | Безопасность | Совместимость |
|---------|--------|----------|--------------|---------------|
| **DESQEMU Desktop** | 180MB | ⚡ Быстро | 🔒 VM изоляция | ✅ Все ОС |
| Electron | 2GB+ | 🐌 Медленно | 🚫 Процесс | ✅ Все ОС |
| Tauri | 50MB | ⚡ Быстро | 🔶 Процесс | ✅ Все ОС |
| Docker Desktop | 4GB+ | 🐌 Медленно | 🔒 VM изоляция | ✅ Все ОС |

## 🐛 Известные ограничения

- 🔧 **Требует QEMU** - нужна установка на хост-системе
- 📦 **Размер образов** - QCOW2 файлы могут быть большими
- 🔊 **Нет аудио** - пока не реализована поддержка звука
- 🖱️ **VM интерфейс** - взаимодействие через веб-браузер

## 📚 Ресурсы

- 📖 [Neutralino.js Documentation](https://neutralino.js.org/docs/)
- 🐧 [QEMU Documentation](https://www.qemu.org/docs/master/)
- 🌐 [MergeBoard Article](https://mergeboard.com/blog/2-qemu-microvm-docker/)
- 🏠 [DESQEMU Repository](https://github.com/the-homeless-god/desqemu)

## 🤝 Участие в проекте

Этот прототип демонстрирует возможности концепции. Для полной реализации нужна помощь:

- 🔧 **Backend разработчики** - автоматизация создания QCOW2
- 🎨 **Frontend разработчики** - улучшение UI/UX
- 📦 **DevOps инженеры** - CI/CD для всех платформ
- 🧪 **QA тестеры** - тестирование на разных ОС

---

**Сделано с ❤️ для сообщества DESQEMU**
