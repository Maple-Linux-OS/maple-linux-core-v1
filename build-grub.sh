#!/bin/bash
# Build script for maple-grub-branding_1.1-1_all.deb
# Includes text branding AND background wallpaper
# Version 1.1 - November 2024

set -e

PKG_NAME="maple-grub-branding"
PKG_VERSION="1.1-1"
PKG_DIR="${PKG_NAME}_${PKG_VERSION}"

echo "Building Maple GRUB branding package v1.1 (with wallpaper)..."

# Check for background image
if [ ! -f "maple-grub-background.png" ]; then
    echo "ERROR: maple-grub-background.png not found in current directory!"
    echo "Please place your GRUB background PNG in this directory."
    exit 1
fi

# Clean and create structure
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"/{DEBIAN,etc/default/grub.d,usr/share/images/desktop-base}

# Create control file
cat > "$PKG_DIR/DEBIAN/control" << CONTROL
Package: $PKG_NAME
Version: $PKG_VERSION
Section: misc
Priority: optional
Architecture: all
Maintainer: Maple Linux Team <team@maple-linux.org>
Description: Maple Linux Core GRUB branding
 Complete GRUB branding for Maple Linux Core including:
 - Custom text: "Maple Linux Core" instead of "Debian"
 - Red gradient background with maple leaf logo
 - Minimal, professional appearance
 This package modifies only GRUB presentation, not boot functionality.
CONTROL

# Create GRUB configuration
cat > "$PKG_DIR/etc/default/grub.d/50-maple-branding.cfg" << 'GRUB_CFG'
# Maple Linux Core - Complete GRUB branding
# Text and background customization

# Set distributor name (appears in menu entries)
GRUB_DISTRIBUTOR="Maple Linux Core"

# Set background image
GRUB_BACKGROUND="/usr/share/images/desktop-base/maple-grub-background.png"

# Keep OS prober enabled (for dual-boot detection)
GRUB_DISABLE_OS_PROBER=false
GRUB_CFG

# Copy background image
echo "  Installing background image..."
cp "maple-grub-background.png" \
    "$PKG_DIR/usr/share/images/desktop-base/maple-grub-background.png"

# Create postinst script
cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e

echo "Configuring Maple GRUB branding..."

# Update GRUB configuration
if command -v update-grub >/dev/null 2>&1; then
    echo "  Updating GRUB configuration..."
    update-grub
    echo "  [OK] GRUB branding applied"
else
    echo "  [INFO] update-grub not available (normal during installation)"
fi

exit 0
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

# Create postrm script (cleanup on removal)
cat > "$PKG_DIR/DEBIAN/postrm" << 'POSTRM'
#!/bin/bash
set -e

if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    echo "Removing Maple GRUB branding..."
    
    # Update GRUB to restore defaults
    if command -v update-grub >/dev/null 2>&1; then
        update-grub
        echo "  [OK] GRUB restored to defaults"
    fi
fi

exit 0
POSTRM
chmod 755 "$PKG_DIR/DEBIAN/postrm"

# Set permissions
echo "Setting permissions..."
find "$PKG_DIR" -type d -exec chmod 755 {} \;
find "$PKG_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$PKG_DIR/DEBIAN/postinst"
chmod 755 "$PKG_DIR/DEBIAN/postrm"

# Build package
echo "Building package..."
fakeroot dpkg-deb --build "$PKG_DIR"
mv "${PKG_DIR}.deb" "${PKG_NAME}_${PKG_VERSION}_all.deb"
rm -rf "$PKG_DIR"

echo ""
echo "[OK] Created: ${PKG_NAME}_${PKG_VERSION}_all.deb"
echo ""
echo "This package includes:"
echo "  - Text branding: 'Maple Linux Core'"
echo "  - Red gradient background with maple leaf logo"
echo "  - Professional, minimal design"
echo ""
echo "To test on your installed system:"
echo "  sudo dpkg -i ${PKG_NAME}_${PKG_VERSION}_all.deb"
echo "  sudo reboot"
