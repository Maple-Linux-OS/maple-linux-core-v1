#!/bin/bash
# Maple Linux Core - Build Configuration
# Contains all build parameters and package definitions

# Maple Linux Information
MAPLE_VERSION="1.0"
MAPLE_CODENAME="Southwold"
MAPLE_FULL_NAME="Maple Linux Core 1.0 (Southwold)"

# Debian Base
DEBIAN_RELEASE="13"  # Trixie

# Output Configuration
OUTPUT_DIR="$(pwd)"
ISO_NAME="maple-linux-core-${MAPLE_VERSION}-amd64.iso"

# Package Filenames
# These are the exact filenames expected in the current directory
CALAMARES_PKG="maple-calamares-branding_1.6-1_all.deb"
CINNAMON_SETTINGS_PKG="maple-cinnamon-settings_2.11-1_all.deb"
LIGHTDM_THEME_PKG="maple-lightdm-userlist_1.7-1_all.deb"
GRUB_BRANDING_PKG="maple-grub-branding_1.1-1_all.deb"

# Note: Plymouth is not used - users will see boot messages instead
# This provides transparency and aligns with minimal modification philosophy

# Build Options
ENABLE_LIBREWOLF=true
ENABLE_CANADIAN_LOCALES=true
ENABLE_ADDITIONAL_APPS=true
ENABLE_LANGUAGE_PACKS=true

# Additional Applications
# Installed during ISO build
ADDITIONAL_APPS=(
    "krita"
    "inkscape"
    "vlc"
    "gnome-firmware"
    "systemd-resolved"
)

# Note: systemd-resolved is installed in the live ISO but masked (disabled)
# It will be enabled on the installed system automatically
# This avoids chroot installation issues during Calamares setup

# Language Packs
# For bilingual support (English CA / French CA)
LANGUAGE_PACKS=(
    "hunspell-en-ca"           # English Canada spell checking
    "hunspell-fr"              # French spell checking
    "thunderbird-l10n-en-ca"   # Thunderbird English Canada
    "thunderbird-l10n-fr"      # Thunderbird French
    "libreoffice-l10n-fr"      # LibreOffice French UI
    "libreoffice-help-fr"      # LibreOffice French help
    "krita-l10n"               # Krita all languages
    "vlc-l10n"                 # VLC all languages
)

# Canadian Locales to Generate
CANADIAN_LOCALES=(
    "en_CA.UTF-8 UTF-8"
    "fr_CA.UTF-8 UTF-8"
)
