#!/bin/bash

set -e

ARCHITECTURE="$1"
if [ -z "$ARCHITECTURE" ]; then
    echo "❌ Не указана архитектура"
    echo "Использование: $0 <architecture>"
    exit 1
fi

echo "📦 Создаем итоговый архив для $ARCHITECTURE..."

cd desqemu-portable
tar -czf "../desqemu-portable-microvm-$ARCHITECTURE.tar.gz" "$ARCHITECTURE"/
cd ..

ARCHIVE_SIZE=$(du -h "desqemu-portable-microvm-$ARCHITECTURE.tar.gz" | cut -f1)
echo "✅ Архив создан: desqemu-portable-microvm-$ARCHITECTURE.tar.gz ($ARCHIVE_SIZE)"

# Create installation script
cat > "install-desqemu-portable-$ARCHITECTURE.sh" << EOF
#!/bin/bash

echo "🚀 DESQEMU Portable MicroVM Installer"
echo "====================================="

ARCHIVE="desqemu-portable-microvm-$ARCHITECTURE.tar.gz"
INSTALL_DIR="\$HOME/desqemu-portable"

if [ ! -f "\$ARCHIVE" ]; then
    echo "❌ Архив \$ARCHIVE не найден!"
    echo "Убедитесь что вы находитесь в директории с архивом"
    exit 1
fi

echo "📦 Устанавливаем DESQEMU Portable в \$INSTALL_DIR..."

# Create install directory
mkdir -p "\$INSTALL_DIR"

# Extract archive
tar -xzf "\$ARCHIVE" -C "\$INSTALL_DIR"

# Create symlinks in PATH
if [ -d "\$HOME/.local/bin" ]; then
    BIN_DIR="\$HOME/.local/bin"
else
    BIN_DIR="\$HOME/bin"
    mkdir -p "\$BIN_DIR"
fi

echo "🔗 Создаем ссылки в \$BIN_DIR..."
ln -sf "\$INSTALL_DIR/$ARCHITECTURE/start-microvm.sh" "\$BIN_DIR/desqemu-start"
ln -sf "\$INSTALL_DIR/$ARCHITECTURE/stop-microvm.sh" "\$BIN_DIR/desqemu-stop"
ln -sf "\$INSTALL_DIR/$ARCHITECTURE/check-status.sh" "\$BIN_DIR/desqemu-status"

echo "✅ Установка завершена!"
echo ""
echo "🚀 Для запуска используйте:"
echo "  desqemu-start     # Запуск микровм"
echo "  desqemu-status    # Проверка статуса"
echo "  desqemu-stop      # Остановка микровм"
echo ""
echo "📁 Файлы установлены в: \$INSTALL_DIR"
echo "🔧 Добавьте \$BIN_DIR в PATH если это еще не сделано:"
echo "  echo 'export PATH=\"\$BIN_DIR:\\\$PATH\"' >> ~/.bashrc"
echo "  source ~/.bashrc"
EOF

chmod +x "install-desqemu-portable-$ARCHITECTURE.sh"

echo "✅ Создан установочный скрипт: install-desqemu-portable-$ARCHITECTURE.sh" 
