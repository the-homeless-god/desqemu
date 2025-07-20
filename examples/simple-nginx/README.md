# 🚀 Simple Nginx Demo - DESQEMU GitHub Action Example

Это простой пример использования DESQEMU GitHub Action для создания портативного десктопного приложения из Docker Compose.

## 📁 Структура проекта

```
simple-nginx/
├── docker-compose.yml          # Конфигурация приложения
├── html/                       # Веб-контент
│   └── index.html             # Демо страница
├── .github/workflows/          # GitHub Actions
│   └── build.yml              # Workflow для сборки
└── README.md                  # Этот файл
```

## 🚀 Быстрый старт

### 1. Форкните этот репозиторий

```bash
# Склонируйте репозиторий
git clone https://github.com/your-username/simple-nginx-demo.git
cd simple-nginx-demo
```

### 2. Запустите сборку

Просто запушьте в репозиторий:

```bash
git add .
git commit -m "Initial commit"
git push origin master
```

### 3. Проверьте результаты

После успешной сборки в GitHub Actions вы получите:

- **Портативные архивы**: `nginx-demo-portable-x86_64.tar.gz`
- **QCOW2 образы**: `nginx-demo-x86_64.qcow2`
- **Десктопные приложения**: `nginx-demo-desktop-x86_64/`

## 🏃‍♂️ Как использовать

### Портативный архив

```bash
# Скачайте архив
curl -LO https://github.com/your-repo/releases/download/v1.0.0/nginx-demo-portable-x86_64.tar.gz

# Распакуйте
tar -xzf nginx-demo-portable-x86_64.tar.gz
cd nginx-demo-portable-x86_64

# Запустите
./start.sh
```

### Десктопное приложение

```bash
# Windows
nginx-demo-desktop-x86_64.exe

# macOS
open nginx-demo-desktop-x86_64.dmg

# Linux
./nginx-demo-desktop-x86_64.AppImage
```

## 🌐 Доступ к приложению

После запуска:

- **🌐 Веб-приложение**: http://localhost:8080
- **📺 VNC сервер**: localhost:5900 (пароль: desqemu)
- **🔑 SSH доступ**: localhost:2222

## 🔧 Настройка

### Изменение контента

Отредактируйте файлы в папке `html/`:

```bash
# Измените главную страницу
nano html/index.html

# Добавьте новые файлы
echo "Hello World" > html/test.txt
```

### Изменение конфигурации

Отредактируйте `docker-compose.yml`:

```yaml
version: '3.8'

services:
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    # Добавьте свои настройки
    environment:
      - NGINX_HOST=localhost
```

## 📦 Что включено

### Автоматические функции

- **🖥️ X11 десктоп** - автоматический запуск
- **🌐 Chromium в kiosk режиме** - полноэкранный браузер
- **📺 VNC сервер** - удаленный доступ
- **🔑 SSH доступ** - командная строка
- **🔄 Автоперезапуск** - мониторинг процессов

### Безопасность

- **🔒 Полная изоляция** - QEMU виртуальная машина
- **🐧 Alpine Linux** - минимальная поверхность атаки
- **🛡️ Аппаратная виртуализация** - QEMU гипервизор

## 🛠️ Устранение проблем

### Приложение не запускается

1. Проверьте логи GitHub Actions
2. Убедитесь, что порт 8080 свободен
3. Проверьте VNC подключение (порт 5900)

### VNC не подключается

```bash
# Проверьте VNC сервер
vncviewer localhost:5900
# Пароль: desqemu
```

### SSH не работает

```bash
# Подключитесь по SSH
ssh -p 2222 desqemu@localhost
# Пароль: desqemu
```

## 📚 Следующие шаги

### Создайте свое приложение

1. Скопируйте структуру этого примера
2. Замените `docker-compose.yml` на ваше приложение
3. Обновите `app-name` в workflow
4. Запушьте в репозиторий

### Примеры приложений

- **WordPress**: CMS платформа
- **Nextcloud**: файловое хранилище
- **Penpot**: дизайн и прототипирование
- **Gitea**: Git сервер

## 🤝 Поддержка

- **GitHub Issues**: https://github.com/the-homeless-god/desqemu/issues
- **Документация**: https://github.com/the-homeless-god/desqemu
- **Примеры**: https://github.com/the-homeless-god/desqemu/tree/master/examples

## 📄 Лицензия

MIT License - см. [LICENSE](LICENSE) файл. 
