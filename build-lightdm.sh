#!/bin/bash
# Build script for maple-lightdm-userlist_1.7-1_all.deb
# VERSION 1.7 - Bundles pre-made wallpaper, NO ImageMagick dependency
set -e

PKG_NAME="maple-lightdm-userlist"
PKG_VERSION="1.7-1"
PKG_DIR="${PKG_NAME}_${PKG_VERSION}"

echo "Building Maple LightDM theme package v1.7..."
echo "  (Bundled wallpaper, no ImageMagick)"

# Check if required files exist
if [ ! -f "maple-linux-logo-ring-symbolic.svg" ]; then
    echo "Error: maple-linux-logo-ring-symbolic.svg not found in current directory"
    exit 1
fi

if [ ! -f "maple-grub-background.png" ]; then
    echo "Error: maple-grub-background.png not found in current directory"
    echo "Please ensure the GRUB wallpaper is in the same directory as this script"
    exit 1
fi

# Clean and create structure
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"/{DEBIAN,usr/share/backgrounds,etc/lightdm}
mkdir -p "$PKG_DIR"/usr/share/lightdm/lightdm-gtk-greeter.conf.d
mkdir -p "$PKG_DIR"/usr/share/pixmaps

# Copy the Maple logo to the package
cp maple-linux-logo-ring-symbolic.svg "$PKG_DIR/usr/share/pixmaps/maple-user-logo.svg"
echo "  [OK] Added custom Maple logo"

# Bundle the GRUB wallpaper for LightDM use
cp maple-grub-background.png "$PKG_DIR/usr/share/backgrounds/maple-login-bg.png"
echo "  [OK] Bundled login wallpaper (shared with GRUB)"

# Create control file - NO ImageMagick dependency
cat > "$PKG_DIR/DEBIAN/control" << CONTROL
Package: $PKG_NAME
Version: $PKG_VERSION
Section: misc
Priority: optional
Architecture: all
Depends: lightdm
Recommends: slick-greeter | lightdm-gtk-greeter
Conflicts: maple-lightdm-minimal, maple-lightdm-theme
Replaces: maple-lightdm-minimal, maple-lightdm-theme
Maintainer: Maple Linux Team <team@maple-linux.org>
Description: Maple Linux Core LightDM theme with user list
 Provides LightDM login screen branding for Maple Linux Core.
 Red gradient wallpaper with user list enabled.
 Uses custom Maple logo for user avatars.
 Looks exactly like Debian 13 with subtle Maple branding.
 .
 No runtime dependencies on ImageMagick - wallpaper is pre-bundled.
CONTROL

# Create postinst script - NO ImageMagick, wallpaper already bundled
cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/sh
# Using /bin/sh for maximum compatibility
# Wallpaper is pre-bundled, no generation needed
set -e

echo "Setting up Maple LightDM theme with user list..."

# Simple logging - ASCII only
LOG_FILE="/var/log/maple-lightdm-install.log"
log() {
    echo "$1" | tee -a "$LOG_FILE" 2>/dev/null || echo "$1"
}

log "=== Maple LightDM Installation - $(date) ==="

# Verify bundled wallpaper
log ""
log "Step 1: Verifying bundled wallpaper..."

if [ -f /usr/share/backgrounds/maple-login-bg.png ]; then
    log "  [OK] Login wallpaper installed"
else
    log "  [ERROR] Wallpaper file missing!"
    exit 1
fi

# Configure user avatar
log ""
log "Step 2: Configuring user avatar..."
MAPLE_USER_ICON="/usr/share/pixmaps/maple-user-logo.svg"

if [ -f "$MAPLE_USER_ICON" ]; then
    log "  [OK] Custom Maple logo found"
else
    log "  [WARN] Maple logo not found, using system default"
    MAPLE_USER_ICON="/usr/share/icons/Adwaita/96x96/status/avatar-default.png"
fi

# Configure slick-greeter
log ""
log "Step 3: Configuring slick-greeter..."

if command -v slick-greeter >/dev/null 2>&1; then
    mkdir -p /etc/lightdm
    
    cat > /etc/lightdm/slick-greeter.conf << SLICK
# Maple Linux Core - LightDM Configuration
[Greeter]
background=/usr/share/backgrounds/maple-login-bg.png
disable-user-list=false
greeter-hide-users=false
draw-user-backgrounds=false
default-user-image=$MAPLE_USER_ICON
show-user-greeter=true
draw-grid=false
theme-name=Mint-Y-Red
icon-theme-name=Mint-Y-Red
font-name=Sans 11
SLICK
    
    log "  [OK] slick-greeter configured"
else
    log "  [WARN] slick-greeter not installed"
fi

# Configure gtk-greeter (fallback)
log ""
log "Step 4: Configuring gtk-greeter (fallback)..."

if command -v lightdm-gtk-greeter >/dev/null 2>&1; then
    mkdir -p /usr/share/lightdm/lightdm-gtk-greeter.conf.d
    
    cat > /usr/share/lightdm/lightdm-gtk-greeter.conf.d/99-maple-userlist.conf << GTK
# Maple Linux Core GTK Greeter Configuration
[greeter]
background = /usr/share/backgrounds/maple-login-bg.png
hide-user-list = false
greeter-hide-users = false
default-user-image = $MAPLE_USER_ICON
theme-name = Mint-Y-Red
icon-theme-name = Mint-Y-Red
font-name = Ubuntu 11
GTK
    
    log "  [OK] gtk-greeter configured"
else
    log "  [WARN] gtk-greeter not installed"
fi

# Update main LightDM config
log ""
log "Step 5: Updating main LightDM configuration..."

if [ -f /etc/lightdm/lightdm.conf ]; then
    if [ ! -f /etc/lightdm/lightdm.conf.maple-backup ]; then
        cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.maple-backup 2>/dev/null || true
        log "  [OK] Backed up original lightdm.conf"
    fi
    
    if grep -q "^greeter-hide-users" /etc/lightdm/lightdm.conf 2>/dev/null; then
        sed -i 's/^greeter-hide-users=.*/greeter-hide-users=false/' /etc/lightdm/lightdm.conf
        log "  [OK] Updated greeter-hide-users setting"
    else
        if grep -q "^\[Seat:\*\]" /etc/lightdm/lightdm.conf 2>/dev/null; then
            sed -i '/^\[Seat:\*\]/a greeter-hide-users=false' /etc/lightdm/lightdm.conf
            log "  [OK] Added greeter-hide-users setting"
        else
            echo "" >> /etc/lightdm/lightdm.conf
            echo "[Seat:*]" >> /etc/lightdm/lightdm.conf
            echo "greeter-hide-users=false" >> /etc/lightdm/lightdm.conf
            log "  [OK] Created [Seat:*] section"
        fi
    fi
else
    log "  [WARN] /etc/lightdm/lightdm.conf not found"
fi

log ""
log "SUCCESS: Maple LightDM theme configured!"
log "  * No ImageMagick needed - wallpaper pre-bundled"
log "  * Shared wallpaper with GRUB for consistency"
log ""

exit 0
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

# Create prerm script
cat > "$PKG_DIR/DEBIAN/prerm" << 'PRERM'
#!/bin/sh
set -e

echo "Removing Maple LightDM configuration..."

if [ "$1" = "remove" ] || [ "$1" = "purge" ]; then
    if [ -f /etc/lightdm/lightdm.conf.maple-backup ]; then
        cp /etc/lightdm/lightdm.conf.maple-backup /etc/lightdm/lightdm.conf 2>/dev/null || true
        echo "  [OK] Restored original lightdm.conf"
    fi
    
    rm -f /etc/lightdm/slick-greeter.conf 2>/dev/null || true
    rm -f /usr/share/lightdm/lightdm-gtk-greeter.conf.d/99-maple-userlist.conf 2>/dev/null || true
    echo "  [OK] Removed Maple greeter configurations"
fi

exit 0
PRERM
chmod 755 "$PKG_DIR/DEBIAN/prerm"

# Fix permissions
echo ""
echo "Setting correct permissions..."
find "$PKG_DIR" -type d -exec chmod 755 {} \;
find "$PKG_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$PKG_DIR/DEBIAN/postinst"
chmod 755 "$PKG_DIR/DEBIAN/prerm"

# Build package
echo ""
echo "Building package..."
fakeroot dpkg-deb --build "$PKG_DIR"

if [ ! -f "${PKG_DIR}.deb" ]; then
    echo "[ERROR] Package file was not created"
    exit 1
fi

mv "${PKG_DIR}.deb" "${PKG_NAME}_${PKG_VERSION}_all.deb"

# Verify package
echo ""
echo "Verifying package integrity..."
if dpkg-deb --info "${PKG_NAME}_${PKG_VERSION}_all.deb" >/dev/null 2>&1; then
    echo "  [OK] Package structure is valid"
else
    echo "  [ERROR] Package structure is invalid"
    exit 1
fi

rm -rf "$PKG_DIR"

echo ""
echo "================================================================"
echo "  SUCCESS: ${PKG_NAME}_${PKG_VERSION}_all.deb"
echo "================================================================"
echo ""
ls -lh "${PKG_NAME}_${PKG_VERSION}_all.deb"
echo ""
echo "Changes in v1.7:"
echo "  * NO ImageMagick dependency"
echo "  * Pre-bundled wallpaper (maple-grub-background.png)"
echo "  * Consistent branding: same wallpaper as GRUB"
echo "  * Reduced installation dependencies"
echo "  * Faster installation (no image generation)"
echo ""
echo "Files included:"
echo "  * /usr/share/backgrounds/maple-login-bg.png (bundled)"
echo "  * /usr/share/pixmaps/maple-user-logo.svg (logo)"
echo ""
