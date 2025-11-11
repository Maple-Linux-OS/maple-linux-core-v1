# Contributing to Maple Linux Core

Thank you for your interest in contributing to Maple Linux Core! This document provides guidelines for contributing to the project.

## Philosophy Alignment

Before contributing, please read [PHILOSOPHY.md](PHILOSOPHY.md) to understand our core principles:

- Minimal modifications to Debian
- Proper packaging for all changes
- Maintainability over features
- Close adherence to upstream

Contributions that don't align with these principles may not be accepted, regardless of technical merit.

## Types of Contributions

We welcome several types of contributions:

### Bug Reports
- **Where**: Open an issue on Codeberg
- **Include**: Steps to reproduce, expected vs actual behavior, system info
- **Distinguish**: Is this a Debian bug or Maple-specific?

### Bug Fixes
- Fork the repository
- Create a fix in a feature branch
- Test thoroughly (both live and installed)
- Submit a pull request with clear description

### Documentation Improvements
- Typo fixes
- Clarifications
- Additional examples
- Translation improvements

### New Features
**IMPORTANT**: Open an issue to discuss BEFORE implementing!

We're very selective about new features. Ask:
- Does this align with our minimalist philosophy?
- Is it worth the maintenance burden?
- Can it be implemented cleanly?
- Will it break on Debian updates?

Many well-intentioned features may be declined to keep the project maintainable.

## Contribution Process

### 1. Fork and Clone

```bash
# Fork on Codeberg first, then:
git clone https://codeberg.org/maplelinux/maple-linux-core.git
cd maple-linux-core
git remote add upstream https://codeberg.org/maplelinux/maple-linux-core.git
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
```

Use descriptive branch names.

### 3. Make Your Changes

Follow these guidelines:

#### For Package Changes

```bash
cd packages/maple-[package-name]

# Make your changes
vim [files]

# Update changelog
dch -i  # This will open an editor

# Rebuild package
dpkg-buildpackage -b -uc -us

# Test the package
sudo dpkg -i ../maple-[package-name]_*.deb
# Verify changes work as expected
```

#### For Build Script Changes

```bash
# Make changes to build_debian_remaster.sh
vim build_debian_remaster.sh

# Test with a full build
sudo ./build_debian_remaster.sh debian-live-*.iso

# Verify ISO boots and works correctly
```

#### For Documentation Changes

```bash
# Edit the relevant .md file
vim README.md  # or other docs

# Preview locally if possible
# Check formatting and links
```

### 4. Test Thoroughly

**Minimum testing requirements**:

For package changes:
- [ ] Package builds without errors
- [ ] Package installs cleanly
- [ ] Functionality works in installed system
- [ ] No conflicts with other packages
- [ ] Uninstalls cleanly if tested

For build script changes:
- [ ] ISO builds successfully
- [ ] ISO boots in VM
- [ ] Can complete installation
- [ ] All branding appears correctly
- [ ] No regressions in existing functionality

For documentation:
- [ ] Links work
- [ ] Formatting is correct
- [ ] No spelling errors
- [ ] Technically accurate

### 5. Commit Changes

Write clear commit messages:

```bash
git add [files]
git commit -m "Short description of change

Longer explanation if needed:
- What changed
- Why it changed
- Any side effects or considerations"
```

**Good commit messages**:
```
Fix: Correct LightDM background path in maple-lightdm-userlist

The background image path was incorrect, causing the default
background to appear instead of our red gradient.

Updated path in lightdm-gtk-greeter.conf and verified in test VM.
```

**Bad commit messages**:
```
fixed stuff
update
changes
```

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on Codeberg with:

**Title**: Brief, descriptive summary

**Description**:
- What does this change do?
- Why is this change needed?
- How was it tested?
- Any breaking changes or special considerations?
- Related issues (if any)

## Code Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Set `set -e` for error propagation
- Quote variables: `"$VARIABLE"` not `$VARIABLE`
- Use explicit error checking
- Add comments for complex logic
- Test with shellcheck if possible

**Example**:
```bash
#!/bin/bash
set -e

PACKAGE_NAME="maple-example"
VERSION="1.0"

if [ ! -f "$PACKAGE_FILE" ]; then
    echo "ERROR: Package file not found: $PACKAGE_FILE"
    exit 1
fi

echo "Installing $PACKAGE_NAME version $VERSION..."
```

### Debian Packages

- Follow Debian Policy Manual
- Use debhelper for build system
- Proper dependency declarations
- Meaningful package descriptions
- Test postinst/prerm scripts
- Version appropriately

**Versioning**:
- Bug fixes: 1.0-1 → 1.0-2
- Minor changes: 1.0-1 → 1.1-1
- Major changes: 1.0-1 → 2.0-1

### Documentation

- Use Markdown format
- Be clear and concise
- Include examples where helpful
- Check spelling and grammar
- Link to related docs
- Keep line lengths reasonable

## What We're Looking For

### High Priority
✅ Bug fixes (especially for reported issues)  
✅ Documentation improvements  
✅ Build process optimizations  
✅ Testing improvements  
✅ Performance enhancements  

### Medium Priority
🔶 New package configurations (if well-justified)  
🔶 Additional language support  
🔶 Desktop environment refinements  
🔶 Installer improvements  

### Low Priority (Usually Declined)
⚠️ New applications in default install  
⚠️ Alternative desktop environments  
⚠️ Major architectural changes  
⚠️ Features that diverge from Debian  

### Will Be Declined
❌ Proprietary software  
❌ Binary blobs without source  
❌ Changes that break Debian compatibility  
❌ Excessive customization  
❌ Features with high maintenance cost  
❌ Anything violating our philosophy  

## Review Process

1. **Initial Review**: Maintainer checks if contribution aligns with philosophy
2. **Technical Review**: Code quality, testing, documentation
3. **Testing**: Verify changes work as claimed
4. **Integration**: Merge if approved, with possible modifications
5. **Feedback**: If declined, explanation provided

Reviews may take time. Please be patient.

## Getting Help

### Before Asking

- Read existing documentation
- Search closed issues
- Check BUILDING.md for build problems
- Review PHILOSOPHY.md for design questions

### Where to Ask

- **Bug reports**: Open an issue
- **Questions**: Use issue with "question" label
- **Discussions**: Community forum (if available)
- **Security issues**: Email maintainers directly

## Code of Conduct

### Be Respectful

- Treat all contributors with respect
- Accept constructive criticism gracefully
- Focus on what's best for the project
- Be patient with newcomers
- Give credit where due

### Be Professional

- Stay on topic
- Avoid personal attacks
- No harassment or discrimination
- Keep discussions technical
- Disagree without being disagreeable

### Be Collaborative

- Share knowledge freely
- Help others learn
- Document your work
- Communicate clearly
- Work together toward common goals

## Recognition

Contributors will be recognized in:
- Git commit history
- Release notes
- CONTRIBUTORS.md (if we create one)
- Project acknowledgments

Significant contributors may be invited to become maintainers.

## Legal

By contributing to Maple Linux Core, you agree that:

- Your contributions are your own work
- You have the right to submit them
- Your contributions will be licensed under the GPL-3 or later
- You understand Maple Linux Core incorporates GPL and other free software components

See LICENSE file for details.

## Questions?

If you have questions about contributing:

1. Check if your question is answered in this guide
2. Search existing issues for similar questions
3. Open a new issue with the "question" label

We're happy to help genuine contributors!

## Final Notes

### Remember

The goal of Maple Linux Core is to create something:
- Simple and maintainable
- Close to Debian upstream
- Useful for Canadian users
- Sustainable long-term

Not every contribution, no matter how well-intentioned or technically impressive, will be accepted if it conflicts with these goals.

### Thank You

We appreciate your interest in Maple Linux Core. Even if your specific contribution isn't accepted, your effort helps the project by:
- Identifying areas for improvement
- Demonstrating community interest
- Sharing different perspectives
- Testing the limits of our approach

Every interaction makes the project better!

---

**Maple Linux Core**: Simple, lean, and proudly Canadian. 🍁
