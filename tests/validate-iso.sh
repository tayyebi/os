#!/bin/bash
set -e

# ISO Validation Test Suite for tayyebi-os
# Tests ISO structure, boot configs, kernel presence, and setup script

ISO_FILE="${1:-tayyebi-os.iso}"
TEST_MOUNT="/tmp/test-iso-mount-$$"
PASSED=0
FAILED=0

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_pass() {
  echo -e "${GREEN}✓ PASS${NC}: $1"
  ((PASSED++))
}

log_fail() {
  echo -e "${RED}✗ FAIL${NC}: $1"
  ((FAILED++))
}

log_info() {
  echo -e "${YELLOW}ℹ INFO${NC}: $1"
}

cleanup() {
  if mountpoint -q "$TEST_MOUNT" 2>/dev/null; then
    sudo umount "$TEST_MOUNT" || true
  fi
  rmdir "$TEST_MOUNT" 2>/dev/null || true
}

trap cleanup EXIT

# Check if ISO exists
if [ ! -f "$ISO_FILE" ]; then
  echo -e "${RED}ERROR: ISO file '$ISO_FILE' not found!${NC}"
  exit 1
fi

log_info "Starting ISO validation tests for '$ISO_FILE'"
echo ""

# Test 1: ISO file is valid
log_info "Test 1: Validating ISO structure..."
if file "$ISO_FILE" | grep -q "ISO 9660"; then
  log_pass "ISO file is valid ISO 9660"
else
  log_fail "ISO file is not valid ISO 9660"
fi

# Test 2: Mount ISO and check contents
log_info "Test 2: Checking ISO contents..."
mkdir -p "$TEST_MOUNT"

if sudo mount -o loop,ro "$ISO_FILE" "$TEST_MOUNT" 2>/dev/null; then
  log_pass "ISO mounted successfully"
  
  # Test 2a: Check boot directory exists
  if [ -d "$TEST_MOUNT/boot" ]; then
    log_pass "Boot directory exists"
  else
    log_fail "Boot directory missing"
  fi
  
  # Test 2b: Check for kernel
  if [ -f "$TEST_MOUNT/boot/vmlinuz-lts" ]; then
    log_pass "Kernel (vmlinuz-lts) found"
  else
    log_fail "Kernel (vmlinuz-lts) not found"
  fi
  
  # Test 2c: Check for kernel symlink variants
  if [ -L "$TEST_MOUNT/boot/vmlinuzlts" ]; then
    log_pass "Kernel symlink (vmlinuzlts) exists"
  else
    log_fail "Kernel symlink (vmlinuzlts) missing"
  fi
  
  # Test 2d: Check for initramfs
  if [ -f "$TEST_MOUNT/boot/initramfs-lts" ]; then
    log_pass "Initramfs (initramfs-lts) found"
  else
    log_fail "Initramfs (initramfs-lts) not found"
  fi
  
  # Test 2e: Check for initramfs symlink variants
  if [ -L "$TEST_MOUNT/boot/initramfslts" ]; then
    log_pass "Initramfs symlink (initramfslts) exists"
  else
    log_fail "Initramfs symlink (initramfslts) missing"
  fi
  
  # Test 2f: Check syslinux/isolinux boot configs
  if [ -f "$TEST_MOUNT/boot/syslinux/isolinux.cfg" ]; then
    log_pass "Isolinux config found"
    if grep -q "vmlinuz" "$TEST_MOUNT/boot/syslinux/isolinux.cfg"; then
      log_pass "Isolinux config references kernel"
    else
      log_fail "Isolinux config does not reference kernel"
    fi
  else
    log_fail "Isolinux config missing"
  fi
  
  # Test 2g: Check for setup script
  if [ -f "$TEST_MOUNT/root/setup-tayyebi-os.sh" ]; then
    log_pass "Setup script found in /root/"
  else
    log_fail "Setup script missing from /root/"
  fi
  
  # Test 2h: Check for setup script in local.d
  if [ -f "$TEST_MOUNT/etc/local.d/setup-tayyebi-os.start" ]; then
    log_pass "Setup script found in /etc/local.d/"
  else
    log_fail "Setup script missing from /etc/local.d/"
  fi
  
  # Test 2i: Check setup script is executable
  if [ -x "$TEST_MOUNT/etc/local.d/setup-tayyebi-os.start" ]; then
    log_pass "Setup script is executable"
  else
    log_fail "Setup script is not executable"
  fi
  
  # Test 2j: Validate setup script syntax
  if sh -n "$TEST_MOUNT/etc/local.d/setup-tayyebi-os.start" 2>/dev/null; then
    log_pass "Setup script has valid shell syntax"
  else
    log_fail "Setup script has shell syntax errors"
  fi
  
  # Test 2k: Check for grub config
  if [ -f "$TEST_MOUNT/boot/grub/grub.cfg" ]; then
    log_pass "GRUB config found"
    if grep -q "vmlinuz" "$TEST_MOUNT/boot/grub/grub.cfg"; then
      log_pass "GRUB config references kernel"
    else
      log_fail "GRUB config does not reference kernel"
    fi
  else
    log_fail "GRUB config missing"
  fi
  
  # Unmount ISO
  sudo umount "$TEST_MOUNT"
  log_pass "ISO unmounted successfully"
else
  log_fail "Failed to mount ISO (requires sudo)"
fi

echo ""
log_info "Test Summary:"
echo -e "  ${GREEN}Passed: $PASSED${NC}"
echo -e "  ${RED}Failed: $FAILED${NC}"
echo ""

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}All tests passed! ISO is ready for installation.${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed. ISO may not be installable.${NC}"
  exit 1
fi
