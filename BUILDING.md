# Building Maple Linux Core

This guide provides complete instructions for building Maple Linux Core from source, starting with just a Debian Live ISO and the build scripts.

## Prerequisites

### System Requirements

- A Debian-based system (Debian, Ubuntu, Linux Mint, etc.)
- At least 10GB free disk space
- Root/sudo access
- Stable internet connection for downloading packages

### Required Packages

Install the necessary build tools:

```bash
sudo apt-get update
sudo apt-get install -y \
    squashfs-tools \
    xorriso \
    isolinux \
    syslinux-utils \
    dpkg-dev \
    debhelper \
    imagemagick \
    wget \
    git
```

## Step 1: Obtain the Base ISO

Download the official Debian 13 "Trixie" Live ISO with Cinnamon desktop:

```bash
# Create a working directory
mkdir -p ~/maple-linux-core
cd ~/maple-linux-core

# Download the base ISO (adjust version as needed)
wget https://cdimage.debian.org/debian-cd/current-live/amd64/iso-hybrid/debian-live-13.0.0-amd64-cinnamon.iso

# Verify the download
ls -lh debian-live-*.iso
```

**Note**: The ISO is approximately 3GB. Ensure you have sufficient disk space.

## Step 2: Build the Debian Packages

All customizations are implemented as proper Debian packages. You need to build these first.

### 2.1: Package Directory Structure

Ensure your packages directory contains:

```
packages/
├── maple-calamares-branding/
│   ├── debian/
│   │   ├── control
│   │   ├── postinst
│   │   └── rules
│   └── [package contents]
├── maple-cinnamon-settings/
├── maple-lightdm-userlist/
├── maple-grub-text/
└── build_all_packages.sh
```

### 2.2: Generate Graphical Assets

Before building packages, generate the required graphical assets. Each package has pre-built assets, but if you need to regenerate them:

```bash
cd packages/maple-calamares-branding
# Assets should already be in the package, but to regenerate:
# convert source-logo.svg -resize 256x256 assets/maple-logo-256.png
# (repeat for other assets as needed)
```

**Important**: All graphical assets are pre-generated and included in the package sources. ImageMagick is only needed if you're creating new assets from scratch.

### 2.3: Build All Packages

```bash
cd ~/maple-linux-core/packages

# Option 1: Build all packages at once
chmod +x build_all_packages.sh
./build_all_packages.sh

# Option 2: Build packages individually
cd maple-calamares-branding
dpkg-buildpackage -b -uc -us
cd ..

cd maple-cinnamon-settings
dpkg-buildpackage -b -uc -us
cd ..

cd maple-lightdm-userlist
dpkg-buildpackage -b -uc -us
cd ..

cd maple-grub-text
dpkg-buildpackage -b -uc -us
cd ..
```

### 2.4: Verify Package Creation

After building, you should have .deb files in the packages directory:

```bash
ls -lh ~/maple-linux-core/packages/*.deb
```

Expected output:
```
maple-calamares-branding_1.0-1_all.deb
maple-cinnamon-settings_1.0-1_all.deb
maple-lightdm-userlist_1.0-1_all.deb
maple-grub-text_1.0-1_all.deb
```

## Step 3: Build the ISO

Now that you have the packages, you can build the customized ISO.

### 3.1: Prepare the Build Script

Make sure the build script is executable:

```bash
cd ~/maple-linux-core
chmod +x build_debian_remaster.sh
```

### 3.2: Review Build Configuration

Open `build_debian_remaster.sh` and verify these key settings:

```bash
# Working directories
WORK_DIR="$PWD/remaster_work"
ISO_EXTRACT="$WORK_DIR/iso"
SQUASHFS_DIR="$WORK_DIR/squashfs"
EDIT_DIR="$WORK_DIR/edit"

# Output ISO name
OUTPUT_ISO="maple-linux-core-${VERSION}-amd64.iso"

# Package locations
MAPLE_PACKAGES=(
    "$PWD/packages/maple-calamares-branding_1.0-1_all.deb"
    "$PWD/packages/maple-cinnamon-settings_1.0-1_all.deb"
    "$PWD/packages/maple-lightdm-userlist_1.0-1_all.deb"
    "$PWD/packages/maple-grub-text_1.0-1_all.deb"
)
```

### 3.3: Run the Build

Execute the build script with sudo (required for chroot operations):

```bash
sudo ./build_debian_remaster.sh debian-live-13.0.0-amd64-cinnamon.iso
```

### 3.4: Build Process Overview

The script performs these operations:

1. **Extraction**: Mounts and extracts the base ISO
2. **SquashFS Extraction**: Unpacks the compressed filesystem
3. **Package Installation**: Copies and installs Maple packages
4. **Application Installation**: Adds LibreWolf, Krita, Inkscape, VLC
5. **Language Support**: Installs Canadian/French locales and language packs
6. **Calamares Integration**: Configures the installer
7. **DNS Configuration**: Sets up CIRA Canadian Shield for live session
8. **Cleanup**: Removes package caches and temporary files
9. **Recompression**: Creates new squashfs filesystem
10. **ISO Generation**: Builds the final bootable ISO

### 3.5: Monitor the Build

The build process takes 10-20 minutes depending on your system. Watch for:

- ✅ Successful package installations
- ✅ "Adding back filesystem.squashfs" message
- ✅ "Creating ISO image" message
- ✅ Final success message with ISO location

### 3.6: Build Output

When complete, you'll find:

```bash
ls -lh maple-linux-core-*.iso
```

The resulting ISO is approximately 3.5GB (slightly larger than the base Debian ISO due to added packages).

## Step 4: Testing the ISO

### 4.1: Create a Test Virtual Machine

Use VirtualBox, QEMU, or virt-manager:

**VirtualBox**:
```bash
# Create a new VM
- Type: Linux
- Version: Debian (64-bit)
- Memory: 2048 MB minimum
- Disk: 20 GB
- Attach the ISO to optical drive
```

**QEMU**:
```bash
qemu-system-x86_64 \
    -cdrom maple-linux-core-1.0-amd64.iso \
    -boot d \
    -m 2048 \
    -enable-kvm
```

### 4.2: Test Checklist

Boot the ISO and verify:

**Live Session**:
- [ ] System boots to login screen
- [ ] Can log in as default user
- [ ] Desktop loads with Cinnamon
- [ ] Red-themed branding visible
- [ ] Basic functionality works (browser, file manager)
- [ ] DNS works (using CIRA Canadian Shield: 149.112.121.20)

**Installer**:
- [ ] Launch Calamares installer
- [ ] Red color scheme throughout installer
- [ ] Maple logos appear correctly
- [ ] Can complete installation process

**Installed System**:
- [ ] System boots after installation
- [ ] LightDM shows red gradient background
- [ ] User list is visible on login screen
- [ ] Cinnamon desktop loads with full branding
- [ ] Custom wallpapers available
- [ ] Dock configuration is correct
- [ ] GRUB shows "Maple Linux Core" text branding
- [ ] Timezone defaults to America/Toronto
- [ ] Locale settings are appropriate

### 4.3: Installation Test

For a complete test, perform a full installation:

1. Boot the ISO
2. Run through the Calamares installer
3. Choose appropriate options (disk, user, timezone)
4. Complete installation
5. Reboot into installed system
6. Verify all branding and customizations

## Troubleshooting

### Common Build Issues

#### Issue: "Package not found" errors

**Symptom**: Build script reports missing .deb packages

**Solution**: 
```bash
# Verify packages exist
ls -lh packages/*.deb

# If missing, rebuild packages
cd packages
./build_all_packages.sh
cd ..
```

#### Issue: "Mount point is busy"

**Symptom**: Build fails with mount-related errors

**Solution**:
```bash
# Clean up existing mounts
sudo umount remaster_work/edit/dev/pts 2>/dev/null
sudo umount remaster_work/edit/dev 2>/dev/null
sudo umount remaster_work/edit/proc 2>/dev/null
sudo umount remaster_work/edit/sys 2>/dev/null

# Remove work directory
sudo rm -rf remaster_work

# Retry build
```

#### Issue: "No space left on device"

**Symptom**: Build fails during package installation or squashfs creation

**Solution**:
```bash
# Check available space
df -h

# Clean up previous builds
sudo rm -rf remaster_work
rm -f maple-linux-core-*.iso

# Free up at least 10GB before retrying
```

#### Issue: Build completes but ISO doesn't boot

**Symptom**: ISO creation succeeds but doesn't boot in VM

**Solution**:
```bash
# Verify ISO isn't corrupted
file maple-linux-core-*.iso
# Should show: ISO 9660 CD-ROM filesystem data

# Check ISO size
ls -lh maple-linux-core-*.iso
# Should be approximately 3.5GB

# Verify in VM settings:
# - Boot order has CD/DVD first
# - ISO is properly attached
# - Sufficient RAM allocated (2GB minimum)
```

### Package-Specific Issues

#### maple-calamares-branding not applying

Check the package installation in chroot:

```bash
# During build, verify in the log output:
grep "maple-calamares-branding" build.log

# After installation, verify:
dpkg -l | grep maple-calamares-branding
```

#### Desktop settings not applying

Desktop settings only apply to newly created users, not the live session user. Test by:
1. Installing the system
2. Creating a new user
3. Logging in as that new user

## Advanced: Customizing the Build

### Modifying Packages

To customize any package:

1. Edit the package source files in `packages/maple-*-*/`
2. Update version in `debian/changelog`
3. Rebuild the package: `dpkg-buildpackage -b -uc -us`
4. Rebuild the ISO with the new package

### Adding More Applications

Edit `build_debian_remaster.sh` and add to the installation section:

```bash
chroot edit apt-get install -y your-package-name
```

### Changing Default Settings

Default settings are controlled by the `maple-cinnamon-settings` package. Edit:

```
packages/maple-cinnamon-settings/etc/skel/.config/
```

### Creating Custom Wallpapers

1. Add your wallpapers to `packages/maple-cinnamon-settings/usr/share/backgrounds/maple/`
2. Update the package metadata if needed
3. Rebuild the package and ISO

## Build Script Architecture

### Key Components

**Extraction Phase**:
- Mounts ISO to extract contents
- Unpacks squashfs filesystem
- Prepares chroot environment

**Customization Phase**:
- Copies custom packages into chroot
- Installs packages with dependencies
- Configures system defaults
- Adds additional software

**Rebuild Phase**:
- Cleans up package caches
- Recompresses filesystem with maximum compression
- Generates new ISO with xorriso
- Makes ISO bootable

### Error Handling Strategy

The build script uses explicit error handling:

- Each critical operation is verified
- Package installations check for success
- File existence is confirmed before operations
- Comprehensive logging captures all output

This "fail fast" approach prevents silent failures that could result in broken ISOs.

## Maintenance and Updates

### Updating to New Debian Releases

When Debian releases a new version:

1. Download the new base ISO
2. Test the build script with the new ISO
3. Adjust package dependencies if needed
4. Verify all customizations still work
5. Update documentation

The minimalist approach means updates should require little to no modification.

### Package Versioning

When updating packages:

1. Edit the package source
2. Update `debian/changelog` with new version
3. Rebuild: `dpkg-buildpackage -b -uc -us`
4. Test the new package
5. Rebuild the ISO

### Keeping Dependencies Minimal

Regularly review package dependencies:

```bash
# Check what each package depends on
dpkg-deb -I maple-calamares-branding_1.0-1_all.deb

# Look for unnecessary dependencies
# Remove anything not strictly required
```

## Contributing Improvements

If you improve the build process:

1. Test thoroughly in clean environment
2. Document the changes
3. Update relevant scripts and docs
4. Submit a pull request with clear description

## Getting Help

If you encounter issues:

1. Check this documentation first
2. Review the troubleshooting section
3. Search existing issues on Codeberg
4. Create a new issue with:
   - Your system details
   - Steps to reproduce
   - Complete error messages
   - Build log if available

## Next Steps

Once you have a working build:

- Create a bootable USB with the ISO
- Test on real hardware
- Gather feedback from users
- Iterate on the design
- Consider contributing back to Debian and upstream projects

---

**Remember**: The goal is to keep things simple, maintainable, and close to Debian upstream. Every customization should have a clear purpose and be implemented in the most straightforward way possible.
