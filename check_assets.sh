#!/bin/bash
# Maple Linux Core - Asset Verification Script
# Checks for all required image files before building packages
# Run this before building any packages to ensure all assets are present

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "================================================"
echo "  Maple Linux Core - Asset Verification"
echo "================================================"
echo ""

# Track overall status
ALL_PRESENT=true
WARNINGS=()

# ============================================================
# CHECK 1: SVG LOGO (Required by Calamares and LightDM)
# ============================================================
echo -e "${CYAN}[1] Checking SVG Logo...${NC}"
echo "    Required by: Calamares, LightDM"
echo ""

SVG_FILE="maple-linux-logo-ring-symbolic.svg"

if [ -f "$SVG_FILE" ]; then
    FILE_SIZE=$(stat -f%z "$SVG_FILE" 2>/dev/null || stat -c%s "$SVG_FILE" 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}[OK]${NC} $SVG_FILE found"
    echo "       Size: $FILE_SIZE bytes"
    
    # Verify it's actually an SVG
    if file "$SVG_FILE" | grep -q "SVG"; then
        echo -e "       ${GREEN}Format: Valid SVG${NC}"
    else
        echo -e "       ${YELLOW}Warning: File may not be a valid SVG${NC}"
        WARNINGS+=("$SVG_FILE may not be a valid SVG file")
    fi
else
    echo -e "  ${RED}X MISSING${NC} $SVG_FILE"
    echo ""
    echo "  This file is REQUIRED for:"
    echo "    * Calamares installer logo"
    echo "    * LightDM user avatar icon"
    echo ""
    ALL_PRESENT=false
fi
echo ""

# ============================================================
# CHECK 2: GRUB BACKGROUND (Required by GRUB, LightDM, Plymouth)
# ============================================================
echo -e "${CYAN}[2] Checking GRUB Background...${NC}"
echo "    Required by: GRUB, LightDM, Plymouth"
echo ""

GRUB_BG="maple-grub-background.png"

if [ -f "$GRUB_BG" ]; then
    FILE_SIZE=$(stat -f%z "$GRUB_BG" 2>/dev/null || stat -c%s "$GRUB_BG" 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}[OK]${NC} $GRUB_BG found"
    echo "       Size: $FILE_SIZE bytes"
    
    # Verify it's actually a PNG
    if file "$GRUB_BG" | grep -q "PNG"; then
        echo -e "       ${GREEN}Format: Valid PNG${NC}"
        
        # Try to get dimensions if identify is available
        if command -v identify &> /dev/null; then
            DIMENSIONS=$(identify -format "%wx%h" "$GRUB_BG" 2>/dev/null || echo "unknown")
            echo "       Dimensions: $DIMENSIONS"
            
            # Check if dimensions are reasonable for boot splash
            WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
            if [ "$WIDTH" != "unknown" ] && [ "$WIDTH" -lt 1024 ]; then
                WARNINGS+=("$GRUB_BG width is less than 1024px - may look stretched on larger screens")
                echo -e "       ${YELLOW}Note: Image width is less than 1024px${NC}"
            fi
        else
            echo "       Dimensions: (install imagemagick to check)"
        fi
    else
        echo -e "       ${YELLOW}Warning: File may not be a valid PNG${NC}"
        WARNINGS+=("$GRUB_BG may not be a valid PNG file")
    fi
else
    echo -e "  ${RED}X MISSING${NC} $GRUB_BG"
    echo ""
    echo "  This file is REQUIRED for:"
    echo "    * GRUB boot menu background"
    echo "    * LightDM login screen background"
    echo "    * Plymouth boot splash background"
    echo ""
    echo "  All three components share this single wallpaper for consistency."
    echo ""
    ALL_PRESENT=false
fi
echo ""

# ============================================================
# CHECK 3: CINNAMON WALLPAPER (Required by Cinnamon desktop)
# ============================================================
echo -e "${CYAN}[3] Checking Cinnamon Desktop Wallpaper...${NC}"
echo "    Required by: Cinnamon desktop environment"
echo ""

CINNAMON_WALLPAPER="maple-cinnamon-wallpaper.png"

if [ -f "$CINNAMON_WALLPAPER" ]; then
    FILE_SIZE=$(stat -f%z "$CINNAMON_WALLPAPER" 2>/dev/null || stat -c%s "$CINNAMON_WALLPAPER" 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}[OK]${NC} $CINNAMON_WALLPAPER found"
    echo "       Size: $FILE_SIZE bytes"
    
    # Verify it's actually a PNG
    if file "$CINNAMON_WALLPAPER" | grep -q "PNG"; then
        echo -e "       ${GREEN}Format: Valid PNG${NC}"
        
        # Try to get dimensions if identify is available
        if command -v identify &> /dev/null; then
            DIMENSIONS=$(identify -format "%wx%h" "$CINNAMON_WALLPAPER" 2>/dev/null || echo "unknown")
            echo "       Dimensions: $DIMENSIONS"
            
            # Check if dimensions are reasonable for desktop
            WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
            if [ "$WIDTH" != "unknown" ] && [ "$WIDTH" -lt 1920 ]; then
                WARNINGS+=("$CINNAMON_WALLPAPER width is less than 1920px - may not look good on Full HD displays")
                echo -e "       ${YELLOW}Note: Image width is less than 1920px${NC}"
            fi
        else
            echo "       Dimensions: (install imagemagick to check)"
        fi
    else
        echo -e "       ${YELLOW}Warning: File may not be a valid PNG${NC}"
        WARNINGS+=("$CINNAMON_WALLPAPER may not be a valid PNG file")
    fi
else
    echo -e "  ${RED}X MISSING${NC} $CINNAMON_WALLPAPER"
    echo ""
    echo "  This file is REQUIRED for:"
    echo "    * Cinnamon desktop wallpaper"
    echo ""
    ALL_PRESENT=false
fi
echo ""

# ============================================================
# CHECK 4: OPTIONAL - IMAGEMAGICK (For Calamares welcome image)
# ============================================================
echo -e "${CYAN}[4] Checking Optional Dependencies...${NC}"
echo "    Optional: ImageMagick (for generating Calamares welcome image)"
echo ""

if command -v convert &> /dev/null; then
    echo -e "  ${GREEN}[OK]${NC} ImageMagick is installed"
    echo "       Calamares welcome image will be generated during package build"
else
    echo -e "  ${YELLOW}[INFO]${NC} ImageMagick not installed"
    echo "       Calamares will use a placeholder welcome image"
    echo "       This is not critical - installer will still work"
    WARNINGS+=("ImageMagick not installed - Calamares welcome image will be a placeholder")
fi
echo ""

# ============================================================
# SUMMARY
# ============================================================
echo "================================================"
echo "  Verification Summary"
echo "================================================"
echo ""

if [ "$ALL_PRESENT" = true ]; then
    echo -e "${GREEN}[OK] All required assets are present!${NC}"
    echo ""
    echo "Ready to build packages:"
    echo "  ./build-calamares.sh"
    echo "  ./build-cinnamon.sh"
    echo "  ./build-lightdm.sh"
    echo "  ./build-grub.sh"
    echo "  ./build_plymouth.sh"
    echo ""
else
    echo -e "${RED}X MISSING ASSETS${NC}"
    echo ""
    echo "The following required files are missing:"
    echo ""
    
    [ ! -f "$SVG_FILE" ] && echo "  * $SVG_FILE"
    [ ! -f "$GRUB_BG" ] && echo "  * $GRUB_BG"
    [ ! -f "$CINNAMON_WALLPAPER" ] && echo "  * $CINNAMON_WALLPAPER"
    
    echo ""
    echo "Please add these files to the current directory before building."
    echo ""
fi

# ============================================================
# WARNINGS
# ============================================================
if [ ${#WARNINGS[@]} -gt 0 ]; then
    echo -e "${YELLOW}Warnings:${NC}"
    echo ""
    for warning in "${WARNINGS[@]}"; do
        echo "  - $warning"
    done
    echo ""
fi

# ============================================================
# FILE LIST
# ============================================================
echo "================================================"
echo "  Required Assets Checklist"
echo "================================================"
echo ""

printf "%-40s %-12s %-20s\n" "FILE" "STATUS" "USED BY"
printf "%-40s %-12s %-20s\n" "----" "------" "-------"

if [ -f "$SVG_FILE" ]; then
    printf "%-40s ${GREEN}%-12s${NC} %-20s\n" "$SVG_FILE" "[OK]" "Calamares, LightDM"
else
    printf "%-40s ${RED}%-12s${NC} %-20s\n" "$SVG_FILE" "[MISSING]" "Calamares, LightDM"
fi

if [ -f "$GRUB_BG" ]; then
    printf "%-40s ${GREEN}%-12s${NC} %-20s\n" "$GRUB_BG" "[OK]" "GRUB, LightDM, Plymouth"
else
    printf "%-40s ${RED}%-12s${NC} %-20s\n" "$GRUB_BG" "[MISSING]" "GRUB, LightDM, Plymouth"
fi

if [ -f "$CINNAMON_WALLPAPER" ]; then
    printf "%-40s ${GREEN}%-12s${NC} %-20s\n" "$CINNAMON_WALLPAPER" "[OK]" "Cinnamon desktop"
else
    printf "%-40s ${RED}%-12s${NC} %-20s\n" "$CINNAMON_WALLPAPER" "[MISSING]" "Cinnamon desktop"
fi

echo ""

# ============================================================
# ADDITIONAL INFO
# ============================================================
echo "================================================"
echo "  Asset Guidelines"
echo "================================================"
echo ""

echo "maple-linux-logo-ring-symbolic.svg:"
echo "  - Purpose: Logo for installer and login screen"
echo "  - Format: SVG (scalable vector graphics)"
echo "  - Recommended: Simple design, works at multiple sizes"
echo "  - Used in: Calamares installer, LightDM user avatars"
echo ""

echo "maple-grub-background.png:"
echo "  - Purpose: Background wallpaper for boot and login"
echo "  - Format: PNG (recommended)"
echo "  - Recommended size: 1920x1080 or larger"
echo "  - Aspect ratio: 16:9 (or 16:10 for some displays)"
echo "  - Used in: GRUB menu, LightDM login, Plymouth splash"
echo "  - Note: Same image used everywhere for consistent branding"
echo ""

echo "maple-cinnamon-wallpaper.png:"
echo "  - Purpose: Desktop background wallpaper"
echo "  - Format: PNG (recommended)"
echo "  - Recommended size: 1920x1080 or larger (3840x2160 for 4K)"
echo "  - Aspect ratio: 16:9 (standard) or 16:10"
echo "  - Used in: Cinnamon desktop environment default wallpaper"
echo "  - Note: Can be different from boot/login wallpaper"
echo ""

# ============================================================
# EXIT CODE
# ============================================================
if [ "$ALL_PRESENT" = true ]; then
    exit 0
else
    echo -e "${RED}Please add missing assets before building packages.${NC}"
    echo ""
    exit 1
fi
