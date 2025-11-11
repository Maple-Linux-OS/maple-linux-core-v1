#!/bin/bash
# Build script for maple-cinnamon-settings_2.11-1_all.deb
# v2.11: Removed ImageMagick dependency, uses static wallpaper image
set -e

PKG_NAME="maple-cinnamon-settings"
PKG_VERSION="2.11-1"
PKG_DIR="${PKG_NAME}_${PKG_VERSION}"

echo "Building Maple Cinnamon Settings package v2.11..."
echo ""

# Pre-flight checks
echo "================================================="
echo "PRE-FLIGHT CHECKS"
echo "================================================="

# Check for Maple logo
if [ -f "maple-linux-logo-ring-symbolic.svg" ]; then
    echo "[OK] Maple logo file found: maple-linux-logo-ring-symbolic.svg"
    LOGO_PRESENT=true
else
    echo "[ERROR] Maple logo file NOT found: maple-linux-logo-ring-symbolic.svg"
    echo "  WARNING: Package will be built without custom menu icon!"
    LOGO_PRESENT=false
fi

# Check for wallpaper
if [ -f "maple-cinnamon-wallpaper.png" ]; then
    echo "[OK] Wallpaper file found: maple-cinnamon-wallpaper.png"
    WALLPAPER_PRESENT=true
else
    echo "[ERROR] Wallpaper file NOT found: maple-cinnamon-wallpaper.png"
    echo "  WARNING: Package will be built without custom wallpaper!"
    WALLPAPER_PRESENT=false
fi

echo "================================================="
echo ""

echo "IMPROVEMENTS:"
echo "  * Creates dock configs for instance IDs 0-3 (covers all common cases)"
echo "  * Creates menu configs for instance IDs 0-3"
echo "  * Better live session detection"
echo "  * Improved menu icon installation"
echo "  * v2.11: No ImageMagick dependency - uses static wallpaper"
echo ""

# Clean and create structure
rm -rf "$PKG_DIR"
mkdir -p "$PKG_DIR"/{DEBIAN,usr/share,etc,var/lib}
mkdir -p "$PKG_DIR"/usr/share/{backgrounds/maple,pixmaps,maple}
mkdir -p "$PKG_DIR"/usr/share/glib-2.0/schemas
mkdir -p "$PKG_DIR"/etc/skel/.config/{gtk-3.0,autostart}
mkdir -p "$PKG_DIR"/etc/skel/.config/cinnamon/spices/{grouped-window-list@cinnamon.org,menu@cinnamon.org}
mkdir -p "$PKG_DIR"/etc/dconf/{profile,db/local.d}
mkdir -p "$PKG_DIR"/usr/lib/live/config
mkdir -p "$PKG_DIR"/var/lib/AccountsService/{icons,users}

# Create control file
cat > "$PKG_DIR/DEBIAN/control" << CONTROL
Package: $PKG_NAME
Version: $PKG_VERSION
Section: misc
Priority: optional
Architecture: all
Depends: cinnamon, mint-y-icons, dconf-cli, accountsservice
Recommends: firefox-esr | firefox, gedit
Maintainer: Maple Linux Team <team@maple-linux.org>
Description: Maple Linux Core Cinnamon settings
 Configures Cinnamon desktop with Maple customizations:
 - Custom Maple Linux start menu icon
 - Sets dock to Firefox-ESR, Files, Terminal, Gedit, LibreWolf
 - Show Desktop applet in panel
 - Applies Mint-Y-Sand icons with Adwaita theme
 - Custom Maple wallpaper
 - Maple logo for user icon on lock screen
 - v2.9: Menu shows only Maple logo (no text label)
 - v2.10: Fixed first-login crash (removed enabled-applets)
 - v2.11: Static wallpaper image (no ImageMagick dependency)
CONTROL

# Create postinst script
cat > "$PKG_DIR/DEBIAN/postinst" << 'POSTINST'
#!/bin/bash
set -e

# Function to find Firefox desktop file
find_firefox_desktop() {
    if [ -f /usr/share/applications/firefox-esr.desktop ]; then
        echo "firefox-esr.desktop"
    elif [ -f /usr/share/applications/firefox.desktop ]; then
        echo "firefox.desktop"
    elif [ -f /usr/share/applications/librewolf.desktop ]; then
        echo "librewolf.desktop"
    else
        echo "firefox-esr.desktop"
    fi
}

# Function to setup user icon
setup_user_icon() {
    local username=$1
    local user_home=$2
    
    # Use Maple logo for lock screen
    local icon_path="/usr/share/pixmaps/maple-menu-icon.svg"
    
    if [ -f "$icon_path" ]; then
        # Create AccountsService directories if needed
        mkdir -p /var/lib/AccountsService/icons
        mkdir -p /var/lib/AccountsService/users
        
        # Copy Maple logo
        cp "$icon_path" "/var/lib/AccountsService/icons/${username}"
        
        # Create/update AccountsService user config
        cat > "/var/lib/AccountsService/users/${username}" << EOF
[User]
Icon=/var/lib/AccountsService/icons/${username}
SystemAccount=false
EOF
        chmod 644 "/var/lib/AccountsService/users/${username}"
        
        # Also set in user's home directory
        if [ -d "$user_home" ]; then
            cp "$icon_path" "$user_home/.face"
            cp "$icon_path" "$user_home/.face.icon"
            chown -R ${username}:${username} "$user_home/.face" "$user_home/.face.icon" 2>/dev/null || true
        fi
    fi
}

# Compile GSettings schemas
if [ -x /usr/bin/glib-compile-schemas ]; then
    glib-compile-schemas /usr/share/glib-2.0/schemas || true
fi

# Compile dconf database
if [ -x /usr/bin/dconf ]; then
    dconf update || true
fi

# Apply settings for live user if exists
if [ -d /home/user ] && [ ! -f /home/user/.config/maple-configured ]; then
    echo "Applying Maple settings for live user..."
    
    FIREFOX_DESKTOP=$(find_firefox_desktop)
    echo "Using browser: $FIREFOX_DESKTOP"
    
    # Setup user icon for live user
    setup_user_icon "user" "/home/user"
    
    # Apply theme settings (Adwaita GTK + Mint-Y-Sand icons)
    sudo -u user dbus-launch gsettings set org.cinnamon.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    sudo -u user dbus-launch gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y-Sand' 2>/dev/null || true
    sudo -u user dbus-launch gsettings set org.cinnamon.theme name 'cinnamon' 2>/dev/null || true
    sudo -u user dbus-launch gsettings set org.cinnamon.desktop.wm.preferences theme 'Adwaita' 2>/dev/null || true
    
    # Set menu favorites without Pidgin
    sudo -u user dbus-launch gsettings set org.cinnamon favorite-apps "['${FIREFOX_DESKTOP}', 'thunderbird.desktop', 'rhythmbox.desktop', 'cinnamon-settings.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop']" 2>/dev/null || true
    
    # Add show-desktop to panel
    
    # Set wallpaper
    sudo -u user dbus-launch gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/maple/maple-cinnamon-wallpaper.png' 2>/dev/null || true
    
    # Delete existing applet configs to prevent merge conflicts
    # (Cinnamon merges existing configs with new ones, which can override our settings)
    rm -f /home/user/.config/cinnamon/spices/grouped-window-list@cinnamon.org/*.json 2>/dev/null || true
    rm -f /home/user/.config/cinnamon/spices/menu@cinnamon.org/*.json 2>/dev/null || true
    echo "  Cleared existing applet configs"
    
    # Copy ALL dock configs to live user (0-3)
    mkdir -p /home/user/.config/cinnamon/spices/grouped-window-list@cinnamon.org
    for id in 0 1 2 3; do
        if [ -f /etc/skel/.config/cinnamon/spices/grouped-window-list@cinnamon.org/${id}.json ]; then
            cp /etc/skel/.config/cinnamon/spices/grouped-window-list@cinnamon.org/${id}.json \
               /home/user/.config/cinnamon/spices/grouped-window-list@cinnamon.org/${id}.json 2>/dev/null || true
        fi
    done
    
    # Copy ALL menu icon configs to live user (0-3)
    mkdir -p /home/user/.config/cinnamon/spices/menu@cinnamon.org
    for id in 0 1 2 3; do
        if [ -f /etc/skel/.config/cinnamon/spices/menu@cinnamon.org/${id}.json ]; then
            cp /etc/skel/.config/cinnamon/spices/menu@cinnamon.org/${id}.json \
               /home/user/.config/cinnamon/spices/menu@cinnamon.org/${id}.json 2>/dev/null || true
        fi
    done
    
    chown -R user:user /home/user/.config/cinnamon 2>/dev/null || true
    
    touch /home/user/.config/maple-configured
    
    echo "[OK] Live user configuration complete"
    echo "[OK] Created configs for instance IDs 0-3"
fi

exit 0
POSTINST
chmod 755 "$PKG_DIR/DEBIAN/postinst"

# Copy Maple menu icon SVG
echo ""
echo "Installing menu icon..."
if [ "$LOGO_PRESENT" = true ]; then
    cp "maple-linux-logo-ring-symbolic.svg" \
       "$PKG_DIR/usr/share/pixmaps/maple-menu-icon.svg"
    echo "[OK] Installed: /usr/share/pixmaps/maple-menu-icon.svg"
else
    echo "[ERROR] Skipped: maple-linux-logo-ring-symbolic.svg not found"
    echo "  Default Cinnamon menu icon will be used"
fi
echo ""

# Create menu icon configuration JSON for MULTIPLE instance IDs (0-3)
for MENU_ID in 0 1 2 3; do
    cat > "$PKG_DIR/etc/skel/.config/cinnamon/spices/menu@cinnamon.org/${MENU_ID}.json" << MENU_JSON
{
    "menu-custom": {
        "type": "switch",
        "default": false,
        "description": "Use a custom icon and label",
        "value": true
    },
    "menu-icon": {
        "type": "iconfilechooser",
        "default": "cinnamon-symbolic",
        "description": "Icon",
        "dependency": "menu-custom",
        "value": "/usr/share/pixmaps/maple-menu-icon.svg"
    },
    "menu-label": {
        "type": "entry",
        "default": "Menu",
        "description": "Text",
        "dependency": "menu-custom",
        "value": ""
    },
    "__md5__": "maple-linux-id${MENU_ID}"
}
MENU_JSON
    echo "  Created menu config for instance ID ${MENU_ID}"
done

# Create dock configuration JSON for MULTIPLE instance IDs (0-3)
for DOCK_ID in 0 1 2 3; do
    cat > "$PKG_DIR/etc/skel/.config/cinnamon/spices/grouped-window-list@cinnamon.org/${DOCK_ID}.json" << 'DOCK_JSON'
{
    "pinned-apps": {
        "type": "generic",
        "default": [],
        "value": [
            "firefox-esr.desktop",
            "nemo.desktop",
            "org.gnome.Terminal.desktop",
            "org.gnome.gedit.desktop",
            "librewolf.desktop"
        ]
    },
    "__md5__": "maple-linux-dock"
}
DOCK_JSON
    echo "  Created dock config for instance ID ${DOCK_ID}"
done

# GTK3 settings
cat > "$PKG_DIR/etc/skel/.config/gtk-3.0/settings.ini" << 'GTK3'
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Mint-Y-Sand
gtk-font-name=Ubuntu 11
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintmedium
GTK3

# Create dconf profile
cat > "$PKG_DIR/etc/dconf/profile/user" << 'DCONF_PROFILE'
user-db:user
system-db:local
DCONF_PROFILE

# Create dconf database (Adwaita + Mint-Y-Sand icons)
cat > "$PKG_DIR/etc/dconf/db/local.d/00-maple-defaults" << 'DCONF'
# Maple Linux Core Default Settings

[org/cinnamon/desktop/interface]
gtk-theme='Adwaita'
icon-theme='Mint-Y-Sand'
font-name='Ubuntu 11'

[org/cinnamon/desktop/wm/preferences]
theme='Adwaita'
titlebar-font='Ubuntu Bold 11'

[org/cinnamon/theme]
name='cinnamon'

[org/cinnamon/desktop/background]
picture-uri='file:///usr/share/backgrounds/maple/maple-cinnamon-wallpaper.png'
picture-options='zoom'
primary-color='#cc2233'
secondary-color='#8a1622'
color-shading-type='vertical'

[org/cinnamon]
panels-height=['1:32']
favorite-apps=['firefox-esr.desktop', 'thunderbird.desktop', 'rhythmbox.desktop', 'cinnamon-settings.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop']

[org/nemo/desktop]
show-desktop-icons=true
computer-icon-visible=true
home-icon-visible=true
trash-icon-visible=true
font='Ubuntu 11'
DCONF

# GSettings schema override (Adwaita + Mint-Y-Sand icons)
cat > "$PKG_DIR/usr/share/glib-2.0/schemas/99_maple-settings.gschema.override" << 'GSETTINGS'
# Maple Linux Core Settings Override

[org.cinnamon.desktop.interface]
gtk-theme='Adwaita'
icon-theme='Mint-Y-Sand'

[org.cinnamon.desktop.wm.preferences]
theme='Adwaita'

[org.cinnamon.theme]
name='cinnamon'

[org.cinnamon.desktop.background]
picture-uri='file:///usr/share/backgrounds/maple/maple-cinnamon-wallpaper.png'
picture-options='zoom'
primary-color='#cc2233'
secondary-color='#8a1622'
color-shading-type='vertical'

[org/cinnamon]
panels-height=['1:32']
favorite-apps=['firefox-esr.desktop', 'thunderbird.desktop', 'rhythmbox.desktop', 'cinnamon-settings.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop']
GSETTINGS

# Create autostart script
cat > "$PKG_DIR/etc/skel/.config/autostart/maple-settings.desktop" << 'AUTOSTART'
[Desktop Entry]
Type=Application
Name=Apply Maple Settings
Comment=Apply Maple Linux desktop settings on first login
Exec=/usr/share/maple/apply-settings.sh
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOSTART

# Create apply-settings script (Adwaita + Mint-Y-Sand icons)
cat > "$PKG_DIR/usr/share/maple/apply-settings.sh" << 'APPLY_SCRIPT'
#!/bin/bash
# Apply Maple settings for current user

# Check if already configured
if [ -f ~/.config/maple-configured ]; then
    exit 0
fi

# Function to find Firefox desktop file
find_firefox_desktop() {
    if [ -f /usr/share/applications/firefox-esr.desktop ]; then
        echo "firefox-esr.desktop"
    elif [ -f /usr/share/applications/firefox.desktop ]; then
        echo "firefox.desktop"
    elif [ -f /usr/share/applications/librewolf.desktop ]; then
        echo "librewolf.desktop"
    else
        echo "firefox-esr.desktop"
    fi
}

# Function to setup user icon
setup_user_icon() {
    # Use Maple logo for lock screen
    local icon_path="/usr/share/pixmaps/maple-menu-icon.svg"
    
    if [ -f "$icon_path" ]; then
        cp "$icon_path" ~/.face 2>/dev/null || true
        cp "$icon_path" ~/.face.icon 2>/dev/null || true
    fi
}

FIREFOX_DESKTOP=$(find_firefox_desktop)

# Setup user icon
setup_user_icon

# Apply theme and icons (Adwaita GTK + Mint-Y-Sand icons)
gsettings set org.cinnamon.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
gsettings set org.cinnamon.desktop.interface icon-theme 'Mint-Y-Sand' 2>/dev/null || true
gsettings set org.cinnamon.theme name 'cinnamon' 2>/dev/null || true
gsettings set org.cinnamon.desktop.wm.preferences theme 'Adwaita' 2>/dev/null || true

# Set menu favorites without Pidgin
gsettings set org.cinnamon favorite-apps "['${FIREFOX_DESKTOP}', 'thunderbird.desktop', 'rhythmbox.desktop', 'cinnamon-settings.desktop', 'org.gnome.Terminal.desktop', 'nemo.desktop']" 2>/dev/null || true

# Set wallpaper
gsettings set org.cinnamon.desktop.background picture-uri 'file:///usr/share/backgrounds/maple/maple-cinnamon-wallpaper.png' 2>/dev/null || true

# Dock configuration and menu icon are applied via JSON files in /etc/skel
# (Multiple IDs 0-3 are pre-created to match whatever Cinnamon assigns)

# Mark as configured
touch ~/.config/maple-configured

exit 0
APPLY_SCRIPT
chmod 755 "$PKG_DIR/usr/share/maple/apply-settings.sh"

# Copy wallpaper image
echo ""
echo "Installing wallpaper..."
if [ "$WALLPAPER_PRESENT" = true ]; then
    cp "maple-cinnamon-wallpaper.png" \
        "$PKG_DIR/usr/share/backgrounds/maple/maple-cinnamon-wallpaper.png"
    echo "[OK] Installed: /usr/share/backgrounds/maple/maple-cinnamon-wallpaper.png"
else
    echo "[ERROR] Skipped: maple-cinnamon-wallpaper.png not found"
    echo "  Creating placeholder to prevent errors"
    # Create a minimal placeholder (1x1 transparent PNG)
    printf '\x89\x50\x4e\x47\x0d\x0a\x1a\x0a\x00\x00\x00\x0d\x49\x48\x44\x52\x00\x00\x00\x01\x00\x00\x00\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\x0a\x49\x44\x41\x54\x78\x9c\x63\x00\x01\x00\x00\x05\x00\x01\x0d\x0a\x2d\xb4\x00\x00\x00\x00\x49\x45\x4e\x44\xae\x42\x60\x82' \
        > "$PKG_DIR/usr/share/backgrounds/maple/maple-cinnamon-wallpaper.png"
fi
echo ""

# FIX PERMISSIONS (CRITICAL!)
echo "Setting correct permissions..."
find "$PKG_DIR" -type d -exec chmod 755 {} \;
find "$PKG_DIR" -type f -exec chmod 644 {} \;
chmod 755 "$PKG_DIR/DEBIAN/postinst"  # Scripts must be executable
chmod 755 "$PKG_DIR/usr/share/maple/apply-settings.sh"  # Scripts must be executable

# Build package with fakeroot to ensure root:root ownership
echo "Building package..."
fakeroot dpkg-deb --build "$PKG_DIR"
mv "${PKG_DIR}.deb" "${PKG_NAME}_${PKG_VERSION}_all.deb"
rm -rf "$PKG_DIR"

echo ""
echo "================================================="
echo "[OK] Created: ${PKG_NAME}_${PKG_VERSION}_all.deb"
echo "[OK] All files owned by root:root with correct permissions"
echo "================================================="
echo ""
echo "FEATURES:"
echo "  * Menu icon configs for IDs 0, 1, 2, 3"
echo "  * Dock configs for IDs 0, 1, 2, 3"
echo "  * Covers all common Cinnamon instance ID assignments"
echo "  * v2.11: Static wallpaper (no ImageMagick dependency)"
echo ""
echo "PACKAGE STATUS:"
if [ "$LOGO_PRESENT" = true ]; then
    echo "  [OK] Custom Maple menu icon included"
else
    echo "  [ERROR] Custom Maple menu icon NOT included"
    echo "    -> Place maple-linux-logo-ring-symbolic.svg in this directory and rebuild"
fi

if [ "$WALLPAPER_PRESENT" = true ]; then
    echo "  [OK] Custom Maple wallpaper included"
else
    echo "  [ERROR] Custom Maple wallpaper NOT included"
    echo "    -> Place maple-cinnamon-wallpaper.png in this directory and rebuild"
fi
echo ""
echo "To diagnose issues in live session, run:"
echo "  chmod +x find-cinnamon-ids.sh"
echo "  ./find-cinnamon-ids.sh"
echo ""
