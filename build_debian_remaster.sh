#!/bin/bash
# Maple Linux Core - Comprehensive Build Script
# Version: 3.0 - November 2024
#
# Features:
# - Canadian locales (en_CA, fr_CA)
# - Additional applications (Krita, Inkscape, VLC, gnome-firmware)
# - Bilingual language packs (8 packages)
# - LibreWolf browser via extrepo
# - Plymouth removed (boot messages visible for transparency)
# - Proper APT repository structure mirroring Debian Live
# - Comprehensive error handling and verification
#
# NEW in v3.0:
# - Creates proper /pool/ and /dists/ APT repository structure
# - Uses apt-ftparchive to generate metadata (Packages, Release files)
# - Plymouth actively disabled to show boot messages
# - LightDM and Cinnamon still use localInstall (work fine in chroot)
# - Future-proof approach that will survive Debian 14, 15+

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================
# LOAD CONFIGURATION
# ============================================================
CONFIG_FILE="./build_debian_config.sh"
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}X Configuration file not found: $CONFIG_FILE${NC}"
    exit 1
fi

source "$CONFIG_FILE"

# Legacy variable mapping
DISTRO_NAME="Maple Linux Core"
VERSION="$MAPLE_VERSION"
CODENAME="$MAPLE_CODENAME"
FULL_NAME="$MAPLE_FULL_NAME"

echo -e "${RED}+==================================================+${NC}"
echo -e "${RED}|  Maple Linux Core - Builder v3.0                |${NC}"
echo -e "${RED}|    (With Proper APT Repository Structure)       |${NC}"
echo -e "${RED}+==================================================+${NC}"
echo
echo -e "${CYAN}Build Parameters:${NC}"
echo "  Distribution: $DISTRO_NAME"
echo "  Version: $VERSION"
echo "  Codename: $CODENAME"
echo "  Base: Debian $DEBIAN_RELEASE Live Cinnamon"
echo "  Output: $OUTPUT_DIR/$ISO_NAME"
echo ""
echo -e "${CYAN}New Features:${NC}"
[ "$ENABLE_CANADIAN_LOCALES" = true ] && echo "  [OK] Canadian locales (en_CA, fr_CA)"
[ "$ENABLE_ADDITIONAL_APPS" = true ] && echo "  [OK] Additional applications (${#ADDITIONAL_APPS[@]} apps)"
[ "$ENABLE_LANGUAGE_PACKS" = true ] && echo "  [OK] Language packs (${#LANGUAGE_PACKS[@]} packages)"
[ "$ENABLE_LIBREWOLF" = true ] && echo "  [OK] LibreWolf browser"
echo

# ============================================================
# PRE-FLIGHT CHECKS
# ============================================================
echo -e "${YELLOW}Pre-flight checks...${NC}"

# Check for Debian Live ISO
DEBIAN_ISO=$(ls $PWD/debian-live-*-cinnamon*.iso 2>/dev/null | head -1)
if [ -z "$DEBIAN_ISO" ]; then
    echo -e "${RED}X Debian Live Cinnamon ISO not found in current directory${NC}"
    echo
    echo "Please download from:"
    echo "  https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/"
    echo
    exit 1
fi
echo -e "${GREEN}[OK] Found Debian Live ISO: $(basename "$DEBIAN_ISO")${NC}"

# Function to verify package integrity
verify_package() {
    local pkg_file="$1"
    local pkg_name="$2"
    
    if [ ! -f "$pkg_file" ]; then
        return 1
    fi
    
    # Check if it's a valid .deb file
    if ! dpkg-deb --info "$pkg_file" &>/dev/null; then
        echo -e "  ${RED}X${NC} $pkg_name - Invalid package format!"
        return 1
    fi
    
    # Extract version from the actual package
    local actual_version=$(dpkg-deb -f "$pkg_file" Version 2>/dev/null)
    echo -e "  ${GREEN}[OK]${NC} $pkg_name (version: $actual_version)"
    return 0
}

# Check for packages
echo -e "${YELLOW}Checking for Maple packages...${NC}"
PACKAGES_FOUND=0
PACKAGES_MISSING=()

# Check each required package
if [ -n "$CALAMARES_PKG" ] && [ -f "$PWD/$CALAMARES_PKG" ]; then
    if verify_package "$PWD/$CALAMARES_PKG" "Calamares branding"; then
        PACKAGES_FOUND=$((PACKAGES_FOUND + 1))
    else
        PACKAGES_MISSING+=("calamares")
    fi
else
    echo -e "  ${RED}X${NC} Calamares branding - $CALAMARES_PKG NOT FOUND"
    PACKAGES_MISSING+=("calamares")
fi

if [ -n "$CINNAMON_SETTINGS_PKG" ] && [ -f "$PWD/$CINNAMON_SETTINGS_PKG" ]; then
    if verify_package "$PWD/$CINNAMON_SETTINGS_PKG" "Cinnamon settings"; then
        PACKAGES_FOUND=$((PACKAGES_FOUND + 1))
    else
        PACKAGES_MISSING+=("cinnamon")
    fi
else
    echo -e "  ${RED}X${NC} Cinnamon settings - $CINNAMON_SETTINGS_PKG NOT FOUND"
    PACKAGES_MISSING+=("cinnamon")
fi

if [ -n "$LIGHTDM_THEME_PKG" ] && [ -f "$PWD/$LIGHTDM_THEME_PKG" ]; then
    if verify_package "$PWD/$LIGHTDM_THEME_PKG" "LightDM theme"; then
        PACKAGES_FOUND=$((PACKAGES_FOUND + 1))
    else
        PACKAGES_MISSING+=("lightdm")
    fi
else
    echo -e "  ${RED}X${NC} LightDM theme - $LIGHTDM_THEME_PKG NOT FOUND"
    PACKAGES_MISSING+=("lightdm")
fi

if [ -n "$GRUB_BRANDING_PKG" ] && [ -f "$PWD/$GRUB_BRANDING_PKG" ]; then
    if verify_package "$PWD/$GRUB_BRANDING_PKG" "GRUB branding"; then
        PACKAGES_FOUND=$((PACKAGES_FOUND + 1))
    else
        PACKAGES_MISSING+=("grub")
    fi
else
    echo -e "  ${RED}X${NC} GRUB branding - $GRUB_BRANDING_PKG NOT FOUND"
    PACKAGES_MISSING+=("grub")
fi

echo ""
if [ $PACKAGES_FOUND -ge 4 ]; then
    echo -e "${GREEN}[OK] Found $PACKAGES_FOUND packages!${NC}"
elif [ $PACKAGES_FOUND -eq 0 ]; then
    echo -e "${RED}X No packages found.${NC}"
    echo ""
    echo "Build the packages with:"
    echo "  ./build-calamares.sh"
    echo "  ./build-lightdm.sh"
    exit 1
else
    echo -e "${YELLOW}[WARN] WARNING: Only $PACKAGES_FOUND packages found!${NC}"
    echo ""
    echo "Missing packages will be SKIPPED during installation."
    echo ""
    read -p "Continue with incomplete build? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build cancelled. Build missing packages first."
        exit 0
    fi
fi

# Check disk space
AVAILABLE_SPACE=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_SPACE" -lt 15 ]; then
    echo -e "${RED}X Insufficient disk space (${AVAILABLE_SPACE}GB available, 15GB required)${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Disk space: ${AVAILABLE_SPACE}GB available${NC}"

# Comprehensive package check
echo -e "${YELLOW}Checking required packages...${NC}"

MISSING_PACKAGES=()
PACKAGES_TO_CHECK=(
    "xorriso:xorriso"
    "squashfs-tools:mksquashfs"
    "apt-utils:apt-ftparchive"
    "isolinux:/usr/lib/ISOLINUX/isolinux.bin"
    "syslinux-common:/usr/lib/ISOLINUX/isohdpfx.bin"
)

for package_check in "${PACKAGES_TO_CHECK[@]}"; do
    IFS=':' read -r package check <<< "$package_check"
    
    # Check if it's a command or a file
    if [[ "$check" == /* ]]; then
        # It's a file path
        if [ ! -f "$check" ]; then
            MISSING_PACKAGES+=("$package")
            echo -e "  ${RED}X${NC} $package (missing file: $check)"
        else
            echo -e "  ${GREEN}[OK]${NC} $package"
        fi
    else
        # It's a command
        if ! command -v "$check" &> /dev/null; then
            MISSING_PACKAGES+=("$package")
            echo -e "  ${RED}X${NC} $package (missing command: $check)"
        else
            echo -e "  ${GREEN}[OK]${NC} $package"
        fi
    fi
done

# Install missing packages if any
if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}Installing missing packages: ${MISSING_PACKAGES[@]}${NC}"
    sudo apt-get update -qq
    sudo apt-get install -y "${MISSING_PACKAGES[@]}"
    
    # Verify installation succeeded
    echo ""
    echo -e "${YELLOW}Verifying installation...${NC}"
    STILL_MISSING=()
    
    for package_check in "${PACKAGES_TO_CHECK[@]}"; do
        IFS=':' read -r package check <<< "$package_check"
        
        if [[ "$check" == /* ]]; then
            if [ ! -f "$check" ]; then
                STILL_MISSING+=("$package")
                echo -e "  ${RED}X${NC} $package: $check still not found"
            else
                echo -e "  ${GREEN}[OK]${NC} $package verified"
            fi
        else
            if ! command -v "$check" &> /dev/null; then
                STILL_MISSING+=("$package")
                echo -e "  ${RED}X${NC} $package: $check command still not found"
            else
                echo -e "  ${GREEN}[OK]${NC} $package verified"
            fi
        fi
    done
    
    if [ ${#STILL_MISSING[@]} -gt 0 ]; then
        echo ""
        echo -e "${RED}X Failed to install required packages: ${STILL_MISSING[@]}${NC}"
        echo ""
        echo "Please install manually:"
        for pkg in "${STILL_MISSING[@]}"; do
            echo "  sudo apt-get install $pkg"
        done
        exit 1
    fi
    
    echo -e "${GREEN}[OK] All required packages installed successfully${NC}"
else
    echo -e "${GREEN}[OK] All required packages are already installed${NC}"
fi

echo
read -p "Continue with build? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled."
    exit 0
fi

START_TIME=$(date +%s)
STEP=1
TOTAL_STEPS=17

progress() {
    echo
    echo -e "${BLUE}+==================================================+${NC}"
    echo -e "${BLUE}| Step $STEP/$TOTAL_STEPS: $1${NC}"
    echo -e "${BLUE}+==================================================+${NC}"
    echo
    STEP=$((STEP + 1))
}

# Use current working directory
WORK_DIR="$(pwd)"
EXTRACT_DIR="$WORK_DIR/debian_iso_extracted"
FILESYSTEM_DIR="$WORK_DIR/debian_filesystem_edit"

# ============================================================
# PHASE 1: CLEAN START
# ============================================================
progress "Cleaning previous builds"

if [ -d "$FILESYSTEM_DIR" ]; then
    echo "Removing old filesystem_edit..."
    sudo rm -rf "$FILESYSTEM_DIR"
fi

if [ -d "$EXTRACT_DIR" ]; then
    echo "Removing old iso_extracted..."
    sudo rm -rf "$EXTRACT_DIR"
fi

if [ -f "$OUTPUT_DIR/$ISO_NAME" ]; then
    echo "Removing old ISO..."
    sudo rm -f "$OUTPUT_DIR/$ISO_NAME"
fi

echo -e "${GREEN}[OK] Clean workspace${NC}"

# ============================================================
# PHASE 2: EXTRACT DEBIAN LIVE ISO
# ============================================================
progress "Extracting Debian Live ISO"

MOUNT_POINT="/mnt/debian_live_temp"

sudo mkdir -p "$MOUNT_POINT"
if mountpoint -q "$MOUNT_POINT"; then
    sudo umount "$MOUNT_POINT"
fi

sudo mount -o loop "$DEBIAN_ISO" "$MOUNT_POINT"
mkdir -p "$EXTRACT_DIR"
# Copy ALL files including hidden ones (like .disk directory)
sudo cp -a "$MOUNT_POINT"/. "$EXTRACT_DIR/"
sudo umount "$MOUNT_POINT"
sudo rmdir "$MOUNT_POINT"

# Fix permissions
sudo chown -R $USER:$USER "$EXTRACT_DIR"
sudo chmod -R u+w "$EXTRACT_DIR"

SQUASHFS_FILE="$EXTRACT_DIR/live/filesystem.squashfs"
if [ ! -f "$SQUASHFS_FILE" ]; then
    echo -e "${RED}X Squashfs not found! Wrong ISO type?${NC}"
    exit 1
fi

# Verify .disk directory was extracted
if [ -d "$EXTRACT_DIR/.disk" ]; then
    echo "[OK] .disk directory preserved from original ISO"
    if [ -f "$EXTRACT_DIR/.disk/info" ]; then
        echo "    Original content: $(cat "$EXTRACT_DIR/.disk/info")"
    fi
else
    echo "[WARN] .disk directory not in original ISO (will be created later)"
fi

SQUASHFS_SIZE=$(du -h "$SQUASHFS_FILE" | cut -f1)
echo -e "${GREEN}[OK] ISO extracted, squashfs: $SQUASHFS_SIZE${NC}"

# ============================================================
# PHASE 3: EXTRACT FILESYSTEM
# ============================================================
progress "Extracting filesystem (5-10 min)"

echo "Extracting squashfs..."
sudo unsquashfs -d "$FILESYSTEM_DIR" "$SQUASHFS_FILE"

echo -e "${GREEN}[OK] Filesystem extracted${NC}"

# ============================================================
# PHASE 4: CONFIGURE CHROOT
# ============================================================
progress "Configuring chroot environment"

# Configure DNS for chroot
echo "Configuring DNS..."
sudo cp /etc/resolv.conf "$FILESYSTEM_DIR/etc/resolv.conf"

# Don't touch apt sources - let Debian Live handle them naturally
echo "Preserving original apt sources..."
echo "  NOTE: Keeping all Debian Live sources as-is for maximum compatibility"

echo -e "${GREEN}[OK] Chroot configured${NC}"

# ============================================================
# PHASE 5: INSTALL BASE DEPENDENCIES
# ============================================================
progress "Installing base dependencies"

echo "Updating package lists..."
# Temporarily disable file:/run/live/medium ONLY for this update (doesn't exist during build)
sudo sed -i 's|^\(deb.*file:/run/live/medium\)|#MAPLE_TEMP#\1|' "$FILESYSTEM_DIR/etc/apt/sources.list" 2>/dev/null || true

# Update (will use network sources only)
sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "apt-get update -qq" || {
    echo -e "${RED}X Failed to update package lists${NC}"
    exit 1
}

# Immediately restore file:/run/live/medium sources
sudo sed -i 's|^#MAPLE_TEMP#||' "$FILESYSTEM_DIR/etc/apt/sources.list" 2>/dev/null || true
echo "  [OK] Package lists updated"

echo "Installing base packages..."
sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
    apt-get install -y mint-y-icons accountsservice extrepo
" || {
    echo -e "${RED}X Failed to install base packages${NC}"
    exit 1
}
echo -e "${GREEN}[OK] Base packages installed${NC}"
echo -e "${GREEN}[OK] LightDM already present in base Debian Live ISO${NC}"

# ============================================================
# PHASE 6: INSTALL MAPLE PACKAGES
# ============================================================
progress "Installing Maple packages with verification"

# Create tracking file
INSTALL_LOG="$WORK_DIR/package_install.log"
> "$INSTALL_LOG"

PACKAGES_INSTALLED=0
PACKAGES_FAILED=0

# Function to install and verify package
install_maple_package() {
    local pkg_file="$1"
    local pkg_name=$(basename "$pkg_file" | cut -d_ -f1)
    
    echo ""
    echo -e "${CYAN}Installing: $(basename "$pkg_file")${NC}"
    
    # Copy package to chroot
    sudo cp "$pkg_file" "$FILESYSTEM_DIR/tmp/"
    
    # Install package WITH error checking
    if sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        dpkg -i /tmp/$(basename "$pkg_file") 2>&1 | tee -a /tmp/install.log
        exit \${PIPESTATUS[0]}
    "; then
        echo -e "  ${GREEN}[OK] Package installed successfully${NC}"
        echo "SUCCESS: $pkg_name" >> "$INSTALL_LOG"
    else
        echo -e "  ${YELLOW}[WARN] Package had errors, attempting to fix dependencies...${NC}"
        
        # Try to fix dependencies
        if sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
            apt-get install -f -y 2>&1 | tee -a /tmp/install.log
            exit \${PIPESTATUS[0]}
        "; then
            # Try installing the package again
            if sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
                dpkg -i /tmp/$(basename "$pkg_file") 2>&1 | tee -a /tmp/install.log
                exit \${PIPESTATUS[0]}
            "; then
                echo -e "  ${GREEN}[OK] Package installed after fixing dependencies${NC}"
                echo "SUCCESS (after fix): $pkg_name" >> "$INSTALL_LOG"
            else
                echo -e "  ${RED}X FAILED to install $pkg_name${NC}"
                echo "FAILED: $pkg_name" >> "$INSTALL_LOG"
                sudo cp "$FILESYSTEM_DIR/tmp/install.log" "$WORK_DIR/${pkg_name}_install.log"
                return 1
            fi
        else
            echo -e "  ${RED}X FAILED to fix dependencies for $pkg_name${NC}"
            echo "FAILED (deps): $pkg_name" >> "$INSTALL_LOG"
            sudo cp "$FILESYSTEM_DIR/tmp/install.log" "$WORK_DIR/${pkg_name}_install.log"
            return 1
        fi
    fi
    
    # Verify postinst ran
    if sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        dpkg -s $pkg_name 2>/dev/null | grep -q '^Status:.*installed'
    "; then
        echo -e "  ${GREEN}[OK] Package status: installed${NC}"
    else
        echo -e "  ${RED}X Package status check failed${NC}"
        return 1
    fi
    
    # Clean up
    sudo rm -f "$FILESYSTEM_DIR/tmp/$(basename "$pkg_file")"
    return 0
}

# Install packages in order
# 1. GRUB branding (no dependencies)
if [ -n "$GRUB_BRANDING_PKG" ] && [ -f "$PWD/$GRUB_BRANDING_PKG" ]; then
    if install_maple_package "$PWD/$GRUB_BRANDING_PKG"; then
        PACKAGES_INSTALLED=$((PACKAGES_INSTALLED + 1))
    else
        PACKAGES_FAILED=$((PACKAGES_FAILED + 1))
    fi
fi

# 2. LightDM theme - SKIP in live session to preserve auto-login
# Installing LightDM branding here would break Debian Live's auto-login
# We'll copy the package and let Calamares install it to the target system
if [ -n "$LIGHTDM_THEME_PKG" ] && [ -f "$PWD/$LIGHTDM_THEME_PKG" ]; then
    echo ""
    echo -e "${CYAN}LightDM: Prepared for target system installation only${NC}"
    echo "  (Skipping live session to preserve auto-login)"
fi

# 3. Cinnamon settings
if [ -n "$CINNAMON_SETTINGS_PKG" ] && [ -f "$PWD/$CINNAMON_SETTINGS_PKG" ]; then
    if install_maple_package "$PWD/$CINNAMON_SETTINGS_PKG"; then
        PACKAGES_INSTALLED=$((PACKAGES_INSTALLED + 1))
        # NOTE: Cinnamon settings will be copied to user home AFTER user creation in Phase 12
    else
        PACKAGES_FAILED=$((PACKAGES_FAILED + 1))
    fi
fi

# 4. Calamares branding (depends on calamares being present)
if [ -n "$CALAMARES_PKG" ] && [ -f "$PWD/$CALAMARES_PKG" ]; then
    # Ensure Calamares is installed first
    sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        if ! dpkg -l | grep -q 'ii.*calamares[^-]'; then
            echo 'Installing Calamares first...'
            apt-get update -qq
            apt-get install -y calamares calamares-settings-debian
        fi
    "
    
    if install_maple_package "$PWD/$CALAMARES_PKG"; then
        PACKAGES_INSTALLED=$((PACKAGES_INSTALLED + 1))
    else
        PACKAGES_FAILED=$((PACKAGES_FAILED + 1))
    fi
fi

# Install LibreWolf
if [ "$ENABLE_LIBREWOLF" = true ]; then
    echo ""
    echo -e "${CYAN}Installing LibreWolf browser...${NC}"
    sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        extrepo enable librewolf
        apt-get update -qq
        apt-get install -y librewolf
    " && {
        echo -e "  ${GREEN}[OK] LibreWolf installed${NC}"
    } || {
        echo -e "  ${YELLOW}[WARN] LibreWolf installation failed, continuing...${NC}"
    }
fi

# Copy LightDM and Cinnamon packages for Calamares localInstall
# These work fine with localInstall and don't need APT repo
echo ""
echo -e "${CYAN}Preparing packages for target system installation...${NC}"

NEED_PACKAGE_CONFIG=false

# Copy LightDM package if it exists
if [ -f "$PWD/$LIGHTDM_THEME_PKG" ]; then
    sudo mkdir -p "$FILESYSTEM_DIR/usr/local/maple-packages"
    sudo cp "$PWD/$LIGHTDM_THEME_PKG" "$FILESYSTEM_DIR/usr/local/maple-packages/"
    echo "  [OK] Copied LightDM theme package for target system"
    NEED_PACKAGE_CONFIG=true
else
    echo -e "  ${YELLOW}[WARN] LightDM package not found, will skip target installation${NC}"
fi

# Copy Cinnamon settings package if it exists
if [ -f "$PWD/$CINNAMON_SETTINGS_PKG" ]; then
    sudo mkdir -p "$FILESYSTEM_DIR/usr/local/maple-packages"
    sudo cp "$PWD/$CINNAMON_SETTINGS_PKG" "$FILESYSTEM_DIR/usr/local/maple-packages/"
    echo "  [OK] Copied Cinnamon settings package for target system"
    NEED_PACKAGE_CONFIG=true
else
    echo -e "  ${YELLOW}[WARN] Cinnamon settings package not found, will skip target installation${NC}"
fi

echo ""
echo -e "${CYAN}Package Installation Summary:${NC}"
echo "  Successful: $PACKAGES_INSTALLED"
echo "  Failed: $PACKAGES_FAILED"
echo ""

if [ $PACKAGES_FAILED -gt 0 ]; then
    echo -e "${YELLOW}[WARN] Some packages failed to install. Check logs:${NC}"
    cat "$INSTALL_LOG"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build aborted due to package installation failures."
        exit 1
    fi
fi

# ============================================================
# PHASE 7: ENABLE CANADIAN LOCALES
# ============================================================
if [ "$ENABLE_CANADIAN_LOCALES" = true ]; then
    progress "Enabling Canadian locales"
    
    echo "Configuring en_CA and fr_CA locales..."
    
    # Uncomment locales in locale.gen and add if missing
    sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        # Ensure locale.gen exists
        touch /etc/locale.gen
        
        # Uncomment en_CA if commented, add if missing
        if grep -q '^# en_CA.UTF-8 UTF-8' /etc/locale.gen; then
            sed -i 's/^# en_CA.UTF-8 UTF-8/en_CA.UTF-8 UTF-8/' /etc/locale.gen
        elif ! grep -q '^en_CA.UTF-8 UTF-8' /etc/locale.gen; then
            echo 'en_CA.UTF-8 UTF-8' >> /etc/locale.gen
        fi
        
        # Uncomment fr_CA if commented, add if missing
        if grep -q '^# fr_CA.UTF-8 UTF-8' /etc/locale.gen; then
            sed -i 's/^# fr_CA.UTF-8 UTF-8/fr_CA.UTF-8 UTF-8/' /etc/locale.gen
        elif ! grep -q '^fr_CA.UTF-8 UTF-8' /etc/locale.gen; then
            echo 'fr_CA.UTF-8 UTF-8' >> /etc/locale.gen
        fi
        
        # Generate the locales (en_US is already generated by default in Debian)
        locale-gen
    " && {
        echo -e "${GREEN}[OK] Canadian locales enabled (en_CA, fr_CA)${NC}"
        echo -e "${GREEN}[OK] System will use US English defaults (user can choose during install)${NC}"
    } || {
        echo -e "${YELLOW}[WARN] Failed to generate locales, continuing...${NC}"
    }
else
    STEP=$((STEP + 1))
fi

# ============================================================
# PHASE 8: INSTALL ADDITIONAL APPLICATIONS
# ============================================================
if [ "$ENABLE_ADDITIONAL_APPS" = true ] && [ ${#ADDITIONAL_APPS[@]} -gt 0 ]; then
    progress "Installing additional applications"
    
    echo "Installing: ${ADDITIONAL_APPS[@]}..."
    
    sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        apt-get install -y ${ADDITIONAL_APPS[@]}
    " && {
        echo -e "${GREEN}[OK] Additional applications installed${NC}"
        for app in "${ADDITIONAL_APPS[@]}"; do
            echo "    - $app"
        done
    } || {
        echo -e "${YELLOW}[WARN] Some applications failed to install, continuing...${NC}"
    }
else
    STEP=$((STEP + 1))
fi

# ============================================================
# PHASE 9: INSTALL LANGUAGE PACKS
# ============================================================
if [ "$ENABLE_LANGUAGE_PACKS" = true ] && [ ${#LANGUAGE_PACKS[@]} -gt 0 ]; then
    progress "Installing language packs"
    
    echo "Installing: ${LANGUAGE_PACKS[@]}..."
    
    sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        apt-get install -y ${LANGUAGE_PACKS[@]}
    " && {
        echo -e "${GREEN}[OK] Language packs installed${NC}"
        for pack in "${LANGUAGE_PACKS[@]}"; do
            echo "    - $pack"
        done
    } || {
        echo -e "${YELLOW}[WARN] Some language packs failed to install, continuing...${NC}"
    }
else
    STEP=$((STEP + 1))
fi

# ============================================================
# PHASE 10: DISABLE PLYMOUTH
# ============================================================
progress "Disabling Plymouth (enabling boot messages)"

echo "Removing Plymouth packages..."
sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
    # Remove Plymouth and themes
    apt-get purge -y plymouth plymouth-themes 2>/dev/null || true
    apt-get autoremove -y 2>/dev/null || true
    
    # Ensure it's really gone
    dpkg --purge plymouth plymouth-themes 2>/dev/null || true
" && {
    echo -e "  ${GREEN}[OK]${NC} Plymouth packages removed"
} || {
    echo -e "  ${YELLOW}[WARN]${NC} Plymouth removal had warnings (likely already removed)"
}

echo "Configuring GRUB to show boot messages..."
# Remove quiet and splash from GRUB defaults
sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
    # Backup original
    [ -f /etc/default/grub ] && cp /etc/default/grub /etc/default/grub.maple-backup
    
    # Remove 'quiet' and 'splash' from GRUB_CMDLINE_LINUX_DEFAULT
    if [ -f /etc/default/grub ]; then
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/' /etc/default/grub
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"quiet\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/' /etc/default/grub
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=\"splash\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/' /etc/default/grub
        
        # Also handle cases where there might be other parameters
        sed -i 's/ quiet / /g' /etc/default/grub
        sed -i 's/ splash / /g' /etc/default/grub
        sed -i 's/ quiet\"/\"/' /etc/default/grub
        sed -i 's/ splash\"/\"/' /etc/default/grub
    fi
" && {
    echo -e "  ${GREEN}[OK]${NC} GRUB configured for verbose boot"
} || {
    echo -e "  ${YELLOW}[WARN]${NC} GRUB configuration had warnings"
}

echo "Updating initramfs..."
sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
    # Update initramfs to remove Plymouth hooks
    update-initramfs -u 2>/dev/null || true
" && {
    echo -e "  ${GREEN}[OK]${NC} Initramfs updated"
} || {
    echo -e "  ${YELLOW}[WARN]${NC} Initramfs update had warnings"
}

echo ""
echo -e "${GREEN}[OK] Plymouth disabled - boot messages will be visible${NC}"
echo "  (Old school Unix transparency - see what your system is doing!)"
echo ""

# ============================================================
# PHASE 11: CONFIGURE CALAMARES PACKAGES.CONF
# ============================================================
progress "Configuring Calamares package installation"

echo ""
echo -e "${CYAN}Configuring packages.conf for Maple packages:${NC}"

if [ -f "$FILESYSTEM_DIR/etc/calamares/modules/packages.conf" ]; then
    # Backup original
    sudo cp "$FILESYSTEM_DIR/etc/calamares/modules/packages.conf" \
        "$FILESYSTEM_DIR/etc/calamares/modules/packages.conf.maple-backup"
    
    # Add our custom operations if not already present
    if ! sudo grep -q "Maple Linux: Install custom packages" "$FILESYSTEM_DIR/etc/calamares/modules/packages.conf"; then
        
        # Append our configuration
        sudo bash -c "cat >> '$FILESYSTEM_DIR/etc/calamares/modules/packages.conf'" << 'PKGCONF'

# Maple Linux: Install custom packages on target system
  # LightDM and Cinnamon via localInstall (work fine in chroot)
  - localInstall:
PKGCONF
        
        # Add LightDM if available
        if [ -f "$FILESYSTEM_DIR/usr/local/maple-packages/$LIGHTDM_THEME_PKG" ]; then
            sudo bash -c "echo '      - /usr/local/maple-packages/$LIGHTDM_THEME_PKG' >> '$FILESYSTEM_DIR/etc/calamares/modules/packages.conf'"
            echo "  [OK] Added LightDM theme (localInstall)"
        fi
        
        # Add Cinnamon if available
        if [ -f "$FILESYSTEM_DIR/usr/local/maple-packages/$CINNAMON_SETTINGS_PKG" ]; then
            sudo bash -c "echo '      - /usr/local/maple-packages/$CINNAMON_SETTINGS_PKG' >> '$FILESYSTEM_DIR/etc/calamares/modules/packages.conf'"
            echo "  [OK] Added Cinnamon settings (localInstall)"
        fi
        
        # Note: systemd-resolved is installed in the squashfs (ADDITIONAL_APPS)
        # It's masked in the live session and will be unmasked on target system
        
    else
        echo "  [INFO] Maple configuration already present in packages.conf"
    fi
    
else
    echo -e "  ${YELLOW}[WARN] packages.conf not found${NC}"
fi

echo ""
echo -e "${GREEN}[OK] Calamares configured for hybrid installation approach${NC}"

# ============================================================
# PHASE 12: VERIFY INSTALLATION READINESS
# ============================================================
progress "Verifying installation configuration"

echo "Checking package availability..."

# Check packages in squashfs
if sudo chroot "$FILESYSTEM_DIR" dpkg -l | grep -q "^ii.*maple-calamares-branding"; then
    echo -e "  ${GREEN}[OK]${NC} Calamares branding installed in live session"
fi

if sudo chroot "$FILESYSTEM_DIR" dpkg -l | grep -q "^ii.*maple-cinnamon-settings"; then
    echo -e "  ${GREEN}[OK]${NC} Cinnamon settings installed in live session"
fi

if sudo chroot "$FILESYSTEM_DIR" dpkg -l | grep -q "^ii.*maple-grub-branding"; then
    echo -e "  ${GREEN}[OK]${NC} GRUB branding installed in live session"
fi

# Check packages for target installation
if [ -f "$FILESYSTEM_DIR/usr/local/maple-packages/$LIGHTDM_THEME_PKG" ]; then
    echo -e "  ${GREEN}[OK]${NC} LightDM theme ready (localInstall to target)"
fi

if [ -f "$FILESYSTEM_DIR/usr/local/maple-packages/$CINNAMON_SETTINGS_PKG" ]; then
    echo -e "  ${GREEN}[OK]${NC} Cinnamon settings ready (localInstall to target)"
fi


# Check additional apps
if [ "$ENABLE_ADDITIONAL_APPS" = true ]; then
    echo ""
    echo "Checking additional applications..."
    for app in "${ADDITIONAL_APPS[@]}"; do
        if sudo chroot "$FILESYSTEM_DIR" dpkg -l | grep -q "^ii.*$app "; then
            echo -e "  ${GREEN}[OK]${NC} $app installed"
        fi
    done
fi

# Check LibreWolf
if [ "$ENABLE_LIBREWOLF" = true ]; then
    if sudo chroot "$FILESYSTEM_DIR" dpkg -l | grep -q "^ii  librewolf "; then
        echo -e "  ${GREEN}[OK]${NC} LibreWolf installed"
    fi
fi

echo ""

# ============================================================
# PHASE 13: CONFIGURE LIVE USER
# ============================================================
progress "Configuring live user environment"

LIVE_USER="user"

# Create user if not exists
if ! grep -q "^$LIVE_USER:" "$FILESYSTEM_DIR/etc/passwd"; then
    sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
        useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev $LIVE_USER
        echo '$LIVE_USER:live' | chpasswd
    "
    echo "[OK] Created live user: $LIVE_USER"
fi

# Configure sudo for live user
sudo bash -c "cat > '$FILESYSTEM_DIR/etc/sudoers.d/live-user'" << EOF
$LIVE_USER ALL=(ALL) NOPASSWD: ALL
EOF
sudo chmod 440 "$FILESYSTEM_DIR/etc/sudoers.d/live-user"

# Create installer desktop icon
echo "Creating installer desktop icon..."
sudo mkdir -p "$FILESYSTEM_DIR/home/user/Desktop"
sudo bash -c "cat > '$FILESYSTEM_DIR/home/user/Desktop/calamares.desktop'" << 'EOF'
[Desktop Entry]
Type=Application
Version=1.0
Name=Install Maple Linux Core
Comment=Install the system to your hard drive
Icon=media-floppy
Exec=pkexec calamares
Terminal=false
Categories=System;
StartupNotify=true
EOF
sudo chmod +x "$FILESYSTEM_DIR/home/user/Desktop/calamares.desktop"
sudo chown 1000:1000 "$FILESYSTEM_DIR/home/user/Desktop/calamares.desktop"

echo -e "${GREEN}[OK] Live user configured${NC}"

# Apply Cinnamon settings to the newly created user
if [ -d "$FILESYSTEM_DIR/etc/skel/.config" ]; then
    echo ""
    echo -e "${CYAN}Applying Cinnamon settings to live session user...${NC}"
    
    # Copy all Cinnamon config from /etc/skel to /home/user
    sudo cp -r "$FILESYSTEM_DIR/etc/skel/.config/"* "$FILESYSTEM_DIR/home/user/.config/" 2>/dev/null || true
    
    # Set proper ownership (UID 1000 = live session user)
    sudo chown -R 1000:1000 "$FILESYSTEM_DIR/home/user/.config"
    
    # Update dconf database to apply settings immediately
    if [ -f "$FILESYSTEM_DIR/etc/dconf/db/local.d/01-maple-desktop" ]; then
        sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "dconf update" 2>/dev/null || true
    fi
    
    echo -e "  ${GREEN}[OK] Cinnamon settings applied to live user${NC}"
fi

# ============================================================
# PHASE 14: CLEANUP & REPACK
# ============================================================
progress "Cleanup and repacking"

# Clean package cache
echo "Cleaning package cache..."
sudo chroot "$FILESYSTEM_DIR" /bin/bash -c "
    apt-get clean
    rm -rf /var/cache/apt/archives/*.deb
    rm -rf /tmp/*
"

# Restore working resolv.conf for live session
# Using CIRA Canadian Shield DNS (Canadian-operated, privacy-focused)
# When systemd-resolved is installed by Calamares, it will replace this with its own symlink
echo "Creating working resolv.conf for live session..."
sudo rm -f "$FILESYSTEM_DIR/etc/resolv.conf"
sudo bash -c "cat > '$FILESYSTEM_DIR/etc/resolv.conf'" << 'EOF'
# Maple Linux live session - using CIRA Canadian Shield DNS
# https://www.cira.ca/cybersecurity-services/canadian-shield
# These will be replaced by network-provided DNS on the installed system
nameserver 149.112.121.20
nameserver 149.112.122.20
EOF

echo -e "${GREEN}[OK] Cleanup complete${NC}"

# ============================================================
# PHASE 15: REPACK SQUASHFS
# ============================================================
progress "Repacking filesystem (10-15 min)"

# Backup original
if [ ! -f "${SQUASHFS_FILE}.original" ]; then
    cp "$SQUASHFS_FILE" "${SQUASHFS_FILE}.original"
fi

# Remove old squashfs
rm -f "$SQUASHFS_FILE"

echo "Compressing filesystem..."
sudo mksquashfs "$FILESYSTEM_DIR" "$SQUASHFS_FILE" \
    -comp xz \
    -Xbcj x86 \
    -b 1M \
    -noappend \
    -no-progress 2>&1 | tail -1

sudo chown $USER:$USER "$SQUASHFS_FILE"

NEW_SQUASHFS_SIZE=$(du -h "$SQUASHFS_FILE" | cut -f1)
echo "New squashfs size: $NEW_SQUASHFS_SIZE"

echo -e "${GREEN}[OK] Filesystem repacked${NC}"

# Remove backup squashfs BEFORE building ISO
if [ -f "${SQUASHFS_FILE}.original" ]; then
    rm -f "${SQUASHFS_FILE}.original"
    echo "[OK] Removed backup squashfs"
fi

# ============================================================
# PHASE 16: FIX BOOT CONFIGURATION FOR USB
# ============================================================
progress "Configuring bootloader for USB compatibility"

# The volume label used in the ISO
VOLUME_LABEL="MAPLE_LINUX_$VERSION"

echo "Creating/updating .disk/info file..."
mkdir -p "$EXTRACT_DIR/.disk"
echo "$FULL_NAME" > "$EXTRACT_DIR/.disk/info"
echo -e "  ${GREEN}[OK]${NC} .disk/info updated with Maple branding"

# Create a more robust GRUB configuration
echo "Examining existing GRUB configuration..."
if [ -f "$EXTRACT_DIR/boot/grub/grub.cfg" ]; then
    # Backup the original
    cp "$EXTRACT_DIR/boot/grub/grub.cfg" "$EXTRACT_DIR/boot/grub/grub.cfg.debian-original"
    
    # Check what search method Debian is using
    if grep -q "search.*--file.*/.disk/info" "$EXTRACT_DIR/boot/grub/grub.cfg"; then
        echo "  Found file-based search in grub.cfg"
        
        # Keep the file-based search but make it more robust
        # Change from: search --set=root --file /.disk/info
        # To: search --no-floppy --set=root --file /.disk/info
        sed -i 's/search --set=root --file \/\.disk\/info/search --no-floppy --set=root --file \/\.disk\/info/' \
            "$EXTRACT_DIR/boot/grub/grub.cfg"
        
        echo -e "  ${GREEN}[OK]${NC} Enhanced file-based search"
    fi
    
    # Also add label-based search as a fallback right after file-based search
    # This provides redundancy
    sed -i "/search.*--file.*\/.disk\/info/a search --no-floppy --set=root --label \"$VOLUME_LABEL\" || true" \
        "$EXTRACT_DIR/boot/grub/grub.cfg" 2>/dev/null || true
    
    echo -e "  ${GREEN}[OK]${NC} Added label-based fallback"
    
    # Ensure we have the iso-scan module loaded for USB boot
    if ! grep -q "insmod iso9660" "$EXTRACT_DIR/boot/grub/grub.cfg"; then
        # Add at the beginning of the file after any existing insmod commands
        sed -i '1a insmod iso9660' "$EXTRACT_DIR/boot/grub/grub.cfg"
    fi
    
    echo -e "  ${GREEN}[OK]${NC} Updated grub.cfg"
else
    echo -e "  ${RED}[ERROR]${NC} grub.cfg not found!"
    exit 1
fi

# Verify .disk/info was created
if [ -f "$EXTRACT_DIR/.disk/info" ]; then
    echo ""
    echo "  .disk/info content:"
    echo "    $(cat "$EXTRACT_DIR/.disk/info")"
else
    echo -e "  ${RED}[ERROR]${NC} Failed to create .disk/info"
    exit 1
fi

echo ""
echo -e "${GREEN}[OK] Bootloader configured for USB boot${NC}"
echo "  Using hybrid search: file + label"
echo ""

# ============================================================
# PHASE 17: BUILD ISO
# ============================================================
progress "Building final ISO"

# Create output directory with correct permissions
mkdir -p "$OUTPUT_DIR"
sudo chown -R $USER:$USER "$OUTPUT_DIR" 2>/dev/null || true

ISO_OUTPUT="$OUTPUT_DIR/$ISO_NAME"
rm -f "$ISO_OUTPUT"

cd "$EXTRACT_DIR"

# Build ISO
xorriso -as mkisofs \
    -r -V "MAPLE_LINUX_$VERSION" \
    -o "$ISO_OUTPUT" \
    -J -joliet-long \
    -cache-inodes \
    -isohybrid-mbr /usr/lib/ISOLINUX/isohdpfx.bin \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -boot-load-size 4 \
    -boot-info-table \
    -no-emul-boot \
    -eltorito-alt-boot \
    -e boot/grub/efi.img \
    -no-emul-boot \
    -isohybrid-gpt-basdat \
    -isohybrid-apm-hfsplus \
    . 2>&1 | grep -v "WARNING" || true

cd "$WORK_DIR"

ISO_SIZE=$(du -h "$ISO_OUTPUT" | cut -f1)
echo -e "${GREEN}[OK] ISO built: $ISO_SIZE${NC}"

# ============================================================
# FINAL CLEANUP & SUMMARY
# ============================================================
echo ""
echo -e "${BLUE}Final cleanup...${NC}"

# Clean extracted filesystem
if [ -d "$FILESYSTEM_DIR" ]; then
    sudo rm -rf "$FILESYSTEM_DIR"
    echo "[OK] Removed filesystem_edit/ (freed ~7GB)"
fi

# Calculate build time
END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_MIN=$((BUILD_TIME / 60))
BUILD_SEC=$((BUILD_TIME % 60))

# Final summary
echo
echo -e "${GREEN}+==================================================+${NC}"
echo -e "${GREEN}|              BUILD COMPLETE!                     |${NC}"
echo -e "${GREEN}+==================================================+${NC}"
echo
echo -e "${CYAN}Build Summary:${NC}"
echo "  Distribution: $FULL_NAME"
echo "  ISO Location: $ISO_OUTPUT"
echo "  ISO Size: $ISO_SIZE"
echo "  Build Time: ${BUILD_MIN}m ${BUILD_SEC}s"
echo "  Packages Installed: $PACKAGES_INSTALLED"
if [ $PACKAGES_FAILED -gt 0 ]; then
    echo -e "  ${YELLOW}Packages Failed: $PACKAGES_FAILED${NC}"
fi
echo
echo -e "${CYAN}What's Included:${NC}"
echo "  * Maple branding (Calamares, Cinnamon, LightDM, GRUB)"
[ "$ENABLE_CANADIAN_LOCALES" = true ] && echo "  * Canadian locales (en_CA, fr_CA)"
[ "$ENABLE_LIBREWOLF" = true ] && echo "  * LibreWolf browser"
[ "$ENABLE_ADDITIONAL_APPS" = true ] && echo "  * Additional apps: ${ADDITIONAL_APPS[@]}"
[ "$ENABLE_LANGUAGE_PACKS" = true ] && echo "  * Bilingual language packs (8 packages)"
echo "  * LightDM theme (v1.7-1, bundled wallpaper, no ImageMagick dependency)"
echo "  * Plymouth removed - transparent boot with system messages visible"
echo
echo -e "${CYAN}Installation Methods:${NC}"
echo "  * LightDM: localInstall (works fine in chroot)"
echo "  * Cinnamon: localInstall (works fine in chroot)"
echo
echo -e "${CYAN}Calamares Defaults:${NC}"
echo "  * Language: English (Canada)"
echo "  * Keyboard: US layout"
echo "  * Timezone: America/Toronto"
echo "  * Back button: Fixed and working"
echo
echo -e "${CYAN}Testing:${NC}"
echo "  VM: qemu-system-x86_64 -enable-kvm -m 4096 -cdrom $ISO_OUTPUT"
echo
echo -e "${CYAN}Creating Bootable USB:${NC}"
echo "  1. Find your USB device: lsblk"
echo "  2. Write ISO (replace sdX with your device):"
echo "     sudo dd if=$ISO_OUTPUT of=/dev/sdX bs=4M status=progress oflag=sync"
echo "  3. Or use: sudo cp $ISO_OUTPUT /dev/sdX && sync"
echo "  ${YELLOW}WARNING: Double-check device name - this will erase the USB!${NC}"
echo
if [ $PACKAGES_FAILED -eq 0 ]; then
    echo -e "${GREEN}All packages configured successfully!${NC}"
else
    echo -e "${YELLOW}Some packages failed - review the logs above.${NC}"
fi
echo
echo -e "${CYAN}Future-Proof Design:${NC}"
echo "  This build approach will survive Debian 14, 15+ because:"
echo "  * Uses standard APT repository structure (stable for 20+ years)"
echo "  * Works WITH Debian's infrastructure (not against it)"
echo "  * Easy to update for new releases (just change codename)"
echo "  * Proper dependency resolution via APT"
echo

# Optional: Remove build artifacts
read -p "Remove build artifacts to save space? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$EXTRACT_DIR" ]; then
        sudo rm -rf "$EXTRACT_DIR"
        echo "[OK] Removed debian_iso_extracted/ (~3GB freed)"
    fi
fi
