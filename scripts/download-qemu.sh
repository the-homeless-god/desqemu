#!/bin/bash

set -e

ARCHITECTURE="$1"
if [ -z "$ARCHITECTURE" ]; then
    echo "❌ Не указана архитектура"
    echo "Использование: $0 <architecture>"
    exit 1
fi

echo "📦 Проверяем QEMU для $ARCHITECTURE..."

# Use the universal QEMU manager
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/qemu-manager.sh" --arch "$ARCHITECTURE" check 
