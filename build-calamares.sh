#!/bin/bash
# Build script for maple-calamares-branding_1.6-1_all.deb
# UPDATED VERSION - November 2024
# 
# Changes in version 1.6:
# - Added supportedLocales to explicitly generate Canadian locales
# - Ensures installed system uses en_CA.UTF-8 regardless of live session locale
# - Fixes issue where live session en_GB was overriding installed system locale

set -e

PKG_NAME="maple-calamares-branding"
PKG_VERSION="1.6-1"
PKG_DIR="${PKG_NAME}_${PKG_VERSION}"

echo "Building Maple Calamares branding package v1.6..."

# Clean and create structure
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"/{DEBIAN,etc/calamares}
mkdir -p "$PKG_DIR"/etc/calamares/branding/maple
mkdir -p "$PKG_DIR"/etc/calamares/modules

# Create control file
cat > "$PKG_DIR/DEBIAN/control" << CONTROL
Package: $PKG_NAME
Version: $PKG_VERSION
Section: misc
Priority: optional
Architecture: all
Depends: calamares, calamares-settings-debian
Maintainer: Maple Linux Team <team@maple-linux.org>
Description: Maple Linux Core Calamares installer branding
 Visual branding for the Calamares installer including:
 - Custom logo and welcome screen
 - Branded slideshow during installation
 - Maple color scheme and styling
 - Canadian defaults (America/Toronto timezone, en_CA locale, US keyboard)
 Provides locale.conf and keyboard.conf which calamares-settings-debian
 does not ship.
CONTROL

# Create branding.desc
cat > "$PKG_DIR/etc/calamares/branding/maple/branding.desc" << 'BRANDING_DESC'
---
componentName:   maple
welcomeStyleCalamares: true
welcomeExpandingLogo:  true
windowExpanding: normal
windowSize: 800px,580px
windowPlacement: center

strings:
    productName:         "Maple Linux Core"
    shortProductName:    "Maple Linux"
    version:             "1.0 (Southwold)"
    shortVersion:        "1.0"
    versionedName:       "Maple Linux Core 1.0 (Southwold)"
    shortVersionedName:  "Maple Linux Core 1.0"
    bootloaderEntryName: "Maple Linux Core"
    productUrl:          "https://maplelinux.ca"
    supportUrl:          "https://maplelinux.ca/support"
    knownIssuesUrl:      "https://maplelinux.ca/issues"
    releaseNotesUrl:     "https://maplelinux.ca/releases"

sidebar: widget
navigation: widget

images:
    productLogo:         "maple-linux-logo-ring-symbolic.svg"
    productIcon:         "maple-linux-logo-ring-symbolic.svg"
    productWelcome:      "welcome.png"

slideshow: "show.qml"

style:
   SidebarBackground:        "#8a1622"
   SidebarText:              "#f6f6f6"
   SidebarTextCurrent:       "#f6f6f6"
   SidebarBackgroundCurrent: "#8a1622"

languages:
  - en_GB
  - en
  - en_US
  - fr

slideshowAPI: 2
BRANDING_DESC

# Create slideshow
cat > "$PKG_DIR/etc/calamares/branding/maple/show.qml" << 'SLIDESHOW'
import QtQuick 2.5
import calamares.slideshow 1.0

Presentation {
    id: presentation
    
    Timer {
        interval: 10000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }
    
    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#2c0808"
            Text {
                anchors.centerIn: parent
                color: "white"
                font.pixelSize: 48
                font.bold: true
                text: "Welcome to Maple Linux Core"
            }
        }
    }
    
    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#2c0808"
            Column {
                anchors.centerIn: parent
                spacing: 20
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#dc3545"
                    font.pixelSize: 36
                    font.bold: true
                    text: "Simple and Reliable"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "white"
                    font.pixelSize: 18
                    text: "Maple Linux Core provides a stable,\nuser-friendly computing experience."
                }
            }
        }
    }
}
SLIDESHOW

# Create locale.conf - THIS FILE DOESN'T EXIST IN calamares-settings-debian!
cat > "$PKG_DIR/etc/calamares/modules/locale.conf" << 'LOCALE_CONF'
---
# Maple Linux Core - Locale Configuration
# This file is provided by maple-calamares-branding because
# calamares-settings-debian does not ship locale.conf

# Pre-select Toronto timezone for Canadian users
region: "America"
zone: "Toronto"

# Locale generation
localeGenPath: "/etc/locale.gen"

# Starting locale - Canadian English
# This ensures the installed system uses Canadian English
startingLocale: "en_CA.UTF-8"

# Explicitly list locales to be generated during installation
# This ensures Canadian locales are available regardless of live session locale
supportedLocales:
  - en_CA.UTF-8 UTF-8
  - fr_CA.UTF-8 UTF-8
  - en_US.UTF-8 UTF-8
  - en_GB.UTF-8 UTF-8
  - fr_FR.UTF-8 UTF-8

# Disable GeoIP to ensure our defaults are used
geoip:
    style: "none"
    url: ""

# Adjust live timezone (system clock in installer)
adjustLiveTimezone: true
LOCALE_CONF

# Create keyboard.conf - THIS FILE DOESN'T EXIST IN calamares-settings-debian!
cat > "$PKG_DIR/etc/calamares/modules/keyboard.conf" << 'KEYBOARD_CONF'
---
# Maple Linux Core - Keyboard Configuration
# This file is provided by maple-calamares-branding because
# calamares-settings-debian does not ship keyboard.conf

# X11 keyboard configuration
xOrgConfFileName: "/etc/X11/xorg.conf.d/00-keyboard.conf"
convertedKeymapPath: "/lib/kbd/keymaps/xkb"

# Pre-select US keyboard layout (most common for Canadian English users)
defaultLayout: "us"
defaultVariant: ""

# Available layouts users can choose from
additionalLayouts:
    - us
    - ca
    - gb
    - fr
    - de
    - es
    - it
    - pt
    - ru
    - jp
KEYBOARD_CONF

# Create images
echo "Setting up branding images..."

# Copy custom SVG logo if present
if [ -f "maple-linux-logo-ring-symbolic.svg" ]; then
    echo "  Using custom SVG logo"
    cp "maple-linux-logo-ring-symbolic.svg" \
        "$PKG_DIR/etc/calamares/branding/maple/maple-linux-logo-ring-symbolic.svg"
else
    echo "  Warning: maple-linux-logo-ring-symbolic.svg not found in current directory"
    echo "  Please place your logo SVG in the build directory"
    # Create a placeholder
    touch "$PKG_DIR/etc/calamares/branding/maple/maple-linux-logo-ring-symbolic.svg"
fi

# Create welcome image
if command -v convert &> /dev/null; then
    echo "  Creating welcome screen image"
    convert -size 600x400 gradient:"#8a1622-#c41e3a" \
        -font DejaVu-Sans-Bold -pointsize 42 -fill white \
        -gravity center -annotate +0-50 "Welcome to" \
        -pointsize 52 -annotate +0+10 "Maple Linux Core" \
        -pointsize 20 -fill "#eeeeee" -annotate +0+70 "Let's install your new system" \
        "$PKG_DIR/etc/calamares/branding/maple/welcome.png"
else
    echo "  Warning: ImageMagick not installed, creating placeholder"
    touch "$PKG_DIR/etc/calamares/branding/maple/welcome.png"
fi

# Create postinst - Only configures settings.conf and welcome.conf
# (Does NOT need to create locale.conf or keyboard.conf - we ship those!)
cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e

echo "Configuring Calamares to use Maple branding..."

# Configure Calamares to use Maple branding
if [ -f /etc/calamares/settings.conf ]; then
    # Backup original if not already backed up
    if [ ! -f /etc/calamares/settings.conf.debian-original ]; then
        cp /etc/calamares/settings.conf /etc/calamares/settings.conf.debian-original
        echo "  Backed up original Debian settings"
    fi
    
    # Change branding from debian to maple
    sed -i 's/^branding:.*$/branding: maple/' /etc/calamares/settings.conf
    
    # Fix back button - ensure navigation is set to widget
    if grep -q "^navigation:" /etc/calamares/settings.conf; then
        sed -i 's/^navigation:.*$/navigation: widget/' /etc/calamares/settings.conf
    else
        # Add navigation setting if not present
        echo "navigation: widget" >> /etc/calamares/settings.conf
    fi
    
    # Verify the changes
    if grep -q "^branding: maple" /etc/calamares/settings.conf; then
        echo "  [OK] Calamares configured to use Maple branding"
    else
        echo "  [WARN] Warning: Failed to configure Calamares branding"
    fi
    
    if grep -q "^navigation: widget" /etc/calamares/settings.conf; then
        echo "  [OK] Navigation (back button) configured"
    else
        echo "  [WARN] Warning: Failed to configure navigation"
    fi
else
    echo "  [WARN] Warning: /etc/calamares/settings.conf not found"
fi

# Disable debug button in welcome screen
if [ -f /etc/calamares/modules/welcome.conf ]; then
    # Backup original if not already backed up
    if [ ! -f /etc/calamares/modules/welcome.conf.debian-original ]; then
        cp /etc/calamares/modules/welcome.conf /etc/calamares/modules/welcome.conf.debian-original
        echo "  Backed up original welcome.conf"
    fi
    
    # Add or update debugMode setting
    if grep -q "^debugMode:" /etc/calamares/modules/welcome.conf; then
        sed -i 's/^debugMode:.*$/debugMode: false/' /etc/calamares/modules/welcome.conf
    else
        # Add after the --- line
        sed -i '/^---/a debugMode: false' /etc/calamares/modules/welcome.conf
    fi
    
    echo "  [OK] Debug button disabled"
else
    echo "  [WARN] Warning: /etc/calamares/modules/welcome.conf not found"
fi

echo ""
echo "Maple Calamares branding configured successfully!"
echo ""
echo "Configuration includes:"
echo "  [OK] Maple theme and branding"
echo "  [OK] Timezone: America/Toronto (pre-selected)"
echo "  [OK] Locale: en_CA.UTF-8 (auto-set from timezone)"
echo "  [OK] Keyboard: US layout (pre-selected)"
echo "  [OK] Back button navigation enabled"
echo "  [OK] Debug button disabled"
echo ""

exit 0
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

# Create prerm - restores Debian settings if package is removed
cat > "$PKG_DIR/DEBIAN/prerm" << 'PRERM'
#!/bin/bash
set -e

# Restore Debian configuration when package is removed
if [ "$1" = "remove" ]; then
    if [ -f /etc/calamares/settings.conf.debian-original ]; then
        cp /etc/calamares/settings.conf.debian-original /etc/calamares/settings.conf
        echo "Restored Debian Calamares settings"
    fi
    
    if [ -f /etc/calamares/modules/welcome.conf.debian-original ]; then
        cp /etc/calamares/modules/welcome.conf.debian-original /etc/calamares/modules/welcome.conf
        echo "Restored Debian welcome.conf"
    fi
fi

exit 0
PRERM
chmod 755 "$PKG_DIR/DEBIAN/prerm"

# FIX PERMISSIONS (CRITICAL!)
echo "Setting correct permissions..."
find "$PKG_DIR" -type d -exec chmod 755 {} \;
find "$PKG_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$PKG_DIR/DEBIAN/postinst"  # Scripts must be executable
chmod 755 "$PKG_DIR/DEBIAN/prerm"     # Scripts must be executable

# Build package with fakeroot to ensure root:root ownership
echo "Building package..."
fakeroot dpkg-deb --build "$PKG_DIR"
mv "${PKG_DIR}.deb" "${PKG_NAME}_${PKG_VERSION}_all.deb"
rm -rf "$PKG_DIR"

echo ""
echo "[OK] Created: ${PKG_NAME}_${PKG_VERSION}_all.deb"
echo "[OK] All files owned by root:root with correct permissions"
echo ""
echo "This package provides:"
echo "  - Maple branding files (logo, slideshow, theme)"
echo "  - locale.conf with Toronto timezone defaults"
echo "  - locale.conf with supportedLocales (ensures en_CA.UTF-8 is generated)"
echo "  - keyboard.conf with US layout default"
echo "  - Configures settings.conf to use Maple branding"
echo "  - Disables debug button in welcome screen"
echo ""
echo "Note: locale.conf and keyboard.conf are SHIPPED by this package"
echo "      because calamares-settings-debian does not provide them!"
echo ""
echo "Version 1.6 ensures the installed system uses Canadian English (en_CA.UTF-8)"
echo "even when the live session uses British English (en_GB.UTF-8) for the installer."
