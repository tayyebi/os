# tayyebi-os Makefile

ALPINE_ISO_URL=https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-standard-3.19.0-x86_64.iso
ALPINE_ISO=alpine.iso
OUTPUT_ISO=tayyebi-os.iso
WORKDIR=/tmp/tayyebi-os-build
SETUP_SCRIPT=setup-tayyebi-os.sh

.PHONY: iso clean contrib-prereq build-deps release test mount umount

iso: $(OUTPUT_ISO)

test:
	@echo "Running ISO validation tests..."
	@chmod +x tests/validate-iso.sh
	@sudo tests/validate-iso.sh $(OUTPUT_ISO)

mount:
	@echo "Mounting $(OUTPUT_ISO) to /mnt/tayyebi-os..."
	@sudo mkdir -p /mnt/tayyebi-os
	@sudo mount -o loop,ro $(OUTPUT_ISO) /mnt/tayyebi-os
	@echo "ISO mounted at /mnt/tayyebi-os"
	@echo "To unmount, run: make umount"

umount:
	@echo "Unmounting /mnt/tayyebi-os..."
	@sudo umount /mnt/tayyebi-os || true
	@sudo rmdir /mnt/tayyebi-os || true
	@echo "ISO unmounted"

$(ALPINE_ISO):
	wget -O $(ALPINE_ISO) $(ALPINE_ISO_URL)

$(OUTPUT_ISO): $(ALPINE_ISO) $(SETUP_SCRIPT)
	rm -rf $(WORKDIR)
	mkdir -p $(WORKDIR)
	7z x $(ALPINE_ISO) -o$(WORKDIR)
	mkdir -p $(WORKDIR)/root
	mkdir -p $(WORKDIR)/etc/local.d
	# ensure common kernel/initramfs name variants exist (vmlinuzlts, initramfslts)
	mkdir -p $(WORKDIR)/boot
	cd $(WORKDIR)/boot && ln -sf vmlinuz-lts vmlinuzlts || true
	cd $(WORKDIR)/boot && ln -sf initramfs-lts initramfslts || true
	cd $(WORKDIR)/boot && ln -sf System.map-lts System.maplts || true
	cp $(SETUP_SCRIPT) $(WORKDIR)/root/$(SETUP_SCRIPT)
	cp $(WORKDIR)/root/$(SETUP_SCRIPT) $(WORKDIR)/etc/local.d/setup-tayyebi-os.start
	chmod +x $(WORKDIR)/etc/local.d/setup-tayyebi-os.start
	chroot $(WORKDIR) rc-update add local default || true
	chroot $(WORKDIR) apk del alpine-base linux-firmware-other || true
	mkisofs -o $(OUTPUT_ISO) -b boot/syslinux/isolinux.bin -c boot/syslinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table $(WORKDIR)
	@echo "ISO built: $(OUTPUT_ISO)"

# Cross-distro package install function
install_pkg = \
	if command -v apt-get >/dev/null; then \
		sudo apt-get update; \
		sudo apt-get install -y $(1); \
	elif command -v dnf >/dev/null; then \
		sudo dnf install -y $(1); \
	elif command -v yum >/dev/null; then \
		sudo yum install -y $(1); \
	elif command -v zypper >/dev/null; then \
		sudo zypper install -y $(1); \
	elif command -v pacman >/dev/null; then \
		sudo pacman -Sy --noconfirm $(1); \
	elif command -v apk >/dev/null; then \
		sudo apk add $(1); \
	else \
		echo 'No supported package manager found!'; exit 1; \
	fi

contrib-prereq:
	@echo "Installing contributor prerequisites (git, gh, shellcheck)..."
	@$(call install_pkg,git)
	@$(call install_pkg,shellcheck)
	@# Try to install gh via snap, then via package manager
	@if command -v snap >/dev/null; then \
		sudo snap install gh || true; \
	else \
		$(call install_pkg,gh) || echo "Install gh CLI manually if unavailable."; \
	fi

build-deps:
	@echo "Installing local build dependencies (p7zip-full, mkisofs)..."
	@$(call install_pkg,p7zip-full)
	@$(call install_pkg,mkisofs)

release:
	@echo "Creating v1.0 release..."
	@if ! command -v gh >/dev/null; then \
		echo 'gh CLI not found. Please install it for automated releases.'; exit 1; \
	fi
	@if ! gh auth status >/dev/null 2>&1; then \
		echo 'GitHub CLI not authenticated. Running gh auth login...'; \
		gh auth login; \
	fi
	@git pull --tags
	@git tag -d v1.0 2>/dev/null || true
	@gh release delete v1.0 --yes 2>/dev/null || true
	@git tag v1.0
	@git push origin v1.0
	@gh release create v1.0 $(OUTPUT_ISO) --title "tayyebi-os v1.0" --notes "Production-ready Alpine Linux for data centers. Includes Docker, Portainer, and automated setup. ISO validated with comprehensive test suite."
	@echo "✓ Release v1.0 created successfully!"

clean:
	rm -rf $(WORKDIR) $(ALPINE_ISO) $(OUTPUT_ISO)
	@echo "Cleaned build artifacts."
