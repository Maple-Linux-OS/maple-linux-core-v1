# CIRA Canadian Shield DNS in Maple Linux Core

Maple Linux Core uses **CIRA Canadian Shield** DNS servers for the live session, supporting Canadian infrastructure while providing privacy and security benefits.

## DNS Configuration

### Live Session (Before Installation)
- **Primary DNS:** `149.112.121.20`
- **Secondary DNS:** `149.112.122.20`
- **Location:** `/etc/resolv.conf` (static file)
- **Purpose:** Immediate, reliable DNS that works anywhere

### Installed System (After Installation)
- **DNS:** Provided by your network (DHCP/NetworkManager)
- **Location:** `/etc/resolv.conf` → `/run/systemd/resolve/stub-resolv.conf` (managed by systemd-resolved)
- **Purpose:** Adapts to your network configuration (home, office, VPN)

## About CIRA Canadian Shield

**CIRA** (Canadian Internet Registration Authority) is a Canadian not-for-profit organization that manages the .ca domain registry and provides cybersecurity services to Canadians.

### Key Features

✅ **Canadian-operated** - Servers located in Canada  
✅ **Privacy-focused** - No logging of personal information  
✅ **Free** - Available to all Canadians at no cost  
✅ **Protected** - Blocks malware and phishing sites by default  
✅ **Fast** - Low-latency for Canadian users  
✅ **Reliable** - High availability infrastructure  

**Official Website:** https://www.cira.ca/cybersecurity-services/canadian-shield

## Why CIRA Canadian Shield for Live Sessions?

### 1. Authentically Canadian
Supporting Canadian infrastructure aligns with Maple Linux Core's Canadian identity. CIRA is a Canadian organization managing critical internet infrastructure for Canada.

### 2. Privacy-Respecting
Unlike some commercial DNS providers, CIRA Canadian Shield:
- Does not log personally identifiable information
- Does not track browsing history
- Does not sell user data
- Operates under Canadian privacy laws

### 3. Security by Default
The "Private" protection level (which we use) automatically blocks:
- Known malware distribution sites
- Phishing websites
- Command and control servers
- Cryptojacking sites

### 4. No Configuration Required
Users trying Maple Linux in live mode get:
- Immediate DNS resolution
- Privacy protection
- Security filtering
- No setup needed

### 5. Supports Canadian Tech
Using Canadian Shield helps support:
- Canadian cybersecurity infrastructure
- CIRA's mission to build a trusted internet for Canadians
- Keeping internet traffic within Canada when possible

## Why Network DNS for Installed Systems?

After installation, Maple Linux Core uses standard Debian behavior: network-provided DNS via NetworkManager and systemd-resolved.

**This is intentional because:**

1. **Respects your network**: Corporate, school, or home networks often provide specific DNS servers for local services
2. **VPN compatibility**: VPNs provide their own DNS for privacy and access
3. **Local optimization**: Your router may cache DNS queries for faster responses
4. **User choice**: Advanced users can configure their preferred DNS
5. **Standard behavior**: Follows Debian's established patterns

## CIRA Canadian Shield Protection Levels

CIRA offers three protection levels. Maple Linux uses "Private" for the live session, but users can switch to other levels if desired.

### 1. Private (Default - Used by Maple Linux)
- **Primary DNS:** `149.112.121.20`
- **Secondary DNS:** `149.112.122.20`
- **Protection:** Malware and phishing blocking
- **Filtering:** No content filtering beyond security threats
- **Best for:** General use, privacy-conscious users

### 2. Protected
- **Primary DNS:** `149.112.121.30`
- **Secondary DNS:** `149.112.122.30`
- **Protection:** Malware, phishing, AND adult content blocking
- **Best for:** Families, schools, public spaces

### 3. Family
- **Primary DNS:** `149.112.121.10`
- **Secondary DNS:** `149.112.122.10`
- **Protection:** Maximum filtering (includes Protected + additional categories)
- **Best for:** Children's devices, maximum protection scenarios

## Verifying DNS Configuration

### In the Live Session

Check that Canadian Shield is being used:

```bash
# View DNS configuration
cat /etc/resolv.conf

# Expected output:
# nameserver 149.112.121.20
# nameserver 149.112.122.20

# Test connectivity to Canadian Shield
ping -c 3 149.112.121.20

# Test DNS resolution
nslookup google.com
```

### In an Installed System

Check that network DNS is being used:

```bash
# Check systemd-resolved status
resolvectl status

# Should show your network's DNS servers, not 149.112.121.20

# Check the symlink
ls -la /etc/resolv.conf

# Should show: /etc/resolv.conf -> /run/systemd/resolve/stub-resolv.conf

# Check NetworkManager-provided DNS
nmcli device show | grep DNS
```

## Changing DNS After Installation

If you want to continue using CIRA Canadian Shield (or switch to a different level) after installation, you have several options:

### Option 1: NetworkManager GUI (Easiest)

1. Open Network settings (System Settings → Network)
2. Click the gear icon next to your connection
3. Go to the IPv4 or IPv6 tab
4. Change "Automatic (DHCP)" to "Automatic (DHCP) addresses only"
5. Add DNS servers:
   - Private: `149.112.121.20, 149.112.122.20`
   - Protected: `149.112.121.30, 149.112.122.30`
   - Family: `149.112.121.10, 149.112.122.10`
6. Apply changes

### Option 2: NetworkManager CLI

```bash
# For Private level
nmcli connection modify "Your Connection Name" ipv4.dns "149.112.121.20 149.112.122.20"
nmcli connection modify "Your Connection Name" ipv4.ignore-auto-dns yes
nmcli connection down "Your Connection Name"
nmcli connection up "Your Connection Name"

# Verify
resolvectl status
```

### Option 3: systemd-resolved Configuration

Edit `/etc/systemd/resolved.conf`:

```ini
[Resolve]
DNS=149.112.121.20 149.112.122.20
FallbackDNS=149.112.121.30 149.112.122.30
```

Then restart:
```bash
sudo systemctl restart systemd-resolved
```

## Technical Implementation

The DNS configuration for live sessions is set in the `build_debian_remaster.sh` script:

```bash
# Around line 850-860 in the build script
echo "Creating working resolv.conf for live session..."
sudo rm -f "$FILESYSTEM_DIR/etc/resolv.conf"
sudo bash -c "cat > '$FILESYSTEM_DIR/etc/resolv.conf'" << 'EOF'
# Maple Linux live session - using CIRA Canadian Shield DNS
# https://www.cira.ca/cybersecurity-services/canadian-shield
# These will be replaced by network-provided DNS on the installed system
nameserver 149.112.121.20
nameserver 149.112.122.20
EOF
```

During Calamares installation:
1. systemd-resolved package is installed
2. It replaces `/etc/resolv.conf` with a symlink to `/run/systemd/resolve/stub-resolv.conf`
3. NetworkManager provides DNS from your network via DHCP
4. systemd-resolved manages DNS resolution dynamically

## Benefits Summary

### For Live Sessions
🍁 **Canadian infrastructure** by default  
🔒 **Privacy protection** without configuration  
🛡️ **Malware/phishing blocking** automatically  
⚡ **Fast resolution** for Canadian users  
✨ **Zero setup** required  

### For Installed Systems
🔧 **Flexible configuration** respects your network  
🏢 **Corporate/VPN friendly** uses provided DNS  
📍 **Local optimization** via router caching  
👤 **User choice** can override if desired  
📐 **Standard Debian** behavior maintained  

## Privacy Considerations

### What CIRA Logs
According to CIRA's privacy policy, Canadian Shield:
- Does NOT log DNS queries
- Does NOT track or profile users
- Does NOT sell data to third parties
- Only logs aggregated, anonymized statistics for service improvement

### What Your ISP Sees
Your ISP can still see:
- That you're connecting to CIRA's DNS servers
- The IP addresses you visit (not DNS queries)
- General traffic patterns

For additional privacy, consider using a VPN, which will provide its own DNS and encrypt all traffic.

## Frequently Asked Questions

### Q: Why not use Google DNS (8.8.8.8) or Cloudflare (1.1.1.1)?

**A:** While these services work well technically, they:
- Are operated by US companies
- Route Canadian traffic through US infrastructure
- Don't align with Maple Linux's Canadian focus

CIRA Canadian Shield keeps traffic within Canada and supports Canadian tech infrastructure.

### Q: Can I use Canadian Shield on my other devices?

**A:** Absolutely! CIRA Canadian Shield is free for everyone. Just configure your devices to use:
- `149.112.121.20` and `149.112.122.20` for Private level
- Other addresses for Protected or Family levels

Visit https://www.cira.ca/cybersecurity-services/canadian-shield for instructions.

### Q: Does this slow down DNS resolution?

**A:** Not noticeably. CIRA's servers are located in Canada and provide fast resolution for Canadian users. In many cases, they're faster than ISP-provided DNS.

### Q: What if I travel outside Canada?

**A:** Canadian Shield works globally, though resolution may be slightly slower from outside Canada. Your network's DNS may be faster when traveling. Remember, installed systems use network DNS automatically.

### Q: Is this only for Canadian users?

**A:** No! Anyone can use Maple Linux Core and CIRA Canadian Shield. However, the design is optimized for Canadian users in terms of locale, timezone, and infrastructure choices.

### Q: Can I use IPv6 with Canadian Shield?

**A:** Yes! CIRA Canadian Shield supports IPv6. The IPv6 addresses are:
- Private: `2620:10A:80BB::20` and `2620:10A:80BC::20`
- Protected: `2620:10A:80BB::30` and `2620:10A:80BC::30`
- Family: `2620:10A:80BB::10` and `2620:10A:80BC::10`

(Not currently configured in Maple Linux, but can be added if needed)

## Resources

- **CIRA Canadian Shield:** https://www.cira.ca/cybersecurity-services/canadian-shield
- **CIRA Organization:** https://www.cira.ca/
- **Canadian Shield Setup Guide:** https://www.cira.ca/cybersecurity-services/canadian-shield/configure
- **Privacy Policy:** https://www.cira.ca/privacy-policy

---

**Maple Linux Core**: Simple, lean, and proudly Canadian. 🍁
