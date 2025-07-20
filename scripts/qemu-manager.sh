#!/bin/bash

set -e

# QEMU Manager - универсальный скрипт для управления QEMU
# Используется в GitHub Actions, templates и локально

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
QEMU_VERSION="8.2.0"
QEMU_BINARY="qemu-system-x86_64"
ARCHITECTURE="x86_64"
AUTO_INSTALL=true
VERBOSE=false

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show help
show_help() {
    echo "QEMU Manager - универсальный скрипт для управления QEMU"
    echo ""
    echo "Использование: $0 [опции]"
    echo ""
    echo "Опции:"
    echo "  -a, --arch ARCH        Архитектура (x86_64, aarch64) [по умолчанию: x86_64]"
    echo "  -v, --version VERSION  Версия QEMU [по умолчанию: 8.2.0]"
    echo "  -b, --binary BINARY    Имя бинарного файла [по умолчанию: qemu-system-x86_64]"
    echo "  -n, --no-install       Не устанавливать автоматически"
    echo "  --verbose              Подробный вывод"
    echo "  -h, --help            Показать эту справку"
    echo ""
    echo "Команды:"
    echo "  check                  Проверить доступность QEMU"
    echo "  install                Установить QEMU"
    echo "  version                Показать версию QEMU"
    echo "  path                   Показать путь к QEMU"
    echo "  test                   Запустить тест QEMU"
    echo ""
    echo "Примеры:"
    echo "  $0 check                    # Проверить QEMU"
    echo "  $0 install                  # Установить QEMU"
    echo "  $0 -a aarch64 check        # Проверить QEMU для ARM"
    echo "  $0 --verbose version       # Показать версию с подробным выводом"
}

# Function to detect platform
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Function to get package manager
get_package_manager() {
    local platform=$1
    
    case $platform in
        "macos")
            if command -v brew >/dev/null 2>&1; then
                echo "brew"
            else
                echo "none"
            fi
            ;;
        "linux")
            if command -v apt-get >/dev/null 2>&1; then
                echo "apt"
            elif command -v yum >/dev/null 2>&1; then
                echo "yum"
            elif command -v dnf >/dev/null 2>&1; then
                echo "dnf"
            elif command -v pacman >/dev/null 2>&1; then
                echo "pacman"
            else
                echo "none"
            fi
            ;;
        *)
            echo "none"
            ;;
    esac
}

# Function to check QEMU availability
check_qemu() {
    print_status $BLUE "🔍 Проверяем доступность QEMU..."
    
    if command -v "$QEMU_BINARY" >/dev/null 2>&1; then
        local version=$("$QEMU_BINARY" --version 2>/dev/null | head -1)
        local path=$(which "$QEMU_BINARY" 2>/dev/null)
        
        print_status $GREEN "✅ QEMU найден"
        print_status $BLUE "📋 Версия: $version"
        print_status $BLUE "📁 Путь: $path"
        
        if [ "$VERBOSE" = true ]; then
            print_status $BLUE "🔧 Подробная информация:"
            "$QEMU_BINARY" --version
        fi
        
        return 0
    else
        print_status $YELLOW "⚠️ QEMU не найден"
        
        if [ "$AUTO_INSTALL" = true ]; then
            print_status $BLUE "🔧 Попытка автоматической установки..."
            install_qemu
        else
            print_status $RED "❌ QEMU не установлен. Используйте команду install для установки."
            return 1
        fi
    fi
}

# Function to install QEMU
install_qemu() {
    local platform=$(detect_platform)
    local package_manager=$(get_package_manager "$platform")
    
    print_status $BLUE "🔧 Устанавливаем QEMU для $platform..."
    
    case $platform in
        "macos")
            if [ "$package_manager" = "brew" ]; then
                print_status $BLUE "🍎 Установка через Homebrew..."
                brew install qemu
            else
                print_status $RED "❌ Homebrew не найден. Установите Homebrew: https://brew.sh/"
                return 1
            fi
            ;;
        "linux")
            case $package_manager in
                "apt")
                    print_status $BLUE "🐧 Установка через APT..."
                    sudo apt-get update && sudo apt-get install -y qemu-system-x86
                    ;;
                "yum")
                    print_status $BLUE "🐧 Установка через YUM..."
                    sudo yum install -y qemu-system-x86_64
                    ;;
                "dnf")
                    print_status $BLUE "🐧 Установка через DNF..."
                    sudo dnf install -y qemu-system-x86_64
                    ;;
                "pacman")
                    print_status $BLUE "🐧 Установка через Pacman..."
                    sudo pacman -S qemu
                    ;;
                *)
                    print_status $RED "❌ Неизвестный пакетный менеджер. Установите QEMU вручную."
                    return 1
                    ;;
            esac
            ;;
        "windows")
            print_status $YELLOW "🪟 Windows: откройте https://www.qemu.org/download/#windows"
            print_status $YELLOW "Скачайте и установите QEMU вручную."
            return 1
            ;;
        *)
            print_status $RED "❌ Неподдерживаемая платформа: $platform"
            return 1
            ;;
    esac
    
    # Verify installation
    if command -v "$QEMU_BINARY" >/dev/null 2>&1; then
        print_status $GREEN "✅ QEMU успешно установлен!"
        check_qemu
    else
        print_status $RED "❌ Установка QEMU не удалась"
        return 1
    fi
}

# Function to get QEMU version
get_qemu_version() {
    if command -v "$QEMU_BINARY" >/dev/null 2>&1; then
        local version=$("$QEMU_BINARY" --version 2>/dev/null | head -1)
        echo "$version"
    else
        echo "QEMU not found"
        return 1
    fi
}

# Function to get QEMU path
get_qemu_path() {
    if command -v "$QEMU_BINARY" >/dev/null 2>&1; then
        which "$QEMU_BINARY" 2>/dev/null
    else
        echo "QEMU not found"
        return 1
    fi
}

# Function to test QEMU
test_qemu() {
    print_status $BLUE "🧪 Тестируем QEMU..."
    
    if ! command -v "$QEMU_BINARY" >/dev/null 2>&1; then
        print_status $RED "❌ QEMU не установлен"
        return 1
    fi
    
    # Test basic functionality
    print_status $BLUE "🔍 Проверяем версию..."
    "$QEMU_BINARY" --version >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_status $GREEN "✅ Версия работает"
    else
        print_status $RED "❌ Ошибка получения версии"
        return 1
    fi
    
    # Test help
    print_status $BLUE "🔍 Проверяем справку..."
    "$QEMU_BINARY" --help >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_status $GREEN "✅ Справка работает"
    else
        print_status $RED "❌ Ошибка получения справки"
        return 1
    fi
    
    print_status $GREEN "✅ QEMU работает корректно"
}

# Parse command line arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--arch)
            ARCHITECTURE="$2"
            shift 2
            ;;
        -v|--version)
            QEMU_VERSION="$2"
            shift 2
            ;;
        -b|--binary)
            QEMU_BINARY="$2"
            shift 2
            ;;
        -n|--no-install)
            AUTO_INSTALL=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        check|install|version|path|test)
            COMMAND="$1"
            shift
            ;;
        *)
            print_status $RED "❌ Неизвестный аргумент: $1"
            show_help
            exit 1
            ;;
    esac
done

# Set QEMU binary based on architecture
if [ "$ARCHITECTURE" = "aarch64" ] || [ "$ARCHITECTURE" = "arm64" ]; then
    QEMU_BINARY="qemu-system-aarch64"
fi

# Execute command
case $COMMAND in
    "check")
        check_qemu
        ;;
    "install")
        install_qemu
        ;;
    "version")
        get_qemu_version
        ;;
    "path")
        get_qemu_path
        ;;
    "test")
        test_qemu
        ;;
    "")
        # Default command is check
        check_qemu
        ;;
    *)
        print_status $RED "❌ Неизвестная команда: $COMMAND"
        show_help
        exit 1
        ;;
esac 
