# tayyebi-os Makefile

ALPINE_ISO_URL=https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-standard-3.19.0-x86_64.iso
ALPINE_ISO=alpine.iso
OUTPUT_ISO=tayyebi-os.iso
WORKDIR=/tmp/tayyebi-os-build
SETUP_SCRIPT=setup-tayyebi-os.sh

.PHONY: iso clean

iso: $(OUTPUT_ISO)

$(ALPINE_ISO):
	wget -O $(ALPINE_ISO) $(ALPINE_ISO_URL)

$(OUTPUT_ISO): $(ALPINE_ISO) $(SETUP_SCRIPT)
	rm -rf $(WORKDIR)
	mkdir -p $(WORKDIR)
	7z x $(ALPINE_ISO) -o$(WORKDIR)
	mkdir -p $(WORKDIR)/root
	mkdir -p $(WORKDIR)/etc/local.d
	cp $(SETUP_SCRIPT) $(WORKDIR)/root/$(SETUP_SCRIPT)
	cp $(WORKDIR)/root/$(SETUP_SCRIPT) $(WORKDIR)/etc/local.d/setup-tayyebi-os.start
	chmod +x $(WORKDIR)/etc/local.d/setup-tayyebi-os.start
	chroot $(WORKDIR) rc-update add local default || true
	chroot $(WORKDIR) apk del alpine-base linux-firmware-other || true
	mkisofs -o $(OUTPUT_ISO) -b boot/syslinux/isolinux.bin -c boot/syslinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table $(WORKDIR)
	@echo "ISO built: $(OUTPUT_ISO)"

clean:
	rm -rf $(WORKDIR) $(ALPINE_ISO) $(OUTPUT_ISO)
	@echo "Cleaned build artifacts."
