#!/bin/bash

set -e

# Container Manager - универсальный скрипт для работы с Docker и Podman
# Используется для локальной разработки образов

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
PREFERRED_ENGINE="auto"
COMPOSE_FILE="docker-compose.yml"

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to show help
show_help() {
    echo "Container Manager - универсальный скрипт для работы с Docker и Podman"
    echo ""
    echo "Использование: $0 [опции] [команда]"
    echo ""
    echo "Опции:"
    echo "  -e, --engine ENGINE    Предпочитаемый движок (docker/podman/auto)"
    echo "  -f, --file FILE        Путь к compose файлу (по умолчанию: docker-compose.yml)"
    echo "  --verbose              Подробный вывод"
    echo "  -h, --help            Показать эту справку"
    echo ""
    echo "Команды:"
    echo "  detect                 Определить доступный движок"
    echo "  build [args]           Собрать образ"
    echo "  run [args]             Запустить контейнер"
    echo "  compose [args]         Запустить docker-compose/podman-compose"
    echo "  images                 Показать образы"
    echo "  containers             Показать контейнеры"
    echo "  clean                  Очистить образы и контейнеры"
    echo ""
    echo "Переменные окружения:"
    echo "  CONTAINER_ENGINE=docker|podman  # Принудительно указать движок"
    echo "  COMPOSE_ENGINE=docker-compose|podman-compose  # Указать compose движок"
    echo ""
    echo "Примеры:"
    echo "  $0 detect                    # Определить движок"
    echo "  $0 -e podman build .        # Собрать с Podman"
    echo "  $0 compose up -d            # Запустить compose"
    echo "  $0 -f my-compose.yml compose up  # Специальный compose файл"
}

# Function to detect platform
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# Function to detect container engine
detect_container_engine() {
    local preferred=$1
    
    case $preferred in
        "podman")
            if command -v podman >/dev/null 2>&1; then
                echo "podman"
            else
                print_status $RED "❌ Podman не найден"
                exit 1
            fi
            ;;
        "docker")
            if command -v docker >/dev/null 2>&1; then
                echo "docker"
            else
                print_status $RED "❌ Docker не найден"
                exit 1
            fi
            ;;
        "auto"|*)
            # Auto-detect: prefer podman if available, then docker
            if command -v podman >/dev/null 2>&1; then
                echo "podman"
            elif command -v docker >/dev/null 2>&1; then
                echo "docker"
            else
                print_status $RED "❌ Не найден ни Docker, ни Podman"
                print_status $BLUE "💡 Установите Podman или Docker для локальной разработки"
                exit 1
            fi
            ;;
    esac
}

# Function to detect compose engine
detect_compose_engine() {
    local container_engine=$1
    
    case $container_engine in
        "podman")
            if command -v podman-compose >/dev/null 2>&1; then
                echo "podman-compose"
            else
                print_status $RED "❌ Не найден podman-compose"
                print_status $BLUE "💡 Установите: pip install podman-compose"
                exit 1
            fi
            ;;
        "docker")
            if command -v docker-compose >/dev/null 2>&1; then
                echo "docker-compose"
            else
                print_status $RED "❌ Не найден docker-compose"
                print_status $BLUE "💡 Установите Docker Compose"
                exit 1
            fi
            ;;
    esac
}

# Function to get container engine info
get_engine_info() {
    local engine=$1
    
    case $engine in
        "podman")
            local version=$(podman --version 2>/dev/null)
            local info=$(podman info --format json 2>/dev/null | jq -r '.host.arch // "unknown"' 2>/dev/null || echo "unknown")
            echo "Podman: $version (Arch: $info)"
            ;;
        "docker")
            local version=$(docker --version 2>/dev/null)
            local info=$(docker info --format '{{.Architecture}}' 2>/dev/null || echo "unknown")
            echo "Docker: $version (Arch: $info)"
            ;;
    esac
}

# Parse command line arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        -e|--engine)
            PREFERRED_ENGINE="$2"
            shift 2
            ;;
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        detect|build|run|compose|images|containers|clean)
            COMMAND="$1"
            shift
            break
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check for environment variables
if [[ -n "$CONTAINER_ENGINE" ]]; then
    PREFERRED_ENGINE="$CONTAINER_ENGINE"
fi

# Detect container engine
CONTAINER_ENGINE=$(detect_container_engine "$PREFERRED_ENGINE")
COMPOSE_ENGINE=$(detect_compose_engine "$CONTAINER_ENGINE")

# Execute command
case $COMMAND in
    "detect")
        print_status $GREEN "🔍 Определение контейнерного движка..."
        print_status $BLUE "✅ Найден: $(get_engine_info $CONTAINER_ENGINE)"
        print_status $BLUE "✅ Compose: $COMPOSE_ENGINE"
        print_status $BLUE "📁 Compose файл: $COMPOSE_FILE"
        ;;
    "build")
        print_status $BLUE "🔨 Сборка образа с $CONTAINER_ENGINE..."
        $CONTAINER_ENGINE build "$@"
        ;;
    "run")
        print_status $BLUE "🚀 Запуск контейнера с $CONTAINER_ENGINE..."
        $CONTAINER_ENGINE run "$@"
        ;;
    "compose")
        print_status $BLUE "🐳 Запуск compose с $COMPOSE_ENGINE..."
        if [[ -f "$COMPOSE_FILE" ]]; then
            $COMPOSE_ENGINE -f "$COMPOSE_FILE" "$@"
        else
            print_status $RED "❌ Compose файл не найден: $COMPOSE_FILE"
            exit 1
        fi
        ;;
    "images")
        print_status $BLUE "📦 Список образов $CONTAINER_ENGINE..."
        $CONTAINER_ENGINE images "$@"
        ;;
    "containers")
        print_status $BLUE "📋 Список контейнеров $CONTAINER_ENGINE..."
        $CONTAINER_ENGINE ps "$@"
        ;;
    "clean")
        print_status $BLUE "🧹 Очистка $CONTAINER_ENGINE..."
        
        # Stop and remove containers
        print_status $YELLOW "Останавливаем контейнеры..."
        $CONTAINER_ENGINE stop $($CONTAINER_ENGINE ps -q 2>/dev/null) 2>/dev/null || true
        $CONTAINER_ENGINE rm $($CONTAINER_ENGINE ps -aq 2>/dev/null) 2>/dev/null || true
        
        # Remove images
        print_status $YELLOW "Удаляем образы..."
        $CONTAINER_ENGINE rmi $($CONTAINER_ENGINE images -q 2>/dev/null) 2>/dev/null || true
        
        # Clean compose
        if command -v $COMPOSE_ENGINE >/dev/null 2>&1; then
            print_status $YELLOW "Очищаем compose..."
            $COMPOSE_ENGINE -f "$COMPOSE_FILE" down --rmi all --volumes --remove-orphans 2>/dev/null || true
        fi
        
        print_status $GREEN "✅ Очистка завершена"
        ;;
    "")
        # Default command is detect
        print_status $GREEN "🔍 Определение контейнерного движка..."
        print_status $BLUE "✅ Найден: $(get_engine_info $CONTAINER_ENGINE)"
        print_status $BLUE "✅ Compose: $COMPOSE_ENGINE"
        print_status $BLUE "📁 Compose файл: $COMPOSE_FILE"
        ;;
    *)
        print_status $RED "❌ Неизвестная команда: $COMMAND"
        show_help
        exit 1
        ;;
esac 
