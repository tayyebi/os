# tayyebi-os

[![Build ISO](https://github.com/tayyebi/os/actions/workflows/build-iso.yml/badge.svg)](https://github.com/tayyebi/os/actions/workflows/build-iso.yml)
[![Release](https://img.shields.io/github/v/release/tayyebi/os?label=latest%20ISO)](https://github.com/tayyebi/os/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

> **Minimal, automated Alpine Linux for data centers.**
>
> Boots fast, runs Docker & Portainer out of the box, and is ready for cloud or bare metal deployment.

---

## 🚀 Features

- **Ultra-minimal Alpine base** — tiny footprint, fast boot
- **Full disk & network support** — default Alpine kernel drivers
- **Docker pre-installed** — ready for containers
- **Portainer UI** — manage Docker visually
- **First-boot setup prompt** — guides admin setup
- **Automated ISO builds** — every push triggers a new release

---

## 🏁 Quick Start

1. **Download the latest ISO** from [Releases](https://github.com/tayyebi/os/releases).
2. **Write to USB**:
   ```sh
   sudo dd if=tayyebi-os-<version>.iso of=/dev/sdX bs=4M status=progress
   sync
   ```
3. **Boot your server** and follow the Portainer setup prompt.

---

## 🛠️ Automated Build & CI/CD

Every push to `main` triggers GitHub Actions:
- Downloads Alpine ISO
- Injects Docker & Portainer setup scripts
- Builds tayyebi-os ISO
- Publishes ISO to [Releases](https://github.com/tayyebi/os/releases)

See `.github/workflows/build-iso.yml` for details.

---

## � Testing & Validation

Run the ISO validation tests to ensure the ISO is installable:

```sh
make test
```

This runs `tests/validate-iso.sh`, which checks:
- ISO structure and validity
- Kernel and initramfs presence
- Boot configuration files
- Setup script presence and syntax
- Symlink variants for compatibility

All tests must pass before deployment.

---

## �🧑‍💻 Manual Build Instructions

1. Download Alpine Linux (sys) ISO: https://alpinelinux.org/downloads/
2. Extract ISO contents and copy to a working directory.
3. Add the post-install script as `/root/setup-tayyebi-os.sh`:
   ```sh
   #!/bin/sh
   apk update
   apk add docker
   rc-update add docker boot
   service docker start
   PORTAINER_DATA="/opt/portainer"
   mkdir -p $PORTAINER_DATA
   docker run -d \
     --name=portainer \
     --restart=always \
     -p 9000:9000 \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v $PORTAINER_DATA:/data \
     portainer/portainer-ce
   cat <<EOF
   ============================
   Portainer is running on port 9000.
   Please connect via browser and set up your admin account.
   ============================
   EOF
   ```
4. Add script to `/etc/local.d/` and enable local service:
   ```sh
   cp /root/setup-tayyebi-os.sh /etc/local.d/setup-tayyebi-os.start
   chmod +x /etc/local.d/setup-tayyebi-os.start
   rc-update add local default
   ```
5. Remove unnecessary packages:
   ```sh
   apk del alpine-base linux-firmware-other
   ```
6. Remaster the ISO using `alpine-make-iso` or manual squashfs editing.

---

## ✅ Test Checklist

- [ ] ISO boots on real & virtual hardware (QEMU, VirtualBox, bare metal)
- [ ] Docker service starts automatically
- [ ] Portainer accessible on port 9000
- [ ] First boot prompt appears and is clear
- [ ] Unnecessary packages are removed
- [ ] Setup script is idempotent and logs errors

---

## 🤝 Contributing

Pull requests and issues are welcome! Please:
- Open issues for bugs or feature requests
- Fork and submit PRs for improvements

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.

---

**Author:** GitHub Copilot