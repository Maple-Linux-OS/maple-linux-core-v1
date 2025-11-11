# Maple Linux Core

A minimalist, Canadian-focused Linux distribution based on Debian 13 "Trixie" with Cinnamon desktop environment.


## Philosophy

Maple Linux Core follows a core principle: **minimal, surgical modifications** that stay close to upstream Debian. This isn't about reinventing the wheel or creating yet another heavily customized distribution. It's about taking Debian's rock-solid foundation and adding just enough polish to create a cohesive, professionally branded experience for Canadian users.

### Why This Approach?

After 30+ years in the Linux ecosystem, we've learned that fighting upstream is a losing battle. Debian's infrastructure, packaging system, and design decisions exist for good reasons. Our approach:

- **Work with Debian, not against it**: Extend Debian's patterns rather than replacing them
- **Package everything properly**: No direct system modifications, only proper .deb packages
- **Stay maintainable**: Future Debian releases should require minimal rework
- **Keep it simple**: If it's not broken, don't customize it

This means Maple Linux Core is about 98% pure Debian with targeted enhancements where they matter most: installer experience, desktop branding, and user-facing defaults.

## What Makes Maple Linux Core Different?

### Canadian by Default
- Bilingual support (English and Canadian French locales)
- America/Toronto timezone default
- Canadian keyboard layouts prioritized
- Consistent Maple leaf branding throughout
- CIRA Canadian Shield DNS for live sessions (privacy-focused, malware-blocking Canadian DNS)

### Professional Branding
- Red-themed color scheme across all components
- Custom Calamares installer with Maple branding
- Themed LightDM login screen
- Custom wallpapers and desktop settings
- GRUB text branding for installed systems

### Thoughtful Additions
- LibreWolf browser (privacy-focused Firefox fork)
- Creative tools (Krita, Inkscape)
- VLC media player
- LibreOffice with multilingual support
- Thunderbird with language packs

## Technical Approach

### ISO Remastering, Not Building from Scratch

We use ISO remastering rather than building from scratch. This means:

1. Start with official Debian Live Cinnamon ISO
2. Add custom .deb packages for branding and configuration
3. Rebuild with Calamares installer integration
4. Test and verify

This methodology preserves all of Debian's proven functionality while applying targeted customizations only where needed.

### Package-First Development

Every customization is implemented as a proper Debian package:

- **maple-calamares-branding**: Installer appearance and behavior
- **maple-cinnamon-settings**: Desktop environment defaults
- **maple-lightdm-userlist**: Login screen theming
- **maple-grub-text**: Boot menu branding

Each package handles a specific domain with clear separation of concerns, making maintenance straightforward and updates predictable.

## Current State

The distribution is functionally complete with all major components working:

✅ Bootable ISO creation  
✅ Calamares installer with full branding  
✅ Cinnamon desktop with custom themes and settings  
✅ LightDM login screen with red gradient and user list  
✅ GRUB text branding for installed systems  
✅ Bilingual support (English/French Canadian)  
✅ Additional applications integrated  
✅ No runtime ImageMagick dependencies (all assets pre-generated)  
✅ CIRA Canadian Shield DNS for live sessions (Canadian privacy-focused DNS)  

## The Journey: What We Learned

### Key Insights

1. **Embrace Debian's Design**: Early attempts to override Debian's decisions led to conflicts. Working with Debian's patterns proved reliable and maintainable.

2. **Live vs Installed Systems**: These behave differently. Minimal branding for live sessions, full customization on installed systems works best.

3. **Package Everything**: Direct system file modifications are fragile. Proper Debian packaging with postinst scripts ensures clean integration with updates.

4. **Error Handling Matters**: Silent failures were our biggest enemy. Explicit error handling and verification steps are essential.

5. **No Wildcards in Build Scripts**: Use explicit package names and versions to avoid timing issues where variables become empty.

### Notable Challenges Overcome

**The ImageMagick Dependency Reduction**  
Initially, we generated graphics at runtime during ISO creation. This added complexity and dependencies. Solution: pre-generate all assets during package build time, bundle them as static files. Result: cleaner builds, fewer dependencies.

**The Live Session Puzzle**  
Many customizations that worked perfectly in installed systems failed in live environments due to timing issues and chroot limitations. Solution: accept minimal live session branding, focus on installed system experience.

**The Calamares Configuration Dance**  
Getting Calamares to respect our branding while maintaining Debian's functionality required understanding the interplay between calamares-settings-debian and our custom package. Solution: extend rather than replace the Debian package.

**The Silent Failure Syndrome**  
Build scripts that suppressed errors masked problems, leading to functional ISOs missing intended customizations. Solution: explicit error handling, package verification, detailed logging.

## Getting Started

See [BUILDING.md](BUILDING.md) for complete build instructions.

### Quick Start

```bash
# Prerequisites (Debian/Ubuntu)
sudo apt-get install squashfs-tools xorriso isolinux syslinux-utils \
                     dpkg-dev debhelper imagemagick

# Clone the repository
git clone https://codeberg.org/yourusername/maple-linux-core.git
cd maple-linux-core

# Download base Debian ISO
wget https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.0.0-amd64-cinnamon.iso

# Build packages
cd packages
./build_all_packages.sh

# Build ISO
cd ..
sudo ./build_debian_remaster.sh debian-live-13.0.0-amd64-cinnamon.iso
```

## Project Structure

```
maple-linux-core/
├── packages/                    # Debian package sources
│   ├── maple-calamares-branding/
│   ├── maple-cinnamon-settings/
│   ├── maple-lightdm-userlist/
│   └── maple-grub-text/
├── build_debian_remaster.sh     # Main ISO build script
├── docs/                        # Documentation and assets
├── README.md                    # This file
└── BUILDING.md                  # Detailed build instructions
```

## Contributing

This project welcomes contributions that align with our minimalist philosophy. Before proposing major changes, please open an issue to discuss the approach.

### Guidelines

- Stay close to Debian upstream
- Package properly, never hack system files directly
- Test in both live and installed environments
- Document your changes
- Keep it simple and maintainable

## License

This project's custom components are released under the MIT License. See LICENSE file for details.

Note: Maple Linux Core is based on Debian GNU/Linux and incorporates many upstream packages. Those components retain their original licenses.

## Acknowledgments

- The Debian Project for creating an outstanding foundation
- The Cinnamon desktop team for a polished user experience
- The Calamares team for a flexible, modern installer
- The Linux Mint project for inspiration on thoughtful defaults
- Everyone who believes Linux distributions should be maintainable by humans

## Contact

- Project: https://codeberg.org/maplelinux/maple-linux-core
- Issues: https://codeberg.org/maplelinux/maple-linux-core/issues

---

**Maple Linux Core**: Simple, lean, and proudly Canadian. 🍁
