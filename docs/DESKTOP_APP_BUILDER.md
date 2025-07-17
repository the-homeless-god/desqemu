# 🚀 DESQEMU Desktop App Builder

**Революционная система автоматической сборки desktop приложений из Docker Compose файлов**

## 🎯 Концепция

Превращает любой Docker Compose файл в полноценное desktop приложение:

```shell
Docker Compose → QCOW2 MicroVM → Neutralino Desktop App → Native .exe/.app/.deb
```

**Результат**: Пользователь скачивает `penpot-desktop.exe`, запускает - получает нативное desktop приложение!

## 🏗️ Архитектура

1. **Шаблон Neutralino** (`templates/neutralino-app/`) - базовый шаблон приложения
2. **Генератор** (`scripts/generate-desktop-app.sh`) - создает приложения из шаблона
3. **GitHub Actions** (`.github/workflows/build-desktop-app.yml`) - автоматическая сборка
4. **QCOW2 Integration** - интеграция с существующими скриптами DESQEMU

## 🚀 Использование через GitHub Actions

### 1. Перейдите в Actions на GitHub

1. Откройте <https://github.com/the-homeless-god/desqemu/actions>
2. Выберите workflow "🚀 DESQEMU Desktop App Builder"
3. Нажмите "Run workflow"

### 2. Заполните форму

```yaml
Название приложения: penpot-desktop
Описание: Penpot Design Tool Desktop
Порт приложения: 9001
Создать GitHub Release: ✅

Содержимое docker-compose.yml:
version: "3.8"
services:
  penpot-frontend:
    image: "penpotapp/frontend:latest"
    ports:
      - "9001:80"
    # ... остальная конфигурация
```

### 3. Результат

Через 10-15 минут в GitHub Releases появится:

- `penpot-desktop-win-x64.zip` (Windows)
- `penpot-desktop-linux-x64.tar.gz` (Linux)
- `penpot-desktop-mac-x64.tar.gz` (macOS Intel)
- `penpot-desktop-mac-arm64.tar.gz` (macOS Apple Silicon)

## 🛠️ Локальная разработка

### Создание приложения локально

```bash
# Создание приложения из Docker Compose файла
./scripts/generate-desktop-app.sh \
  "penpot-desktop" \
  "examples/penpot-desktop-compose.yml" \
  "Penpot Design Tool" \
  "9001"

# Переход в директорию приложения
cd build/desktop-apps/penpot-desktop

# Установка Neutralino CLI (если не установлен)
npm install -g @neutralinojs/neu

# Обновление бинарников
neu update

# Запуск в режиме разработки
neu run

# Сборка для production
neu build --release

# Создание архива
cd dist && zip -r ../penpot-desktop.zip .
```

## 📁 Структура сгенерированного приложения

```
build/desktop-apps/penpot-desktop/
├── neutralino.config.json    # Конфигурация приложения
├── package.json              # NPM пакет
├── README.md                 # Документация
├── bin/                      # Neutralino бинарники
│   ├── neutralino-linux_x64
│   ├── neutralino-mac_arm64
│   ├── neutralino-mac_x64
│   └── neutralino-win_x64.exe
├── resources/
│   ├── index.html           # Главная страница
│   ├── css/style.css        # Стили интерфейса
│   ├── js/app.js            # Логика приложения
│   ├── docker-compose.yml   # Пользовательский compose файл
│   ├── icons/               # Иконки приложения
│   └── qcow2/              # QCOW2 образы
│       └── app.qcow2
└── dist/                   # Собранное приложение
    ├── penpot-desktop       # Исполняемый файл (Linux/macOS)
    ├── penpot-desktop.exe   # Исполняемый файл (Windows)
    └── resources/          # Ресурсы
```

## 🎨 Кастомизация шаблона

### Обновление интерфейса

Отредактируйте файлы в `templates/neutralino-app/resources/`:

- `index.html` - структура интерфейса
- `css/style.css` - внешний вид
- `js/app.js` - логика работы с QEMU

### Добавление новых иконок

Поместите иконки в `templates/neutralino-app/resources/icons/`:

- `appIcon.png` - иконка приложения
- `trayIcon.png` - иконка в системном трее

### Изменение конфигурации

Редактируйте `templates/neutralino-app/neutralino.config.json`:

```json
{
  "applicationId": "org.desqemu.{{APP_ID}}",
  "modes": {
    "window": {
      "title": "🚀 {{APP_TITLE}}",
      "width": 1200,
      "height": 800
    }
  }
}
```

## 🔧 Интеграция с существующими скриптами

### QCOW2 Generation

В `scripts/generate-desktop-app.sh` можно интегрировать существующие скрипты:

```bash
# Создание QCOW2 образа
if [[ -f "scripts/create-qemu-vm.sh" ]]; then
    echo "🐳 Создание QCOW2 с помощью существующих скриптов..."
    scripts/create-qemu-vm.sh "$COMPOSE_FILE" "$APP_DIR/resources/qcow2/"
fi
```

### Alpine Integration

Использование существующего Dockerfile:

```bash
# Сборка Alpine образа с приложением
docker build -t "desqemu-$APP_NAME:latest" .

# Экспорт в QCOW2 формат
scripts/docker-to-qcow2.sh "desqemu-$APP_NAME:latest" "$APP_DIR/resources/qcow2/app.qcow2"
```

## 📈 Примеры использования

### Penpot Desktop

```bash
./scripts/generate-desktop-app.sh \
  "penpot-desktop" \
  "examples/penpot-desktop-compose.yml" \
  "Penpot Design Tool" \
  "9001"
```

### WordPress Desktop

```bash
./scripts/generate-desktop-app.sh \
  "wordpress-desktop" \
  "examples/wordpress-compose.yml" \
  "WordPress Content Management" \
  "8080"
```

### Nextcloud Desktop

```bash
./scripts/generate-desktop-app.sh \
  "nextcloud-desktop" \
  "examples/nextcloud-compose.yml" \
  "Nextcloud File Sync" \
  "8080"
```

## 🎯 Преимущества

### Для пользователей

- **Простота**: Скачал → Запустил → Работает
- **Безопасность**: Полная изоляция через виртуализацию
- **Производительность**: Легче Electron (~180MB vs 2GB+)
- **Универсальность**: Работает на Windows/macOS/Linux

### Для разработчиков

- **Скорость**: Автоматическая сборка в GitHub Actions
- **Простота**: Один Docker Compose файл → Desktop приложение
- **Гибкость**: Любое веб-приложение → Native app
- **Масштабируемость**: Шаблонная система

## 🔮 Будущие возможности

- **Auto-updater**: Автоматическое обновление приложений
- **App Store**: Магазин готовых desktop приложений
- **Cloud Sync**: Синхронизация настроек через облако
- **Multi-VM**: Запуск нескольких микро-ВМ в одном приложении
- **Performance Monitoring**: Мониторинг производительности

## 🤝 Вклад в проект

1. Добавляйте новые шаблоны в `templates/`
2. Улучшайте генератор в `scripts/generate-desktop-app.sh`
3. Оптимизируйте GitHub Actions workflow
4. Создавайте примеры в `examples/`

---

**🏗️ DESQEMU Desktop App Builder** - революция в создании desktop приложений!

**🔗 GitHub**: <https://github.com/the-homeless-god/desqemu>
