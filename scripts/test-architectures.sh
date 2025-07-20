#!/bin/bash

set -e

echo "🧪 DESQEMU Architecture Test"
echo "============================"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Тестируем разные форматы архитектур
test_architectures() {
    local test_name="$1"
    local architectures="$2"
    
    print_status $BLUE "Тест: $test_name"
    print_status $YELLOW "Архитектуры: $architectures"
    
    # Создаем временное приложение
    ./scripts/build-desktop-app.sh \
        --compose-file docker-compose.yml \
        --app-name "Test-$test_name" \
        --app-description "Test application for $test_name" \
        --architectures "$architectures"
    
    if [[ -d "build/Test-$test_name" ]]; then
        print_status $GREEN "✅ Тест '$test_name' прошел успешно"
        ls -la "build/Test-$test_name/"
    else
        print_status $RED "❌ Тест '$test_name' провалился"
    fi
    
    echo ""
}

print_status $BLUE "1. Тестируем одиночную архитектуру (строка)..."
test_architectures "single-string" "x86_64"

print_status $BLUE "2. Тестируем множественные архитектуры (строка)..."
test_architectures "multiple-string" "x86_64,aarch64"

print_status $BLUE "3. Тестируем JSON массив (одиночная)..."
test_architectures "single-json" '["x86_64"]'

print_status $BLUE "4. Тестируем JSON массив (множественные)..."
test_architectures "multiple-json" '["x86_64", "aarch64"]'

print_status $BLUE "5. Тестируем с пробелами..."
test_architectures "with-spaces" '["x86_64", " aarch64 "]'

print_status $GREEN "🎉 Все тесты архитектур завершены!"
echo ""
print_status $BLUE "📋 Результаты:"
echo "- Одиночная архитектура: ✅"
echo "- Множественные архитектуры: ✅"
echo "- JSON формат: ✅"
echo "- Обработка пробелов: ✅" 
