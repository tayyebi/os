docker run -d \
  --name=portainer \
  --restart=always \
  -p 9000:9000 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $PORTAINER_DATA:/data \
  portainer/portainer-ce


# tayyebi-os

**Author:** GitHub Copilot

[![Build ISO](https://github.com/tayyebi/os/actions/workflows/build-iso.yml/badge.svg)](https://github.com/tayyebi/os/actions/workflows/build-iso.yml)
[![Release](https://img.shields.io/github/v/release/tayyebi/os?label=latest%20ISO)](https://github.com/tayyebi/os/releases)

Minimal Alpine-based Linux distribution for data centers, with Docker and Portainer pre-installed. Automated ISO builds are available in [GitHub Releases](https://github.com/tayyebi/os/releases).

---

## Features

- Alpine Linux base (minimal footprint)
- All disk and network drivers (default Alpine kernel)
- Docker installed and enabled
- Portainer installed via Docker
- First boot prompts for Portainer connection info
- Ready for data center deployment

---

## Quick Start

1. Download the latest tayyebi-os ISO from [Releases](https://github.com/tayyebi/os/releases).
2. Write the ISO to a USB drive:
  ```sh
  sudo dd if=tayyebi-os-<version>.iso of=/dev/sdX bs=4M status=progress
  sync
  ```
3. Boot your server from the USB and follow the on-screen instructions to set up Portainer.

---

## Automated Build & Release

Every push to `main` triggers a GitHub Actions workflow that:
- Builds a tayyebi-os ISO from Alpine Linux
- Injects Docker and Portainer setup scripts
- Publishes the ISO as a release artifact

See `.github/workflows/build-iso.yml` for details.

---

## Manual Build Instructions

1. Download Alpine Linux (sys) ISO: https://alpinelinux.org/downloads/
2. Extract ISO contents and copy to a working directory.
3. Add the following post-install script as `/root/setup-tayyebi-os.sh`:
  ```sh
  #!/bin/sh
  apk update
  apk add docker
  rc-update add docker boot
  service docker start
  # Install Portainer
  PORTAINER_DATA="/opt/portainer"
  mkdir -p $PORTAINER_DATA

  docker run -d \
    --name=portainer \
    --restart=always \
    -p 9000:9000 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $PORTAINER_DATA:/data \
    portainer/portainer-ce

  # Prompt for Portainer connection info
  cat <<EOF
  ============================
  Portainer is running on port 9000.
  Please connect via browser and set up your admin account.
  ============================
  EOF
  ```
4. Add `setup-tayyebi-os.sh` to `/etc/local.d/` and enable local service:
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

## Contributing

Pull requests are welcome! Please open issues for feature requests or bug reports.

---

## Testing & Validation

Before releasing a new ISO, validate:
- [ ] ISO boots on real and virtual hardware (QEMU, VirtualBox, bare metal)
- [ ] Docker service starts automatically
- [ ] Portainer is accessible on port 9000
- [ ] First boot prompt appears and is clear
- [ ] Unnecessary packages are removed
- [ ] Setup script is idempotent and logs errors

## License

MIT License. See [LICENSE](LICENSE) for details.