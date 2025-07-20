# 🐳 Container Manager - Универсальный скрипт для Docker и Podman

## Обзор

`scripts/container-manager.sh` - это универсальный скрипт для работы с контейнерными движками, который поддерживает как Docker, так и Podman.

## Возможности

### ✅ Автоматическое определение
- **Podman** (приоритет) - безопаснее, не требует root
- **Docker** - классический вариант
- **Автоопределение** - автоматически выбирает доступный движок

### ✅ Поддерживаемые команды
- `detect` - определить доступный движок
- `build` - собрать образ
- `run` - запустить контейнер
- `compose` - запустить docker-compose/podman-compose
- `images` - показать образы
- `containers` - показать контейнеры
- `clean` - очистить образы и контейнеры

## Использование

### Базовое использование

```bash
# Определить доступный движок
./scripts/container-manager.sh detect

# Собрать образ с автоопределением
./scripts/container-manager.sh build -t myapp .

# Запустить compose
./scripts/container-manager.sh compose up -d

# Показать образы
./scripts/container-manager.sh images

# Очистить все
./scripts/container-manager.sh clean
```

### С принудительным выбором движка

```bash
# Использовать Podman
./scripts/container-manager.sh -e podman build -t myapp .

# Использовать Docker
./scripts/container-manager.sh -e docker compose up -d

# Специальный compose файл
./scripts/container-manager.sh -f my-compose.yml compose up
```

### Переменные окружения

```bash
# Принудительно указать движок
export CONTAINER_ENGINE=podman
./scripts/container-manager.sh detect

# Указать compose движок
export COMPOSE_ENGINE=podman-compose
./scripts/container-manager.sh compose up
```

## Интеграция в проекте

### 1. Локальная разработка

```bash
# Создать тестовое приложение
mkdir my-test-app
cd my-test-app

# Создать docker-compose.yml
cat > docker-compose.yml << EOF
version: '3.8'
services:
  test-app:
    image: nginx:alpine
    ports:
      - "8080:80"
EOF

# Запустить с Container Manager
../desqemu/scripts/container-manager.sh compose up -d
```

### 2. В скриптах сборки

```bash
# В scripts/build-desktop-app.sh
if [[ -f "docker-compose.yml" ]]; then
    ./scripts/container-manager.sh compose build
fi
```

### 3. В GitHub Actions

```yaml
- name: Setup Container Engine
  run: |
    ./scripts/container-manager.sh detect
    
- name: Build with Container Manager
  run: |
    ./scripts/container-manager.sh -e podman compose build
```

## Преимущества унификации

### 🔒 Безопасность
- **Podman** работает без root
- Изоляция контейнеров
- Безопасные образы

### 🚀 Производительность
- Автоматическое определение лучшего движка
- Оптимизированные команды
- Кэширование образов

### 🔧 Удобство
- Единый интерфейс для Docker и Podman
- Автоматическое определение платформы
- Подробные сообщения об ошибках

### 📦 Портативность
- Работает на всех платформах
- Поддержка разных compose движков
- Совместимость с существующими проектами

## Примеры вывода

### Успешное определение
```
🔍 Определение контейнерного движка...
✅ Найден: Podman: podman version 5.1.2 (Arch: amd64)
✅ Compose: podman-compose
📁 Compose файл: docker-compose.yml
```

### Сборка образа
```
🔨 Сборка образа с podman...
STEP 1/3: FROM nginx:alpine
STEP 2/3: COPY . /usr/share/nginx/html
STEP 3/3: EXPOSE 80
✅ Образ собран успешно
```

### Compose команды
```
🐳 Запуск compose с podman-compose...
Creating network "myapp_default"
Creating myapp_web_1 ... done
✅ Compose запущен успешно
```

## Конфигурация

### Переменные окружения

```bash
# Контейнерный движок
CONTAINER_ENGINE=podman|docker

# Compose движок
COMPOSE_ENGINE=podman-compose|docker-compose

# Compose файл
COMPOSE_FILE=docker-compose.yml
```

### Параметры командной строки

```bash
-e, --engine ENGINE    # Предпочитаемый движок
-f, --file FILE        # Путь к compose файлу
--verbose              # Подробный вывод
-h, --help            # Справка
```

## Поддержка платформ

| Платформа | Podman | Docker | Compose |
|-----------|--------|--------|---------|
| macOS | ✅ Homebrew | ✅ Homebrew | ✅ |
| Ubuntu | ✅ APT | ✅ APT | ✅ |
| CentOS | ✅ YUM | ✅ YUM | ✅ |
| Fedora | ✅ DNF | ✅ DNF | ✅ |
| Arch | ✅ Pacman | ✅ Pacman | ✅ |

## Troubleshooting

### Podman не найден
```bash
# macOS
brew install podman

# Ubuntu
sudo apt install podman

# Проверить установку
./scripts/container-manager.sh detect
```

### Docker не найден
```bash
# macOS
brew install docker

# Ubuntu
sudo apt install docker.io

# Проверить установку
./scripts/container-manager.sh detect
```

### Compose не работает
```bash
# Установить podman-compose
pip install podman-compose

# Установить docker-compose
pip install docker-compose

# Проверить
./scripts/container-manager.sh detect
```

### Проблемы с правами
```bash
# Podman (не требует root)
podman system connection add

# Docker (может требовать sudo)
sudo usermod -aG docker $USER
```

## Разработка

### Добавление нового движка

1. Обновите функцию `detect_container_engine()`
2. Добавьте новый case в `detect_compose_engine()`
3. Обновите `get_engine_info()`

### Тестирование

```bash
# Тест всех команд
./scripts/container-manager.sh detect
./scripts/container-manager.sh images
./scripts/container-manager.sh containers

# Тест с разными движками
./scripts/container-manager.sh -e podman detect
./scripts/container-manager.sh -e docker detect
```

## Лицензия

MIT License - см. файл LICENSE в корне проекта. 
