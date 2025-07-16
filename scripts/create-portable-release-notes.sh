#!/bin/bash

set -e

GITHUB_REPOSITORY="$1"
GITHUB_REF_NAME="$2"
GITHUB_REPOSITORY_OWNER="$3"
GITHUB_SERVER_URL="$4"

if [ -z "$GITHUB_REPOSITORY" ] || [ -z "$GITHUB_REF_NAME" ] || [ -z "$GITHUB_REPOSITORY_OWNER" ] || [ -z "$GITHUB_SERVER_URL" ]; then
    echo "❌ Не указаны параметры"
    echo "Использование: $0 <github_repository> <github_ref_name> <github_repository_owner> <github_server_url>"
    exit 1
fi

echo "📝 Создаем release notes для портативных архивов..."

cat > portable-release-notes.md << EOF
# 🚀 DESQEMU Portable MicroVM Archives

Портативные архивы с готовой микровм и QEMU - не требуют установки QEMU!

## 🎯 Что это:

Самодостаточные архивы, содержащие:
- **QEMU бинарники** - под нужную архитектуру
- **Alpine Linux MicroVM** - готовая к запуску микровм
- **Podman + Docker CLI + Chromium** - полный стек
- **Скрипты запуска** - одна команда для запуска

## 📦 Доступные архивы:

### 🖥️ x86_64 (Intel/AMD 64-bit)
- \`desqemu-portable-microvm-x86_64.tar.gz\` - полный архив
- \`install-desqemu-portable.sh\` - автоматический установщик

### 💪 ARM64/AArch64 
- \`desqemu-portable-microvm-aarch64.tar.gz\` - для ARM64 систем
- \`desqemu-portable-microvm-arm64.tar.gz\` - альтернативная архитектура

## 🚀 Быстрый старт:

\`\`\`bash
# Скачать архив для вашей архитектуры
wget https://github.com/$GITHUB_REPOSITORY/releases/download/$GITHUB_REF_NAME/desqemu-portable-microvm-x86_64.tar.gz

# Распаковать
tar -xzf desqemu-portable-microvm-x86_64.tar.gz

# Запустить
cd x86_64
./start-microvm.sh
\`\`\`

## 🔧 Автоматическая установка:

\`\`\`bash
# Скачать и запустить установщик
wget https://github.com/$GITHUB_REPOSITORY/releases/download/$GITHUB_REF_NAME/install-desqemu-portable.sh
chmod +x install-desqemu-portable.sh
./install-desqemu-portable.sh

# После установки
desqemu-start      # Запуск микровм
desqemu-status     # Статус
desqemu-stop       # Остановка
\`\`\`

## 🌐 Доступ к микровм:

- **VNC:** localhost:5900 (пароль: desqemu)
- **SSH:** ssh desqemu@localhost -p 2222 (пароль: desqemu)  
- **Web:** http://localhost:8080

## 📊 Размеры архивов:

EOF

# Add file sizes to release notes
for archive in desqemu-portable-microvm-*.tar.gz; do
  if [ -f "$archive" ]; then
    size=$(du -h "$archive" | cut -f1)
    arch=$(echo "$archive" | sed 's/desqemu-portable-microvm-\(.*\)\.tar\.gz/\1/')
    echo "- **$arch:** ~$size" >> portable-release-notes.md
  fi
done

cat >> portable-release-notes.md << EOF

## 🆘 Решение проблем:

\`\`\`bash
# Если KVM недоступен, отредактируйте start-microvm.sh:
# Уберите флаги: -enable-kvm -machine q35,accel=kvm:tcg
# Замените на: -machine q35,accel=tcg

# Проверка занятых портов:
netstat -tuln | grep -E ':(5900|2222|8080)'

# Запуск с другими параметрами:
MEMORY=1G CPU_CORES=4 ./start-microvm.sh
\`\`\`

## 🔗 Связанные релизы:

- [DESQEMU Alpine Docker Images]($GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/tag/$GITHUB_REF_NAME)
- [DESQEMU GitHub Container Registry](https://github.com/$GITHUB_REPOSITORY_OWNER/packages)

---

**Версия:** $GITHUB_REF_NAME
**Дата:** $(date)
**Репозиторий:** https://github.com/$GITHUB_REPOSITORY
EOF

echo "✅ Создан portable-release-notes.md" 
