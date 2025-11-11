#!/bin/bash
# Maple Linux Minimal Plymouth Theme Builder
# Version 1.2 - Fixed black screen issue
# Run from your main maple-linux build directory
# Uses assets from current directory

set -e

PKG_NAME="maple-plymouth-theme"
PKG_VERSION="1.0-2"  # Increment version for the fix

echo "================================================"
echo "  Maple Linux Minimal Plymouth Theme Builder"
echo "  Version 1.2 - Black Screen Fix"
echo "================================================"
echo ""

# Check for required assets in current directory
echo "[1/7] Checking for required assets..."

WALLPAPER="maple-grub-background.png"

if [ ! -f "$WALLPAPER" ]; then
    echo "[ERROR] Wallpaper not found!"
    echo ""
    echo "Required file:"
    echo "  * maple-grub-background.png (shared with GRUB and LightDM)"
    echo ""
    echo "Current directory: $PWD"
    echo ""
    exit 1
fi

echo "   [OK] Found wallpaper: $WALLPAPER (shared with GRUB and LightDM)"

# Check dependencies
echo ""
echo "[2/7] Checking dependencies..."
MISSING_DEPS=()
command -v dpkg-deb &> /dev/null || MISSING_DEPS+=("dpkg-dev")
command -v fakeroot &> /dev/null || MISSING_DEPS+=("fakeroot")

if [ ${#MISSING_DEPS[@]} -gt 0 ]; then
    echo "[ERROR] Missing required packages: ${MISSING_DEPS[*]}"
    echo "   Install with: sudo apt install ${MISSING_DEPS[*]}"
    exit 1
fi
echo "   [OK] All dependencies present"

# Clean and create structure
echo ""
echo "[3/7] Creating package structure..."
rm -rf "${PKG_NAME}_${PKG_VERSION}"
mkdir -p "${PKG_NAME}_${PKG_VERSION}"/{DEBIAN,usr/share/plymouth/themes/maple}

THEME_DIR="${PKG_NAME}_${PKG_VERSION}/usr/share/plymouth/themes/maple"
echo "   [OK] Package structure created"

# Copy wallpaper
echo ""
echo "[4/7] Copying assets..."
cp "$WALLPAPER" "$THEME_DIR/background.png"
echo "   [OK] Copied wallpaper as background.png"

# Create Plymouth config
echo ""
echo "[5/7] Creating Plymouth configuration files..."

cat > "$THEME_DIR/maple.plymouth" << 'EOF'
[Plymouth Theme]
Name=Maple Linux
Description=Maple Linux Core boot theme
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/maple
ScriptFile=/usr/share/plymouth/themes/maple/maple.script
EOF

echo "   [OK] Created maple.plymouth"

# Create FIXED Plymouth script with proper image scaling
cat > "$THEME_DIR/maple.script" << 'EOF'
# Maple Linux Plymouth Theme
# Fixed version: Properly scales wallpaper to screen size

# Get screen dimensions
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();

# Load and scale wallpaper to fill screen
background_image = Image("background.png");
background_scaled = background_image.Scale(screen_width, screen_height);
background_sprite = Sprite(background_scaled);
background_sprite.SetPosition(0, 0, 0);

# Progress bar at bottom
progress_bar = {
    width = screen_width * 0.5,
    height = 6,
    x = 0,
    y = 0,
};

progress_bar.x = (screen_width - progress_bar.width) / 2;
progress_bar.y = screen_height - 60;

# Create progress bar sprites
progress_bar.background_sprite = Sprite();
progress_bar.foreground_sprite = Sprite();

progress_bar.background_sprite.SetPosition(progress_bar.x, progress_bar.y, 1);
progress_bar.foreground_sprite.SetPosition(progress_bar.x, progress_bar.y, 2);

# Update function
fun refresh_callback() {
    progress = Plymouth.GetBootProgress();
    
    if (progress > 0) {
        # Background bar (dark red)
        bg_image = Image.Text("", 0.541, 0.086, 0.133);
        bg_image = bg_image.Scale(progress_bar.width, progress_bar.height);
        progress_bar.background_sprite.SetImage(bg_image);
        
        # Foreground bar (bright red)
        fg_width = progress_bar.width * progress;
        if (fg_width > 0) {
            fg_image = Image.Text("", 0.800, 0.133, 0.200);
            fg_image = fg_image.Scale(fg_width, progress_bar.height);
            progress_bar.foreground_sprite.SetImage(fg_image);
        }
    }
}

Plymouth.SetRefreshFunction(refresh_callback);

# Message display (for boot messages)
message_sprite = Sprite();
message_sprite.SetPosition(screen_width / 2, screen_height - 100, 10);

fun message_callback(text) {
    if (text == "") {
        message_sprite.SetImage(NULL);
    } else {
        message_image = Image.Text(text, 1.0, 1.0, 1.0);
        message_sprite.SetImage(message_image);
    }
}

Plymouth.SetMessageFunction(message_callback);
EOF

echo "   [OK] Created maple.script (with proper image scaling)"

# Create DEBIAN control file
cat > "${PKG_NAME}_${PKG_VERSION}/DEBIAN/control" << EOF
Package: maple-plymouth-theme
Version: 1.0-2
Section: misc
Priority: optional
Architecture: all
Recommends: plymouth, plymouth-themes
Maintainer: Maple Linux Team <team@maple-linux.org>
Description: Maple Linux Plymouth boot theme
 Minimal Plymouth theme for Maple Linux Core featuring:
 - Maple Linux wallpaper background (properly scaled)
 - Uses same wallpaper as GRUB and LightDM for consistency
 - Simple progress bar
 - Clean, professional appearance
 .
 Version 1.0-2 fixes black screen issue by properly scaling
 the wallpaper image to screen dimensions.
 .
 Uses script module for maximum compatibility.
 Perfect for encrypted and non-encrypted installations.
 Aligns with Debian's approach by using Plymouth as intended.
EOF

echo "   [OK] Created control file (v1.0-2)"

# Create postinst script
cat > "${PKG_NAME}_${PKG_VERSION}/DEBIAN/postinst" << 'EOF'
#!/bin/bash
# Maple Plymouth Theme - Post Install

case "$1" in
    configure)
        # Detect if in installation environment (Calamares)
        IN_INSTALLATION=false
        if [ ! -d /run/systemd/system ]; then
            IN_INSTALLATION=true
        fi
        
        # Only configure if Plymouth is actually installed
        if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
            echo "Plymouth not installed, skipping theme configuration"
            exit 0
        fi
        
        # Set as default theme
        plymouth-set-default-theme maple 2>/dev/null || true
        
        # Register with update-alternatives
        if command -v update-alternatives >/dev/null 2>&1; then
            update-alternatives --install \
                /usr/share/plymouth/themes/default.plymouth \
                default.plymouth \
                /usr/share/plymouth/themes/maple/maple.plymouth \
                100 2>/dev/null || true
            
            update-alternatives --set default.plymouth \
                /usr/share/plymouth/themes/maple/maple.plymouth 2>/dev/null || true
        fi
        
        # Only update initramfs if NOT in installation
        if [ "$IN_INSTALLATION" = false ]; then
            if command -v update-initramfs >/dev/null 2>&1; then
                update-initramfs -u -k all 2>/dev/null || true
            fi
        fi
        ;;
esac

exit 0
EOF

chmod 755 "${PKG_NAME}_${PKG_VERSION}/DEBIAN/postinst"
echo "   [OK] Created postinst script"

# Create prerm script
cat > "${PKG_NAME}_${PKG_VERSION}/DEBIAN/prerm" << 'EOF'
#!/bin/bash
# Maple Plymouth Theme - Pre Remove

case "$1" in
    remove|deconfigure)
        # Only try to revert if Plymouth is installed
        if command -v plymouth-set-default-theme >/dev/null 2>&1; then
            plymouth-set-default-theme --reset 2>/dev/null || true
        fi
        
        # Remove from alternatives
        if command -v update-alternatives >/dev/null 2>&1; then
            update-alternatives --remove default.plymouth \
                /usr/share/plymouth/themes/maple/maple.plymouth 2>/dev/null || true
        fi
        
        # Update initramfs
        if command -v update-initramfs >/dev/null 2>&1; then
            update-initramfs -u -k all 2>/dev/null || true
        fi
        ;;
esac

exit 0
EOF

chmod 755 "${PKG_NAME}_${PKG_VERSION}/DEBIAN/prerm"
echo "   [OK] Created prerm script"

# Fix permissions (CRITICAL!)
echo ""
echo "[6/7] Fixing permissions..."

# Directories: 755
find "${PKG_NAME}_${PKG_VERSION}" -type d -exec chmod 755 {} \;

# Files: 644
find "${PKG_NAME}_${PKG_VERSION}" -type f -exec chmod 644 {} \;

# DEBIAN scripts: 755
chmod 755 "${PKG_NAME}_${PKG_VERSION}/DEBIAN/postinst" 2>/dev/null || true
chmod 755 "${PKG_NAME}_${PKG_VERSION}/DEBIAN/prerm" 2>/dev/null || true

echo "   [OK] Permissions set (755 dirs, 644 files, 755 scripts)"

# Build package with fakeroot (ensures root:root ownership)
echo ""
echo "[7/7] Building package..."
fakeroot dpkg-deb --build "${PKG_NAME}_${PKG_VERSION}"

# Rename to proper convention
mv "${PKG_NAME}_${PKG_VERSION}.deb" "${PKG_NAME}_${PKG_VERSION}_all.deb"

echo "   [OK] Package built with root:root ownership"

# Summary
echo ""
echo "================================================"
echo "  SUCCESS!"
echo "================================================"
echo ""
echo "Created: ${PKG_NAME}_${PKG_VERSION}_all.deb"
ls -lh "${PKG_NAME}_${PKG_VERSION}_all.deb"
echo ""

# Show package contents
echo "Package contents:"
dpkg-deb -c "${PKG_NAME}_${PKG_VERSION}_all.deb" | grep -E "\.png$|\.plymouth$|\.script$"

echo ""
echo "Theme files:"
echo "  * maple.plymouth (config)"
echo "  * maple.script (FIXED - properly scales wallpaper)"
echo "  * background.png (your wallpaper)"
echo ""
echo "================================================"
echo "  What Was Fixed in v1.2"
echo "================================================"
echo ""
echo "BLACK SCREEN FIX:"
echo "  - Wallpaper now properly scaled to screen dimensions"
echo "  - Added: background_image.Scale(screen_width, screen_height)"
echo "  - Uses Window.GetWidth() and GetHeight() for proper sizing"
echo ""
echo "This should eliminate the black screen issue!"
echo ""
echo "================================================"
echo "  Next Steps"
echo "================================================"
echo ""
echo "1. Update build_debian_config.sh:"
echo "   Change: PLYMOUTH_PKG=\"maple-plymouth-theme_1.0-2_all.deb\""
echo ""
echo "2. Rebuild ISO with updated package"
echo ""
echo "3. Test - wallpaper should now appear!"
echo ""
# Clean up build directory
rm -rf "${PKG_NAME}_${PKG_VERSION}"
