#!/bin/bash

set -e

echo "🧪 Тестирование системы DESQEMU"
echo "================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to print status
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Test 1: Check if we're in the right directory
print_status $BLUE "1. Проверка директории..."
if [[ -f "README.md" && -f "scripts/qemu-manager.sh" ]]; then
    print_status $GREEN "✅ Мы в правильной директории DESQEMU"
else
    print_status $RED "❌ Не в директории DESQEMU"
    exit 1
fi

# Test 2: Check QEMU Manager
print_status $BLUE "2. Тестирование QEMU Manager..."
if [[ -f "scripts/qemu-manager.sh" ]]; then
    print_status $GREEN "✅ QEMU Manager найден"
    
    # Test QEMU Manager functionality
    if ./scripts/qemu-manager.sh check >/dev/null 2>&1; then
        print_status $GREEN "✅ QEMU Manager работает"
    else
        print_status $YELLOW "⚠️ QEMU Manager имеет проблемы"
    fi
else
    print_status $RED "❌ QEMU Manager не найден"
fi

# Test 3: Check build script
print_status $BLUE "3. Тестирование скрипта сборки..."
if [[ -f "scripts/build-desktop-app.sh" ]]; then
    print_status $GREEN "✅ Скрипт сборки найден"
    
    # Test help
    if ./scripts/build-desktop-app.sh --help >/dev/null 2>&1; then
        print_status $GREEN "✅ Скрипт сборки работает"
    else
        print_status $YELLOW "⚠️ Скрипт сборки имеет проблемы"
    fi
else
    print_status $RED "❌ Скрипт сборки не найден"
fi

# Test 4: Check templates
print_status $BLUE "4. Тестирование шаблонов..."
if [[ -d "templates/neutralino-app" ]]; then
    print_status $GREEN "✅ Шаблоны Neutralino найдены"
    
    # Check key files
    if [[ -f "templates/neutralino-app/resources/js/app.js" ]]; then
        print_status $GREEN "✅ app.js найден"
    else
        print_status $RED "❌ app.js не найден"
    fi
    
    if [[ -f "templates/neutralino-app/resources/js/qemu-utils.js" ]]; then
        print_status $GREEN "✅ qemu-utils.js найден"
    else
        print_status $RED "❌ qemu-utils.js не найден"
    fi
else
    print_status $RED "❌ Шаблоны не найдены"
fi

# Test 5: Check examples
print_status $BLUE "5. Тестирование примеров..."
if [[ -d "examples" ]]; then
    print_status $GREEN "✅ Папка examples найдена"
    
    # Check if there are any compose files
    compose_files=$(find examples -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
    if [[ $compose_files -gt 0 ]]; then
        print_status $GREEN "✅ Найдено $compose_files docker-compose файлов"
    else
        print_status $YELLOW "⚠️ Docker-compose файлы не найдены"
    fi
else
    print_status $RED "❌ Папка examples не найдена"
fi

# Test 6: Check GitHub Actions
print_status $BLUE "6. Тестирование GitHub Actions..."
if [[ -d ".github/workflows" ]]; then
    print_status $GREEN "✅ GitHub Actions найдены"
    
    workflow_files=$(find .github/workflows -name "*.yml" 2>/dev/null | wc -l)
    if [[ $workflow_files -gt 0 ]]; then
        print_status $GREEN "✅ Найдено $workflow_files workflow файлов"
    else
        print_status $YELLOW "⚠️ Workflow файлы не найдены"
    fi
else
    print_status $YELLOW "⚠️ GitHub Actions не найдены"
fi

# Test 7: Check QEMU availability
print_status $BLUE "7. Тестирование QEMU..."
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    version=$(qemu-system-x86_64 --version 2>/dev/null | head -1)
    print_status $GREEN "✅ QEMU установлен: $version"
else
    print_status $YELLOW "⚠️ QEMU не установлен"
    print_status $BLUE "💡 Установите QEMU: ./scripts/qemu-manager.sh install"
fi

# Test 8: Check Node.js
print_status $BLUE "8. Тестирование Node.js..."
if command -v node >/dev/null 2>&1; then
    version=$(node --version 2>/dev/null)
    print_status $GREEN "✅ Node.js установлен: $version"
else
    print_status $YELLOW "⚠️ Node.js не установлен"
    print_status $BLUE "💡 Установите Node.js для сборки Neutralino приложений"
fi

# Test 9: Check Container Engines (optional)
print_status $BLUE "9. Тестирование контейнерных движков (опционально)..."
if command -v podman >/dev/null 2>&1; then
    version=$(podman --version 2>/dev/null)
    print_status $GREEN "✅ Podman установлен: $version"
elif command -v docker >/dev/null 2>&1; then
    version=$(docker --version 2>/dev/null)
    print_status $GREEN "✅ Docker установлен: $version"
else
    print_status $YELLOW "⚠️ Контейнерные движки не найдены"
    print_status $BLUE "💡 Podman/Docker нужны только для локальной разработки образов"
fi

# Test 10: Check git
print_status $BLUE "10. Тестирование Git..."
if command -v git >/dev/null 2>&1; then
    version=$(git --version 2>/dev/null)
    print_status $GREEN "✅ Git установлен: $version"
else
    print_status $YELLOW "⚠️ Git не установлен"
fi

echo ""
print_status $GREEN "🎉 Тестирование завершено!"
echo ""
print_status $BLUE "📋 Следующие шаги:"
echo "1. Запустите: ./scripts/qemu-manager.sh check"
echo "2. Протестируйте сборку: ./scripts/build-desktop-app.sh --help"
echo "3. Создайте тестовое приложение в examples/"
echo "4. Запустите GitHub Actions для полного тестирования"
echo ""
print_status $YELLOW "📚 Документация:"
echo "- README.md - основная документация"
echo "- QEMU_MANAGER_README.md - документация по QEMU Manager"
echo "- TESTING_GUIDE.md - подробное руководство по тестированию" 
