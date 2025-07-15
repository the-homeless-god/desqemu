# 🚀 DESQEMU Alpine Linux MicroVM

A project for creating secure virtual machines based on Alpine Linux to run Docker Compose applications.

## 🎯 Concept

This project implements the **"Docker-to-MicroVM"** approach described in the article [MergeBoard: Execute Docker Containers as QEMU MicroVMs](https://mergeboard.com/blog/2-qemu-microvm-docker/).

The core idea is to combine **virtual machine security** with **Docker ecosystem convenience**:

- 🔒 **Complete isolation** at the QEMU hypervisor level
- 🐳 **Docker compatibility** - use existing images and compose files
- ⚡ **MicroVM speed** - fast boot (~200ms for kernel)
- 🎯 **Ease of use** - automatic docker-compose.yml parsing

## 📦 What GitHub Actions Creates

Our CI/CD pipeline automatically creates **3 types of images** for each architecture:

### 1. 🐳 Docker Image (`desqemu-alpine-docker-*.tar.gz`)

Full-featured Docker image with Alpine Linux and all necessary tools:

- Podman + Docker CLI + Docker Compose
- Chromium + X11/VNC for GUI applications
- SSH server + Python 3 + Node.js
- Automatic docker-compose.yml parsing

### 2. 📁 Rootfs Archive (`desqemu-alpine-rootfs-*.tar.gz`)

Filesystem for use in chroot environments:

- Ready to extract to any system
- Contains all programs and configurations
- Can be used to create custom images

### 3. 🚀 QEMU MicroVM (`desqemu-alpine-microvm-*.qcow2`)

**Main product** - ready-to-run qcow2 image for QEMU:

- Created using MergeBoard methodology
- Custom init script with automatic functions
- Ready to run with a single command
- Full network interface support

## 🏗️ Solution Architecture

```shell
Docker Ecosystem          Security Layer             QEMU MicroVM
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│ docker-compose  │  ──▶  │ Alpine Linux    │  ──▶  │ QEMU Hypervisor │
│ Docker images   │       │ + Podman        │       │ + virtio devices│
│ Existing tools  │       │ + init script   │       │ + networking    │
└─────────────────┘       └─────────────────┘       └─────────────────┘
```

## 🔧 MicroVM Automatic Functions

Our custom init script (`microvm-init.sh`) provides:

### 🌐 Network Configuration

- Automatic DHCP with fallback to static IP
- Port forwarding to host (8080, 5900, 2222)
- Hostname and routing setup

### 🐳 Docker Compose Auto-start

- Automatic detection of `/home/desqemu/docker-compose.yml`
- Port parsing from compose file
- Launch via Podman Compose
- Automatic browser opening

### 🔐 System Services

- SSH server with auto-generated keys
- Syslog for logging
- Virtual filesystem mounting
- Process management

### 🎯 Customization

- Support for custom `entrypoint.sh` scripts
- Ability to mount folders via 9p
- File injection via guestfish

## 📋 Supported Architectures

GitHub Actions creates images for:

- **x86_64** (Intel/AMD 64-bit)
- **aarch64** (ARM 64-bit)
- **arm64** (ARM 64-bit alternative)
- **amd64** (AMD 64-bit alternative)

## 🚀 Usage

### From GitHub Container Registry (recommended)

```bash
# Run ready-made image
docker run -it --privileged \
  -p 8080:8080 -p 5900:5900 -p 2222:22 \
  ghcr.io/the-homeless-god/desqemu-alpine:latest
```

### Local MicroVM Build

```bash
# Download artifacts from GitHub Actions
# Run the ready script
./run-microvm.sh
```

### With Your docker-compose.yml

```bash
# Create compose file
echo 'version: "3"
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"' > my-compose.yml

# Inject into image
guestfish -a desqemu-alpine-microvm-*.qcow2 -m /dev/sda \
  copy-in my-compose.yml /home/desqemu/

# Run
./run-microvm.sh
```

## 🌐 Available Ports

- **8080** → Your web application (auto-detected from compose)
- **5900** → VNC server (password: desqemu)
- **2222** → SSH access (user: desqemu)

## 🛠️ Technical Details

### QEMU Launch Command

```bash
qemu-system-x86_64 \
    -M microvm,x-option-roms=off,isa-serial=off,rtc=off \
    -m 512M \
    -no-acpi \
    -cpu max \
    -nodefaults \
    -no-user-config \
    -nographic \
    -no-reboot \
    -device virtio-serial-device \
    -chardev stdio,id=virtiocon0 \
    -device virtconsole,chardev=virtiocon0 \
    -drive id=root,file=desqemu-alpine-microvm-*.qcow2,format=qcow2,if=none \
    -device virtio-blk-device,drive=root \
    -netdev user,id=mynet0,hostfwd=tcp:127.0.0.1:8080-:8080,hostfwd=tcp:127.0.0.1:5900-:5900,hostfwd=tcp:127.0.0.1:2222-:22 \
    -device virtio-net-device,netdev=mynet0 \
    -device virtio-rng-device
```

### Project File Structure

```shell
desqemu/
├── microvm-init.sh              # Main init script for MicroVM
├── run-microvm-template.sh      # QEMU launch script template
├── Dockerfile                   # Alpine image build
├── .github/workflows/
│   └── alpine-podman-distribution.yml  # CI/CD pipeline
└── docs/
    ├── README_RU.md            # Documentation (Russian)
    └── README_EN.md            # Documentation (English)
```

## 🔍 Debugging and Monitoring

### System Logs

```bash
# SSH connection
ssh desqemu@localhost -p 2222

# View logs
journalctl -f                  # System logs
podman logs <container>        # Container logs
dmesg                         # Kernel logs
```

### Resource Monitoring

```bash
htop                          # Processes and memory
podman ps                     # Running containers
podman-compose ps            # Compose services status
netstat -tlnp                # Open ports
```

## 🎯 Usage Examples

### Simple Web Application

```yaml
version: '3'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
```

### Complex Application

```yaml
version: '3'
services:
  frontend:
    image: node:alpine
    ports:
      - "3000:3000"
    depends_on:
      - backend
  
  backend:
    image: python:alpine
    ports:
      - "8000:8000"
    depends_on:
      - database
  
  database:
    image: postgres:alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_PASSWORD: secret
```

## 🔗 Related Projects

- **MergeBoard Blog**: [Execute Docker Containers as QEMU MicroVMs](https://mergeboard.com/blog/2-qemu-microvm-docker/)
- **Alpine Linux**: [https://alpinelinux.org/](https://alpinelinux.org/)
- **QEMU**: [https://www.qemu.org/](https://www.qemu.org/)
- **Podman**: [https://podman.io/](https://podman.io/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on different architectures
5. Create a Pull Request

## 📄 License

This project is distributed under the BSD 3-Clause License with additional commercial terms. See [LICENSE](../LICENSE) file.

**💡 Commercial Use**: If you use this software commercially, please contact for licensing arrangements:

- 📧 Email: <zimtir@mail.ru>  
- 💬 Telegram: t.me/the_homeless_god

**🙏 Attribution Required**: Any use must clearly credit "Marat Zimnurov" as the original author and include a reference to the source repository.

## 👨‍💻 Author

**Marat Zimnurov** - Creator and maintainer of DESQEMU

- 📧 Email: <zimtir@mail.ru>
- 💬 Telegram: [@the_homeless_god](https://t.me/the_homeless_god)
- 🐙 GitHub: [@the-homeless-god](https://github.com/the-homeless-god)

---

**DESQEMU** - a bridge between the world of containers and virtual machines! 🚀
