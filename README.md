# 🚀 DESQEMU Alpine Linux MicroVM

> **Docker-to-MicroVM**: Secure virtual machines with Docker ecosystem compatibility

Transform your Docker Compose applications into secure, isolated QEMU MicroVMs while keeping all the convenience of the Docker ecosystem.

## 🎯 What is this?

DESQEMU implements the **"Docker-to-MicroVM"** concept from [MergeBoard's article](https://mergeboard.com/blog/2-qemu-microvm-docker/), combining:

- 🔒 **VM-level security** (complete hypervisor isolation)
- 🐳 **Docker compatibility** (existing images and compose files)
- ⚡ **MicroVM performance** (fast boot ~200ms)
- 🎯 **Zero configuration** (automatic compose parsing)

## 📦 What You Get

Our **GitHub Actions pipeline** automatically builds **4 types of artifacts**:

| Type | File | Purpose |
|------|------|---------|
| 🐳 **Docker Image** | `desqemu-alpine-docker-*.tar.gz` | Standard Docker container |
| 📁 **Rootfs Archive** | `desqemu-alpine-rootfs-*.tar.gz` | For chroot environments |
| 🚀 **QEMU MicroVM** | `desqemu-alpine-microvm-*.qcow2` | **Ready-to-run VM image** |
| 📦 **Portable QEMU** | `desqemu-portable-microvm-*.tar.gz` | **Self-contained with QEMU** |

## 🚀 Quick Start

### Option 1: GitHub Container Registry (Recommended)

```bash
docker run -it --privileged \
  -p 8080:8080 -p 5900:5900 -p 2222:22 \
  ghcr.io/the-homeless-god/desqemu-alpine:latest
```

### Option 2: Portable Archive (No Installation)

```bash
# Download portable archive with QEMU included
curl -O https://raw.githubusercontent.com/the-homeless-god/desqemu/master/utils/download-portable.sh
chmod +x download-portable.sh
./download-portable.sh the-homeless-god/desqemu

# Extract and run - works anywhere
tar -xzf desqemu-portable-microvm-*.tar.gz
cd x86_64  # or your architecture
./start-microvm.sh
```

### Option 3: Download & Run MicroVM

```bash
# Download artifacts from GitHub Actions  
# Extract and run
./run-microvm.sh
```

### Option 4: With Your docker-compose.yml

```bash
# Inject your compose file into the VM
guestfish -a desqemu-alpine-microvm-*.qcow2 -m /dev/sda \
  copy-in docker-compose.yml /home/desqemu/

# Launch - your app will auto-start
./run-microvm.sh
```

## 🌐 Access Points

- **8080** → Your web application (auto-detected from compose)
- **5900** → VNC desktop (password: `desqemu`)
- **2222** → SSH access (user: `desqemu`)

## 📚 Documentation

| Language | Link | Description |
|----------|------|-------------|
| 🇷🇺 **Русский** | [docs/README_RU.md](docs/README_RU.md) | Полная документация на русском |
| 🇺🇸 **English** | [docs/README_EN.md](docs/README_EN.md) | Complete English documentation |

## 🏗️ Key Features

✅ **Automatic compose parsing** - Drop your `docker-compose.yml` and it just works  
✅ **Security isolation** - Full VM-level separation via QEMU hypervisor  
✅ **Multi-architecture** - x86_64, aarch64, arm64, amd64 support  
✅ **Zero setup** - Pre-configured Alpine Linux with Podman + Docker CLI  
✅ **Portable archives** - Self-contained QEMU bundles, no installation needed  
✅ **GUI support** - VNC access with automatic browser launching  
✅ **SSH ready** - Instant remote access with auto-generated keys  

## 🔗 Based On

- **Concept**: [MergeBoard - Execute Docker Containers as QEMU MicroVMs](https://mergeboard.com/blog/2-qemu-microvm-docker/)
- **OS**: [Alpine Linux](https://alpinelinux.org/) (minimal, secure)
- **Hypervisor**: [QEMU MicroVM](https://www.qemu.org/) (fast, lightweight)
- **Runtime**: [Podman](https://podman.io/) (rootless, secure)

## 📄 License

BSD 3-Clause License with additional commercial terms - see [LICENSE](LICENSE) file.

**💡 Commercial Use**: If you use this software commercially, please contact for licensing arrangements:

- 📧 Email: <zimtir@mail.ru>  
- 💬 Telegram: t.me/the_homeless_god

## 👨‍💻 Author

**Marat Zimnurov** - Creator and maintainer of DESQEMU

- 📧 Email: <zimtir@mail.ru>
- 💬 Telegram: [@the_homeless_god](https://t.me/the_homeless_god)
- 🐙 GitHub: [@the-homeless-god](https://github.com/the-homeless-god)

---

**DESQEMU** - The secure way to run Docker applications! 🛡️
