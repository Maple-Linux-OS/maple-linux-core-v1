# The Philosophy of Maple Linux Core

## Why Another Linux Distribution?

This is a fair question. There are hundreds of Linux distributions, many based on Debian, and several with Cinnamon desktop. What justifies another one?

The answer isn't about creating something radically different. It's about creating something **radically maintainable**.

## Our Minimalist Approach

### Core Principle: Change as Little as Possible

The foundation of Maple Linux Core is simple: **take Debian and change only what you must**. This isn't laziness—it's wisdom earned from decades of watching distributions struggle with maintenance burden.

Every customization is a commitment. Every modification is technical debt. Every override is a potential conflict waiting to happen when upstream updates.

So we ask of every change: "Is this worth maintaining forever?"

### What We Changed (and Why)

**We changed**:
- Installer branding (first impression matters)
- Desktop defaults (save users configuration time)
- Login screen appearance (cohesive experience)
- Boot menu text (professional touch)
- Application selection (sensible Canadian defaults)
- Locale priorities (English/French Canadian)
- Live session DNS (CIRA Canadian Shield for privacy and Canadian infrastructure)

**We did NOT change**:
- System architecture
- Package management
- Update mechanisms
- Core system utilities
- Network configuration
- Security policies
- File system layout

This distinction is crucial. We customize the **experience layer** while leaving the **system layer** pure Debian.

## Lessons from the Field

### 30+ Years of Linux: What We Learned

**Lesson 1: Upstream Knows Best (Usually)**

Debian's design decisions come from thousands of developer-hours and millions of user-installations. When you think you've found a "better way," you're probably wrong. Or you're trading one set of problems for another set you don't know about yet.

Example: We initially tried to override Debian's calamares-settings-debian package completely. This led to conflicts, missing features, and breakage on updates. The solution? Extend it, don't replace it. Work with the grain, not against it.

**Lesson 2: The Live/Installed Dichotomy**

Live sessions and installed systems are fundamentally different environments:

- Live sessions run as a pre-configured user in a read-mostly filesystem
- Installed systems create new users with fresh home directories
- Live sessions need to be fast and functional
- Installed systems need to be complete and customizable

We spent significant time trying to make live sessions look "perfect" before realizing: users spend 15 minutes in live mode and years in installed mode. Optimize for the long-term experience.

**Lesson 3: Packages Are Not Optional**

Direct file modifications are tempting. Copy a file here, edit a config there. Quick, easy, done.

Also unmaintainable, fragile, and hostile to updates.

Everything must be packaged. Yes, it's more work upfront. Yes, you need to learn debian/rules syntax. But proper packages:
- Integrate with apt's dependency resolution
- Handle conflicts gracefully
- Can be upgraded or removed cleanly
- Document their own dependencies
- Work with Debian's policies

The alternative is a house of cards that collapses on the first major update.

**Lesson 4: Error Suppression is Evil**

Early build scripts had lines like:
```bash
some_command 2>/dev/null || true
```

This hides failures. Builds succeed. ISOs boot. Everything looks fine.

Except your customization didn't actually apply. The package installation failed silently. The configuration never took effect.

Better to fail loudly and fix the root cause than succeed quietly with a broken result.

**Lesson 5: Wildcards Are Dangerous**

```bash
# WRONG - might be empty if evaluated too early
PACKAGE=$(ls packages/maple-*.deb)

# RIGHT - explicit, verifiable
PACKAGE="packages/maple-calamares-branding_1.0-1_all.deb"
```

Implicit behavior leads to mysterious failures. Explicit code is maintainable code.

## Design Decisions

### Why ISO Remastering?

We could build from scratch using debootstrap, live-build, or similar tools. Many distributions do this.

We chose remastering because:

1. **Debian's ISO already works**: Why rebuild what's proven?
2. **Minimal delta**: We want to change little, remastering reflects that
3. **Update simplicity**: New Debian release? Use their new ISO
4. **Reduced maintenance**: We maintain changes, not the entire base system
5. **Trust**: Users can verify our ISO is based on official Debian

The tradeoff is less flexibility in base system composition. We accept this tradeoff gladly.

### Why Debian and Not Ubuntu/Mint?

**Debian** because:
- Upstream of Ubuntu (fewer layers to debug)
- Predictable release cycle
- True community project
- Stable without stagnation
- Excellent package management
- Strong security track record

**Not Ubuntu** because:
- Ubuntu is already Debian + changes (we'd be modifying modifications)
- Snaps add complexity we don't want
- Corporate considerations can affect decisions
- More frequent updates = more maintenance

**Not Mint** because:
- We'd be forking a fork of a fork (Mint → Ubuntu → Debian)
- Much harder to stay current with upstream changes
- Mint's customizations conflict with our minimalist approach

### Why Cinnamon?

Cinnamon offers:
- Familiar paradigm (taskbar, menu, system tray)
- Good performance on modest hardware
- Rich customization options
- Active development
- Works well with Debian's stability

We're not married to Cinnamon, but it suits our current needs well.

### Why Calamares?

Debian's default installer works but shows its age. Calamares provides:
- Modern, graphical interface
- Easy customization
- Good hardware detection
- Active development
- Used by many distributions (proven)

Most importantly: Debian already ships calamares-settings-debian, giving us a solid foundation to extend.

### Package Architecture

Each package handles one domain:

**maple-calamares-branding**: Installer appearance
- Red color scheme
- Maple logos
- Slide deck content
- Welcome text

**maple-cinnamon-settings**: Desktop defaults
- Wallpapers
- Theme selection
- Panel configuration
- Default applications
- Applies only to new users

**maple-lightdm-userlist**: Login screen
- Background image
- User list visibility
- Theme integration

**maple-grub-text**: Boot menu
- Text-only branding (no graphics)
- Maintains GRUB functionality
- Simple, maintainable

This separation means:
- Clear ownership of each component
- Easy to update individual pieces
- Simple to test in isolation
- Straightforward dependency management

### The ImageMagick Elimination

Initial approach: Generate graphics at build time using ImageMagick.

Problems:
- Added build dependencies
- Increased ISO creation time
- Potential failure point
- Unnecessary complexity

Solution: Pre-generate all assets during package creation, bundle as static files.

Benefits:
- Simpler builds
- Fewer dependencies
- Faster ISO creation
- More reliable

This exemplifies our philosophy: do work once during development, not repeatedly during every build.

## What We Failed At (And What We Learned)

### Failed Attempt 1: Live Session Perfection

**What we tried**: Make the live session look exactly like the installed system with all branding, settings, and configurations.

**What happened**: Constant struggles with timing issues, chroot limitations, permission problems. Some settings wouldn't apply, others would conflict with the live user's environment.

**What we learned**: The live session is temporary infrastructure. Make it functional and presentable, but don't obsess. Focus on the installed system experience.

**Result**: Minimal live session customization, full installed system customization. Much simpler, much more reliable.

### Failed Attempt 2: Complete Calamares Replacement

**What we tried**: Create our own calamares-settings package replacing Debian's entirely.

**What happened**: Missing features, broken functionality, conflicts with Calamares updates. We were maintaining Debian's settings ourselves.

**What we learned**: Extending is better than replacing. Debian's package handles the hard parts (hardware detection, partition management, bootloader installation).

**Result**: maple-calamares-branding extends calamares-settings-debian, keeping all functionality while adding our appearance layer.

### Failed Attempt 3: Wildcards in Build Scripts

**What we tried**: 
```bash
PACKAGES=$(ls packages/maple-*.deb)
for pkg in $PACKAGES; do
    # install
done
```

**What happened**: Sometimes worked, sometimes failed mysteriously. When evaluated before packages were built, $PACKAGES was empty. No error, just silently skipped installation.

**What we learned**: Explicit > Implicit. Debugging implicit failures wastes hours.

**Result**: All package names explicitly listed in array with verification before use.

### Failed Attempt 4: Error Suppression for "Cleaner" Logs

**What we tried**: Redirect errors to /dev/null to keep build logs clean.

**What happened**: Built ISOs missing customizations. Packages failed to install silently. Configurations never applied.

**What we learned**: Visible errors are features, not bugs. Silent failures are the enemy.

**Result**: Explicit error checking, comprehensive logging, fail-fast approach.

## The Canadian Focus

### The Canadian Focus

### Why Canadian-Specific?

Canada represents an interesting use case:
- Officially bilingual (English/French)
- Distinct timezone considerations
- Unique cultural identity
- Often overlooked by US-centric distributions

But more importantly: **specificity is useful**. A distribution trying to be everything to everyone ends up optimized for no one.

By targeting Canadian users explicitly, we can make opinionated decisions about:
- Default locales and language packs
- Timezone settings
- Keyboard layouts
- Visual identity

Users elsewhere can still use Maple Linux Core, but we're not contorting the design to accommodate every possible scenario.

### The Maple Leaf

The maple leaf branding serves multiple purposes:

1. **Identity**: Immediately recognizable Canadian symbol
2. **Cohesion**: Consistent visual theme throughout
3. **Professionalism**: Polished appearance vs. default Debian
4. **Pride**: Unapologetically Canadian

The red color scheme reinforces this identity while providing good contrast and readability.

### Canadian Infrastructure: DNS Choice

A small but meaningful decision: the live session uses CIRA Canadian Shield DNS servers (149.112.121.20 and 149.112.122.20) rather than Google's DNS or other international providers.

**Why this matters**:

1. **Authentically Canadian**: CIRA (Canadian Internet Registration Authority) is a Canadian not-for-profit organization that manages the .ca domain
2. **Privacy-focused**: No logging of personal information, unlike some commercial DNS providers
3. **Security by default**: Blocks malware and phishing sites automatically
4. **Supports Canadian infrastructure**: Keeps traffic and infrastructure within Canada when possible
5. **Aligned with values**: Privacy, security, and Canadian sovereignty

**Why only for live sessions?**

The installed system uses network-provided DNS (via DHCP/NetworkManager) because:
- Respects your network configuration (home, office, school, VPN)
- Adapts to local infrastructure automatically
- Follows standard Debian behavior
- Allows users to choose their preferred DNS

But for the live session, where users are trying out Maple Linux, using Canadian Shield provides:
- Immediate privacy protection
- Support for Canadian tech infrastructure
- A demonstration of Canadian-first thinking
- No configuration required

This is a small touch, but it reinforces that Maple Linux Core is proudly Canadian from the DNS resolver up through the desktop environment.

## Philosophy in Practice

### Adding a New Feature: The Decision Process

When considering a new feature or customization:

1. **Is it necessary?** What problem does this solve?
2. **Can Debian already do this?** Are we reinventing the wheel?
3. **What's the maintenance cost?** Will this break on updates?
4. **Does it align with our minimalism?** Or are we feature-creeping?
5. **Can it be packaged properly?** If not, we probably shouldn't do it.
6. **Will users notice?** Is this valuable or just different?

If the answer to most of these questions is positive, proceed carefully. If not, perhaps the feature isn't worth it.

### Saying No

A key part of maintaining a minimalist distribution is saying no. No to:
- Feature requests that don't serve the core vision
- Customizations that increase maintenance burden
- Changes that diverge significantly from Debian
- Solutions that are clever but fragile
- Complexity for complexity's sake

Every "no" keeps the project maintainable. Every "yes" is a commitment.

### When to Say Yes

Say yes when:
- It improves the user experience significantly
- It's maintainable with reasonable effort
- It aligns with the Canadian focus
- It can be implemented cleanly with Debian's tools
- It's worth maintaining across future Debian releases

## Looking Forward

### Maintaining Across Debian Releases

Debian 14 will come eventually. Then 15. Our approach should make updates straightforward:

1. Download new Debian ISO
2. Test our build script with new ISO
3. Update package dependencies if needed (usually not)
4. Verify customizations still work (usually do)
5. Release new Maple Linux Core version

If we've held to our principles, this should be a day's work, not months of porting.

### Potential Future Additions

We might consider:
- Additional desktop environment options (XFCE, MATE)
- Server variant (minimal installation)
- Raspberry Pi support (if Debian adds official support)
- Additional Canadian-specific applications or services

We probably won't:
- Create our own package repository (use Debian's)
- Fork major components (too much maintenance)
- Develop custom system tools (Debian's work fine)
- Add proprietary software (conflicts with Debian's principles)

### The Goal

The goal isn't to become a major distribution with thousands of users and corporate backing. The goal is to create something:

- **Maintainable** by one or two people long-term
- **Useful** for Canadian Linux users
- **Stable** across Debian's release cycle
- **Simple** enough to understand completely
- **Professional** in appearance and behavior

If Maple Linux Core achieves this, it's a success regardless of market share.

## Final Thoughts

### For Other Distribution Creators

If you're considering creating your own distribution:

**Ask yourself**: Why not contribute to an existing distribution instead?

If you still want to proceed:

1. Start with a solid base (Debian, Ubuntu, Fedora)
2. Change as little as possible
3. Package everything properly
4. Document your changes
5. Test thoroughly
6. Be prepared for long-term maintenance
7. Remember: you're committing to maintain this for years

### For Users

If you're trying Maple Linux Core:

Remember this is essentially Debian with a fresh coat of paint and some sensible defaults. If something breaks:

1. Check if it's our customization or Debian itself
2. Report Debian bugs to Debian
3. Report Maple-specific issues to us
4. You can always remove our packages and have pure Debian

You're not locked in. You're getting Debian with a nicer out-of-box experience.

### For Us (The Project)

Stay true to the principles:

- Minimal changes
- Proper packaging
- Close to upstream
- Maintainability first
- User experience second
- Feature count distant third

When in doubt, do less. When tempted to add something, resist. When Debian updates, follow.

Keep it simple. Keep it lean. Keep it Canadian.

---

**Maple Linux Core**: Simple, lean, and proudly Canadian. 🍁
