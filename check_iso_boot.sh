#!/bin/bash
# Script to examine boot configuration in the ISO

ISO_FILE="$1"

if [ -z "$ISO_FILE" ] || [ ! -f "$ISO_FILE" ]; then
    echo "Usage: $0 <path-to-iso>"
    exit 1
fi

TEMP_MOUNT=$(mktemp -d)
echo "Mounting ISO to examine boot configuration..."
sudo mount -o loop "$ISO_FILE" "$TEMP_MOUNT"

echo ""
echo "=== Checking .disk/info ==="
if [ -f "$TEMP_MOUNT/.disk/info" ]; then
    echo "✓ .disk/info exists"
    cat "$TEMP_MOUNT/.disk/info"
else
    echo "✗ .disk/info MISSING"
fi

echo ""
echo "=== Checking GRUB configuration ==="
if [ -f "$TEMP_MOUNT/boot/grub/grub.cfg" ]; then
    echo "✓ grub.cfg exists"
    echo ""
    echo "Search commands found:"
    grep -n "search" "$TEMP_MOUNT/boot/grub/grub.cfg" | head -20
    echo ""
    echo "Set root commands:"
    grep -n "set root" "$TEMP_MOUNT/boot/grub/grub.cfg" | head -10
else
    echo "✗ grub.cfg MISSING"
fi

echo ""
echo "=== Checking isolinux configuration ==="
if [ -f "$TEMP_MOUNT/isolinux/isolinux.cfg" ]; then
    echo "✓ isolinux.cfg exists"
fi

sudo umount "$TEMP_MOUNT"
rmdir "$TEMP_MOUNT"
