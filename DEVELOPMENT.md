# Development Journey

This document chronicles the development of Maple Linux Core from concept to completion, including key milestones, challenges faced, and solutions discovered.

## Project Genesis

### The Vision

**Goal**: Create a Canadian-focused Linux distribution that's:
- Based on Debian's solid foundation
- Professionally branded with Maple leaf theme
- Minimally modified for maintainability
- Bilingual (English/French Canadian)
- Simple enough to maintain long-term

**Approach**: ISO remastering with package-based customizations rather than building from scratch.

**Timeline**: From initial concept to functional distribution in [your timeframe].

## Development Phases

### Phase 1: Foundation and Architecture

#### Initial Setup
- Chose Debian 13 "Trixie" with Cinnamon as base
- Selected ISO remastering methodology over build-from-scratch
- Established package-first development pattern
- Set up build environment and tooling

#### Key Decisions
- **Debian over Ubuntu**: Fewer layers, more predictable
- **Cinnamon over others**: Good balance of features and familiarity
- **Calamares installer**: Modern, customizable, actively maintained
- **Package everything**: No direct system modifications

#### Early Challenges
- Learning Debian packaging conventions
- Understanding ISO structure and remastering workflow
- Mapping out which components needed customization
- Determining scope (what to change vs. what to leave alone)

### Phase 2: Calamares Installer Branding

#### Objectives
- Red color scheme throughout installer
- Maple leaf logos at appropriate sizes
- Custom slide deck for installation process
- Professional welcome and completion messages

#### Implementation
Created `maple-calamares-branding` package:
- Extended calamares-settings-debian (not replaced)
- Generated Maple logos at multiple sizes (256px, 128px, 64px, 48px)
- Designed red-themed branding.desc configuration
- Created installation slideshow content
- Wrote postinst script to update Calamares configuration

#### Challenges Encountered

**Challenge 1: Override vs. Extend**
- Initial attempt: Replace calamares-settings-debian completely
- Problem: Lost Debian's hardware detection and configuration
- Solution: Use `Provides:` and proper configuration merging
- Lesson: Extend existing packages, don't replace them

**Challenge 2: Logo Sizing**
- Issue: Different Calamares screens need different logo sizes
- Problem: Generated wrong sizes initially
- Solution: Created complete set (256, 128, 64, 48 pixels)
- Result: Professional appearance at all stages

**Challenge 3: Configuration Priority**
- Issue: Our settings weren't overriding Debian's
- Problem: Incorrect file placement and postinst timing
- Solution: Proper configuration directory structure and update-alternatives
- Outcome: Clean override system that survives updates

#### Milestone Achieved
✅ Professional, red-themed installer with Maple branding throughout

### Phase 3: Desktop Environment Customization

#### Objectives
- Custom Maple wallpapers
- Themed panel and applets
- Dock configuration with useful defaults
- Consistent red/Maple theme
- Settings apply to new users only (not live session)

#### Implementation
Created `maple-cinnamon-settings` package:
- Wallpapers in /usr/share/backgrounds/maple/
- Settings in /etc/skel/.config/ for new users
- Dconf defaults for system-wide preferences
- Custom panel configuration (favorites, layout)
- Theme and icon selection

#### Challenges Encountered

**Challenge 1: Live vs. Installed Settings**
- Initial approach: Apply settings to live session
- Problem: Constant failures due to timing and permissions
- Root cause: Live user already exists with own configs
- Solution: Only apply to /etc/skel/ for new user creation
- Lesson: Accept minimal live session customization

**Challenge 2: Dock Configuration**
- Issue: Panel configuration is complex nested JSON
- Problem: Wrong structure broke entire panel
- Solution: Extract from working system, test thoroughly
- Result: Reliable panel defaults with app favorites

**Challenge 3: Theme Dependencies**
- Issue: Custom themes needed packaging
- Problem: Licensing and maintenance concerns
- Solution: Use mint-y-icons from Debian repos
- Lesson: Leverage existing packages when possible

#### Milestone Achieved
✅ Branded desktop environment for installed systems with Canadian defaults

### Phase 4: Login Screen Theming

#### Objectives
- Red gradient background for LightDM
- User list enabled by default
- Consistent branding with rest of system
- Clean, professional appearance

#### Implementation
Created `maple-lightdm-userlist` package:
- Generated red gradient background PNG
- Configured LightDM to show user list
- Added greeter settings for theme integration
- Postinst script for configuration application

#### Challenges Encountered

**Challenge 1: Background Not Applying**
- Issue: LightDM ignored our background setting
- Problem: Configuration priority incorrect
- Solution: Proper conf.d ordering and file naming
- Result: Background applies reliably

**Challenge 2: User List Toggle**
- Issue: Users weren't showing in list
- Problem: Wrong configuration directive
- Solution: Set greeter-hide-users=false explicitly
- Outcome: User list works as expected

**Challenge 3: Theme Integration**
- Issue: Greeter theme didn't match desktop
- Problem: Wrong theme specification
- Solution: Use consistent theme across components
- Result: Cohesive visual experience

#### Milestone Achieved
✅ Professional login screen with red branding and user list

### Phase 5: GRUB Bootloader Branding

#### Objectives
- Text-only branding (no graphics in boot menu)
- "Maple Linux Core" identification
- Maintain all GRUB functionality
- Simple, clean implementation

#### Implementation
Created `maple-grub-text` package:
- Modified /etc/default/grub with distributor ID
- Postinst script runs update-grub
- Text-only approach (no complex graphics)
- Preserves all boot options and functionality

#### Challenges Encountered

**Challenge 1: Graphics Complexity**
- Initial idea: Graphical splash screen
- Problem: Resolution detection, theme compatibility
- Solution: Text-only branding is simpler and reliable
- Lesson: Simple solutions often better than complex ones

**Challenge 2: Update Timing**
- Issue: GRUB not updating during installation
- Problem: Postinst running in chroot vs. installed system
- Solution: Accept this limitation, updates work post-install
- Result: GRUB branding appears after first kernel update

#### Milestone Achieved
✅ Bootloader identifies system as "Maple Linux Core"

### Phase 6: Application Integration and Localization

#### Objectives
- Add useful applications (LibreWolf, creative tools, VLC)
- Install Canadian and French locales
- Add language packs for major applications
- Configure timezone defaults
- Set up CIRA Canadian Shield DNS for live sessions

#### Implementation
Modified build script to:
- Install LibreWolf from Debian repos
- Add Krita, Inkscape for creative work
- Install VLC media player
- Configure locales (en_CA, fr_CA, fr_FR)
- Add Thunderbird and LibreOffice language packs
- Set America/Toronto as default timezone
- Configure CIRA Canadian Shield DNS for live session (149.112.121.20, 149.112.122.20)

#### Challenges Encountered

**Challenge 1: LibreWolf Availability**
- Issue: LibreWolf not in main Debian repos
- Problem: Needed to add external repository
- Solution: Used proper apt sources configuration
- Result: Clean installation without manual repos

**Challenge 2: Language Pack Selection**
- Issue: Which language packs to include?
- Problem: Balance between size and completeness
- Solution: Canadian English, French, and French Canadian
- Result: Comprehensive coverage for target audience

**Challenge 3: Locale Priority**
- Issue: Setting locale defaults properly
- Problem: Debian's locale system is particular
- Solution: Configure locale-gen and update-locale correctly
- Outcome: Appropriate defaults for Canadian users

**Challenge 4: DNS Selection**
- Issue: Which DNS to use for live session?
- Problem: Google DNS works but isn't Canadian-aligned
- Solution: CIRA Canadian Shield - Canadian, privacy-focused, malware-blocking
- Result: Authentically Canadian infrastructure with privacy protection
- Note: Installed systems use network-provided DNS for flexibility

#### Milestone Achieved
✅ Well-rounded application set with full bilingual support and Canadian infrastructure

### Phase 7: Build System Refinement

#### Objectives
- Eliminate runtime dependencies where possible
- Improve error handling in build script
- Add verification steps
- Optimize build time and ISO size

#### Implementation
Major improvements to build_debian_remaster.sh:
- Explicit error checking (no silent failures)
- Package verification before installation
- Comprehensive logging throughout
- Proper cleanup of apt caches
- Maximum squashfs compression

#### Challenges Encountered

**Challenge 1: Silent Failures**
- Issue: Builds succeeding with missing customizations
- Problem: Error suppression masked failures
- Solution: Removed all `|| true` and `2>/dev/null` patterns
- Result: Failures now visible and fixable

**Challenge 2: Wildcard Variables**
- Issue: Package installation sometimes skipped
- Problem: `$PACKAGES` empty when evaluated too early
- Solution: Explicit package name array with verification
- Result: Reliable package installation

**Challenge 3: ImageMagick Runtime Dependency**
- Issue: ImageMagick needed at build time
- Problem: Why require it if we could pre-generate?
- Solution: Generate all assets during package creation
- Result: Simpler builds, fewer dependencies

#### Milestone Achieved
✅ Robust build system with explicit error handling

### Phase 8: Testing and Refinement

#### Objectives
- Comprehensive testing in VMs
- Verify all components work together
- Test installation on different configurations
- Validate both live and installed experiences

#### Testing Process
- Created test checklist for all components
- Tested multiple installation scenarios
- Verified branding consistency throughout
- Checked locale and timezone settings
- Validated application functionality

#### Issues Discovered and Fixed

**Issue 1: Panel Configuration Reset**
- Symptom: Panel settings reverting after login
- Cause: Incorrect dconf database setup
- Fix: Proper dconf profile configuration
- Verification: Settings persist across sessions

**Issue 2: Wallpaper Selection Limited**
- Symptom: Only one wallpaper appearing
- Cause: Wrong directory structure
- Fix: Proper backgrounds directory organization
- Result: All wallpapers available in settings

**Issue 3: Locale Not Applying**
- Symptom: System defaulting to en_US
- Cause: Locale generation order
- Fix: Explicit locale priority in build script
- Outcome: en_CA default as intended

#### Milestone Achieved
✅ Fully functional system passing all test criteria

### Phase 9: Documentation and Polish

#### Objectives
- Comprehensive README for project overview
- Detailed build instructions
- Philosophy document explaining decisions
- Development journey (this document)

#### Documentation Created
- README.md: Project overview and quick start
- BUILDING.md: Step-by-step build instructions
- PHILOSOPHY.md: Design philosophy and lessons learned
- DEVELOPMENT.md: Chronological development journey

#### Final Polish
- Code cleanup and commenting
- Script organization
- Package metadata refinement
- Licensing clarification
- Contribution guidelines

#### Milestone Achieved
✅ Complete documentation suite for reproducibility

## Key Technical Insights

### What Worked Well

1. **Package-First Development**
   - Everything as proper .deb packages
   - Clean integration with apt system
   - Survives updates gracefully
   - Easy to maintain and debug

2. **Extending Not Replacing**
   - Building on calamares-settings-debian
   - Using Debian's existing infrastructure
   - Minimal delta from upstream
   - Future-proof against Debian changes

3. **Pre-Generated Assets**
   - All graphics created during package build
   - No runtime ImageMagick dependency
   - Faster ISO creation
   - More reliable builds

4. **Explicit Error Handling**
   - Every critical operation verified
   - Fail fast on problems
   - Comprehensive logging
   - Debuggable when issues occur

5. **Separation of Concerns**
   - Each package handles one domain
   - Clear ownership boundaries
   - Independent testing possible
   - Maintainable architecture

### What Didn't Work

1. **Excessive Live Session Customization**
   - Timing issues
   - Permission problems
   - Chroot limitations
   - Not worth the complexity

2. **Replacing Debian Packages**
   - Lost functionality
   - Maintenance burden
   - Update conflicts
   - Learned to extend instead

3. **Wildcard Dependencies**
   - Timing-dependent failures
   - Silent problems
   - Debugging nightmares
   - Explicit is better

4. **Error Suppression**
   - Masked real problems
   - ISOs looked fine but weren't
   - Wasted debugging time
   - Removed all suppression

5. **Runtime Asset Generation**
   - Extra dependencies
   - Slower builds
   - Potential failure points
   - Pre-generation better

## Development Statistics

### Time Investment
- Planning and architecture: [X hours/days]
- Package development: [X hours/days]
- Build system creation: [X hours/days]
- Testing and debugging: [X hours/days]
- Documentation: [X hours/days]
- Total: [X hours/days]

### Iteration Counts
- Full ISO rebuilds: [~X builds]
- Package rebuilds: [~X builds]
- Major refactors: [X times]
- Complete restarts: [X times (if any)]

### Code Volume
- Shell script lines: [~X lines]
- Package configuration: [~X files]
- Documentation: [~X words]

## Lessons for Future Projects

### Do This
✅ Start with solid upstream base  
✅ Package everything properly  
✅ Test incrementally  
✅ Document as you go  
✅ Embrace explicit error handling  
✅ Keep scope minimal  
✅ Learn upstream's patterns  

### Don't Do This
❌ Fight against upstream design  
❌ Suppress errors for clean logs  
❌ Try to customize everything  
❌ Use wildcards in critical paths  
❌ Skip testing phases  
❌ Assume live/installed are same  
❌ Add dependencies unnecessarily  

## Future Development Roadmap

### Planned Improvements
- [ ] Automated testing framework
- [ ] CI/CD for builds
- [ ] Alternative desktop environment options
- [ ] Enhanced Canadian content/resources
- [ ] Community feedback integration

### Not Planned
- ❌ Custom package repository
- ❌ Forking major components
- ❌ Proprietary software inclusion
- ❌ Diverging significantly from Debian

### Maintenance Strategy
- Follow Debian's release cycle
- Update packages only when needed
- Test thoroughly before releases
- Keep documentation current
- Respond to user feedback
- Stay true to minimalist principles

## Acknowledgments and Resources

### Tools and Technologies Used
- Debian GNU/Linux (foundation)
- Cinnamon Desktop (interface)
- Calamares Installer (installation)
- SquashFS Tools (filesystem compression)
- dpkg/apt (package management)
- ImageMagick (asset generation)
- Git (version control)
- VirtualBox/QEMU (testing)

### Documentation References
- Debian Policy Manual
- Calamares documentation
- Cinnamon configuration guides
- SquashFS documentation
- LightDM configuration references

### Inspiration
- Debian's commitment to stability
- Linux Mint's attention to user experience
- The broader Linux community's collaborative spirit
- Canada's bilingual and inclusive values

## Conclusion

Maple Linux Core represents a different approach to distribution creation: do less, do it well, and keep it maintainable. 

The journey from concept to completion taught valuable lessons about working with upstream, the importance of proper packaging, and the virtue of simplicity. Every failed approach made the final solution clearer. Every challenge overcome reinforced the core philosophy.

The result is a distribution that's:
- 98% pure Debian
- 2% thoughtful customization
- 100% maintainable
- Distinctly Canadian

And that's exactly what we set out to create.

---

**Development Status**: Feature complete and ready for community use  
**Last Updated**: [Date]  
**Codeberg.Org repo**: https://codeberg.org/maplelinux/maple-linux-core  
**Project Home**: https://maplelinux.ca  
**License**: GPL 3.0 or later

**Maple Linux Core**: Simple, lean, and proudly Canadian. 🍁
