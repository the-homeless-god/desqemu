# QEMU Manager - Универсальный скрипт управления QEMU

## Обзор

`scripts/qemu-manager.sh` - это универсальный скрипт для управления QEMU, который используется во всех частях проекта DESQEMU:

- **GitHub Actions** - для проверки и установки QEMU в CI/CD
- **Templates** - для встраивания в Neutralino.js приложения
- **Локальная разработка** - для проверки окружения

## Возможности

### ✅ Автоматическое определение платформы
- macOS (Homebrew)
- Linux (APT, YUM, DNF, Pacman)
- Windows (ручная установка)

### ✅ Поддержка архитектур
- x86_64 (по умолчанию)
- aarch64/arm64

### ✅ Команды
- `check` - проверка доступности QEMU
- `install` - установка QEMU
- `version` - получение версии
- `path` - получение пути к QEMU
- `test` - тестирование QEMU

## Использование

### Базовое использование

```bash
# Проверить QEMU
./scripts/qemu-manager.sh check

# Установить QEMU
./scripts/qemu-manager.sh install

# Получить версию
./scripts/qemu-manager.sh version

# Получить путь
./scripts/qemu-manager.sh path

# Протестировать
./scripts/qemu-manager.sh test
```

### С параметрами

```bash
# Для конкретной архитектуры
./scripts/qemu-manager.sh --arch aarch64 check

# С подробным выводом
./scripts/qemu-manager.sh --verbose version

# Без автоматической установки
./scripts/qemu-manager.sh --no-install check
```

### В GitHub Actions

```yaml
- name: Check QEMU
  run: ./scripts/qemu-manager.sh check

- name: Install QEMU if needed
  run: ./scripts/qemu-manager.sh install
```

### В JavaScript (Neutralino.js)

```javascript
// Инициализация
const qemuUtils = new QemuUtils();

// Проверка статуса
const status = await qemuUtils.checkQemuStatus();
if (status.available) {
    console.log('QEMU найден:', status.version);
}

// Установка
const result = await qemuUtils.installQemu();

// Запуск VM
const command = qemuUtils.buildQemuCommand('vm.qcow2', {
    memory: '2G',
    cpus: 4,
    ports: { 8080: 8080 }
});
```

## Интеграция в проекте

### 1. GitHub Actions Workflow

```yaml
- name: Setup QEMU
  run: |
    ./scripts/qemu-manager.sh check || ./scripts/qemu-manager.sh install
```

### 2. Build Scripts

```bash
# В scripts/build-desktop-app.sh
./scripts/qemu-manager.sh --arch $arch check || ./scripts/qemu-manager.sh --arch $arch install
```

### 3. Templates

```javascript
// В templates/neutralino-app/resources/js/app.js
this.qemuUtils = new QemuUtils();
await this.qemuUtils.checkQemuStatus();
```

### 4. Legacy Scripts

```bash
# В scripts/download-qemu.sh
"$SCRIPT_DIR/qemu-manager.sh" --arch "$ARCHITECTURE" check
```

## Преимущества унификации

### 🔧 Единая логика
- Один скрипт для всех платформ
- Консистентное поведение
- Легкое сопровождение

### 🚀 Автоматизация
- Автоматическое определение платформы
- Автоматическая установка через пакетные менеджеры
- Интеграция с CI/CD

### 🛡️ Надежность
- Проверка доступности
- Тестирование функциональности
- Обработка ошибок

### 📦 Портативность
- Работает в GitHub Actions
- Работает в Neutralino.js
- Работает локально

## Примеры вывода

### Успешная проверка
```
🔍 Проверяем доступность QEMU...
✅ QEMU найден
📋 Версия: QEMU emulator version 10.0.2
📁 Путь: /opt/homebrew/bin/qemu-system-x86_64
```

### Установка
```
🔧 Устанавливаем QEMU для macos...
🍎 Установка через Homebrew...
✅ QEMU успешно установлен!
```

### Ошибка
```
⚠️ QEMU не найден
🔧 Попытка автоматической установки...
❌ Установка QEMU не удалась
```

## Конфигурация

### Переменные окружения

```bash
# Архитектура (по умолчанию: x86_64)
QEMU_ARCH=x86_64

# Версия QEMU (по умолчанию: 8.2.0)
QEMU_VERSION=8.2.0

# Бинарный файл (по умолчанию: qemu-system-x86_64)
QEMU_BINARY=qemu-system-x86_64
```

### Параметры командной строки

```bash
-a, --arch ARCH        # Архитектура
-v, --version VERSION  # Версия QEMU
-b, --binary BINARY    # Имя бинарного файла
-n, --no-install       # Не устанавливать автоматически
--verbose              # Подробный вывод
-h, --help            # Справка
```

## Поддержка платформ

| Платформа | Пакетный менеджер | Команда установки |
|-----------|-------------------|-------------------|
| macOS | Homebrew | `brew install qemu` |
| Ubuntu/Debian | APT | `sudo apt install qemu-system-x86` |
| CentOS/RHEL | YUM | `sudo yum install qemu-system-x86_64` |
| Fedora | DNF | `sudo dnf install qemu-system-x86_64` |
| Arch Linux | Pacman | `sudo pacman -S qemu` |
| Windows | - | Ручная установка |

## Troubleshooting

### QEMU не найден
```bash
# Проверить установку
./scripts/qemu-manager.sh check

# Установить вручную
./scripts/qemu-manager.sh install
```

### Ошибка установки
```bash
# Подробный вывод
./scripts/qemu-manager.sh --verbose install

# Проверить пакетный менеджер
which brew  # macOS
which apt   # Ubuntu
```

### Проблемы с правами
```bash
# Проверить права
ls -la scripts/qemu-manager.sh

# Установить права
chmod +x scripts/qemu-manager.sh
```

## Разработка

### Добавление новой платформы

1. Обновите функцию `detect_platform()`
2. Добавьте новый case в `get_package_manager()`
3. Добавьте логику установки в `install_qemu()`

### Тестирование

```bash
# Тест всех команд
./scripts/qemu-manager.sh check
./scripts/qemu-manager.sh version
./scripts/qemu-manager.sh path
./scripts/qemu-manager.sh test

# Тест с параметрами
./scripts/qemu-manager.sh --arch aarch64 check
./scripts/qemu-manager.sh --verbose version
```

## Лицензия

MIT License - см. файл LICENSE в корне проекта. 
