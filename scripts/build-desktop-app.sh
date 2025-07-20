#!/bin/bash

set -e

# Парсинг аргументов
COMPOSE_FILE=""
APP_NAME=""
APP_DESCRIPTION=""
APP_ICON=""
ARCHITECTURES="x86_64,aarch64"
QEMU_VERSION="8.2.0"
ALPINE_VERSION="3.22.0"

# Функция для вывода справки
show_help() {
    cat << EOF
DESQEMU Desktop App Builder

Usage: $0 [OPTIONS]

Options:
    --compose-file FILE      Path to docker-compose.yml file (required)
    --app-name NAME         Name of the desktop application (required)
    --app-description DESC  Description of the application
    --app-icon ICON         Path to app icon (SVG recommended)
    --architectures ARCH    Comma-separated list of architectures (default: x86_64,aarch64)
    --qemu-version VERSION  QEMU version to include (default: 8.2.0)
    --alpine-version VERSION Alpine Linux version (default: 3.22.0)
    --help                  Show this help message

Examples:
    $0 --compose-file my-app.yml --app-name "My App"
    $0 --compose-file penpot.yml --app-name "Penpot" --app-icon penpot-logo.svg
EOF
}

# Парсинг аргументов командной строки
while [[ $# -gt 0 ]]; do
    case $1 in
        --compose-file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        --app-name)
            APP_NAME="$2"
            shift 2
            ;;
        --app-description)
            APP_DESCRIPTION="$2"
            shift 2
            ;;
        --app-icon)
            APP_ICON="$2"
            shift 2
            ;;
        --architectures)
            # Поддерживаем как строку, так и JSON массив
            if [[ "$2" == \[* ]]; then
                # JSON массив - извлекаем значения
                ARCHITECTURES=$(echo "$2" | sed 's/\[//g' | sed 's/\]//g' | sed 's/"//g' | sed 's/,/ /g' | tr ' ' ',' | sed 's/,,*/,/g' | sed 's/^,//' | sed 's/,$//')
            else
                ARCHITECTURES="$2"
            fi
            shift 2
            ;;
        --qemu-version)
            QEMU_VERSION="$2"
            shift 2
            ;;
        --alpine-version)
            ALPINE_VERSION="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Проверка обязательных параметров
if [[ -z "$COMPOSE_FILE" ]]; then
    echo "❌ Error: --compose-file is required"
    show_help
    exit 1
fi

if [[ -z "$APP_NAME" ]]; then
    echo "❌ Error: --app-name is required"
    show_help
    exit 1
fi

# Проверка существования файлов
if [[ ! -f "$COMPOSE_FILE" ]]; then
    echo "❌ Error: Docker Compose file not found: $COMPOSE_FILE"
    exit 1
fi

if [[ -n "$APP_ICON" && ! -f "$APP_ICON" ]]; then
    echo "⚠️  Warning: App icon not found: $APP_ICON"
    APP_ICON=""
fi

echo "🚀 DESQEMU Desktop App Builder"
echo "📦 App: $APP_NAME"
echo "📄 Compose file: $COMPOSE_FILE"
echo "🏗️  Architectures: $ARCHITECTURES"
echo ""

# Создаем временную директорию для сборки
BUILD_DIR="build/$APP_NAME"
mkdir -p "$BUILD_DIR"

echo "📁 Creating build directory: $BUILD_DIR"

# Копируем Docker Compose файл
cp "$COMPOSE_FILE" "$BUILD_DIR/docker-compose.yml"

# Создаем конфигурацию приложения
cat > "$BUILD_DIR/app-config.json" << EOF
{
  "name": "$APP_NAME",
  "description": "$APP_DESCRIPTION",
  "composeFile": "docker-compose.yml",
  "architectures": ["${ARCHITECTURES//,/\",\""}"],
  "qemuVersion": "$QEMU_VERSION",
  "alpineVersion": "$ALPINE_VERSION",
  "icon": "${APP_ICON:-app-icon.svg}",
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Копируем иконку если есть
if [[ -n "$APP_ICON" ]]; then
    cp "$APP_ICON" "$BUILD_DIR/app-icon.svg"
else
    # Создаем дефолтную иконку
    cat > "$BUILD_DIR/app-icon.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">
  <rect width="100" height="100" fill="#4A90E2" rx="20"/>
  <text x="50" y="60" font-family="Arial, sans-serif" font-size="40" fill="white" text-anchor="middle">D</text>
</svg>
EOF
fi

# Создаем скрипт сборки для каждой архитектуры
IFS=',' read -ra ARCH_ARRAY <<< "$ARCHITECTURES"
for arch in "${ARCH_ARRAY[@]}"; do
    # Убираем пробелы
    arch=$(echo "$arch" | xargs)
    echo "🏗️  Building for architecture: $arch"
    
    # Создаем директорию для архитектуры
    ARCH_DIR="$BUILD_DIR/$arch"
    mkdir -p "$ARCH_DIR"
    
    # Создаем скрипт сборки
    cat > "$ARCH_DIR/build.sh" << EOF
#!/bin/bash
set -e

echo "🔨 Building $APP_NAME for $arch..."

# Проверяем и устанавливаем QEMU для архитектуры
./scripts/qemu-manager.sh --arch $arch check || ./scripts/qemu-manager.sh --arch $arch install

# Создаем Alpine образ
./scripts/create-alpine-image.sh --version $ALPINE_VERSION --arch $arch

# Конвертируем Docker Compose в QCOW2
./scripts/docker-compose-to-qcow2.sh \
    --compose-file docker-compose.yml \
    --output $APP_NAME-$arch.qcow2 \
    --arch $arch

# Создаем портативный архив
./scripts/create-portable-archive.sh \
    --qcow2 $APP_NAME-$arch.qcow2 \
    --qemu-dir qemu-$arch \
    --output $APP_NAME-portable-$arch.tar.gz \
    --app-name "$APP_NAME" \
    --app-description "$APP_DESCRIPTION"

# Создаем Neutralino десктопное приложение
./scripts/create-neutralino-desktop.sh \
    --portable-archive $APP_NAME-portable-$arch.tar.gz \
    --app-name "$APP_NAME" \
    --app-description "$APP_DESCRIPTION" \
    --app-icon app-icon.svg \
    --arch $arch \
    --qcow2 $APP_NAME-$arch.qcow2

echo "✅ Build completed for $arch"
EOF
    
    chmod +x "$ARCH_DIR/build.sh"
    
    # Копируем необходимые скрипты
    cp -r scripts "$ARCH_DIR/"
    cp -r templates "$ARCH_DIR/"
    
    # Копируем Docker Compose файл
    cp "$COMPOSE_FILE" "$ARCH_DIR/"
    cp "$BUILD_DIR/app-icon.svg" "$ARCH_DIR/"
done

# Создаем основной скрипт сборки
cat > "$BUILD_DIR/build-all.sh" << EOF
#!/bin/bash
set -e

echo "🚀 Building $APP_NAME for all architectures..."

# Массив архитектур
ARCHITECTURES=(${ARCHITECTURES//,/ })

# Собираем для каждой архитектуры
for arch in "\${ARCHITECTURES[@]}"; do
    echo "🏗️  Building for \$arch..."
    cd "\$arch"
    ./build.sh
    cd ..
done

echo "✅ All builds completed!"
echo ""
echo "📦 Generated artifacts:"
for arch in "\${ARCHITECTURES[@]}"; do
    echo "  - \$arch/$APP_NAME-portable-\$arch.tar.gz"
    echo "  - \$arch/$APP_NAME-\$arch.qcow2"
    echo "  - \$arch/$APP_NAME-desktop-\$arch/"
    echo "  - \$arch/$APP_NAME-desktop-\$arch.dmg (macOS)"
    echo "  - \$arch/$APP_NAME-desktop-\$arch.exe (Windows)"
    echo "  - \$arch/$APP_NAME-desktop-\$arch.AppImage (Linux)"
done
EOF

chmod +x "$BUILD_DIR/build-all.sh"

# Создаем README для пользователя
cat > "$BUILD_DIR/README.md" << EOF
# $APP_NAME - DESQEMU Desktop Application

## Описание

$APP_DESCRIPTION

## Быстрый запуск

### 1. Сборка для всех архитектур

\`\`\`bash
./build-all.sh
\`\`\`

### 2. Сборка для конкретной архитектуры

\`\`\`bash
cd x86_64  # или aarch64
./build.sh
\`\`\`

### 3. Запуск портативного приложения

\`\`\`bash
# Распакуйте архив
tar -xzf $APP_NAME-portable-x86_64.tar.gz
cd $APP_NAME-portable-x86_64

# Запустите приложение
./start.sh
\`\`\`

### 4. Запуск десктопного приложения

\`\`\`bash
# macOS
open $APP_NAME-desktop-x86_64.dmg

# Windows
$APP_NAME-desktop-x86_64.exe

# Linux
./$APP_NAME-desktop-x86_64.AppImage
\`\`\`

## Архитектуры

Поддерживаемые архитектуры:
- **x86_64** - Intel/AMD 64-bit
- **aarch64** - ARM 64-bit

## Файлы

- \`docker-compose.yml\` - конфигурация приложения
- \`app-icon.svg\` - иконка приложения
- \`app-config.json\` - конфигурация сборки

## Порты

По умолчанию пробрасываются порты:
- **8080** → Веб-приложение
- **5900** → VNC сервер (пароль: desqemu)
- **2222** → SSH доступ

## Поддержка

Для получения помощи обратитесь к документации DESQEMU:
https://github.com/the-homeless-god/desqemu
EOF

# Создаем .gitignore
cat > "$BUILD_DIR/.gitignore" << 'EOF'
# Build artifacts
*.qcow2
*.tar.gz
qemu-*/
desktop-app-*/

# Temporary files
*.tmp
*.log
build/

# OS files
.DS_Store
Thumbs.db
EOF

echo "✅ Build configuration created successfully!"
echo ""
echo "📁 Build directory: $BUILD_DIR"
echo "📄 Configuration: $BUILD_DIR/app-config.json"
echo "🚀 To build: cd $BUILD_DIR && ./build-all.sh"
echo ""

# Устанавливаем выходные переменные для GitHub Actions (если доступно)
if [[ -n "$GITHUB_OUTPUT" ]]; then
    echo "archive-path=$BUILD_DIR" >> $GITHUB_OUTPUT
    echo "qcow2-path=$BUILD_DIR" >> $GITHUB_OUTPUT
    echo "desktop-app-path=$BUILD_DIR" >> $GITHUB_OUTPUT
fi

echo "🎉 DESQEMU Desktop App Builder completed!" 
