#!/bin/sh
set -e
set -u
set -o pipefail

# Usage: ./tools/make-iso.sh <alpine-iso-path> <output-iso-path>

ALPINE_ISO="${1:-}" # e.g. alpine-standard-3.19.0-x86_64.iso
OUTPUT_ISO="${2:-tayyebi-os.iso}"
WORKDIR="/tmp/tayyebi-os-build"
SCRIPT="setup-tayyebi-os.sh"

if [ -z "$ALPINE_ISO" ]; then
  echo "Usage: $0 <alpine-iso-path> <output-iso-path>" >&2
  exit 1
fi

rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"

# Extract ISO
7z x "$ALPINE_ISO" -o"$WORKDIR"

# Inject setup script
cp "$(dirname "$0")/../$SCRIPT" "$WORKDIR/root/$SCRIPT"

# Add script to local.d
cp "$WORKDIR/root/$SCRIPT" "$WORKDIR/etc/local.d/setup-tayyebi-os.start"
chmod +x "$WORKDIR/etc/local.d/setup-tayyebi-os.start"

# Enable local service
chroot "$WORKDIR" rc-update add local default

# Remove unnecessary packages
chroot "$WORKDIR" apk del alpine-base linux-firmware-other || true

# Repack ISO (requires mkisofs or xorriso)
mkisofs -o "$OUTPUT_ISO" -b boot/syslinux/isolinux.bin -c boot/syslinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table "$WORKDIR"

echo "ISO built: $OUTPUT_ISO"
