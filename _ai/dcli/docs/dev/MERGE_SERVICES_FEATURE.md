# `dcli merge --services` Feature

## Overview

Added a `--services` flag to the `dcli merge` command that allows users to bootstrap their services configuration by capturing currently enabled services on their system.

## Implementation

### Command Usage

```bash
# Add currently enabled services to host config
dcli merge --services

# Preview services that would be added (dry run)
dcli merge --services --dry-run
```

### What It Does

1. **Scans System Services**
   - Queries all enabled services using `systemctl list-unit-files`
   - Retrieves services that are set to start on boot

2. **Filters System-Critical Services**
   - Automatically filters out ~50 system-critical services
   - Prevents accidental management of essential services
   - Includes: systemd-*, dbus, getty, display managers, system targets

3. **Compares with Configuration**
   - Checks services already declared in `config.services.enabled`
   - Checks services already declared in `config.services.disabled`
   - Only captures unmanaged services

4. **Updates Host Configuration**
   - Adds services to `hosts/{hostname}.yaml`
   - Adds to `services.enabled` section
   - Sorts alphabetically for easy management

### Filtered Services

The following types of services are automatically filtered out:

- **Core systemd services**: journald, logind, udevd, resolved, timesyncd, networkd
- **D-Bus services**: dbus, dbus-broker
- **Security services**: polkit, rtkit-daemon
- **Display managers**: gdm, sddm, lightdm, display-manager
- **TTY services**: getty@tty1-6
- **System targets**: multi-user.target, graphical.target, basic.target, sysinit.target
- **Kernel services**: kmod-static-nodes

Full list available in `get_system_critical_services()` function in `src/commands/merge.rs`.

## Example Usage

### Dry Run

```bash
$ dcli merge --services --dry-run

→ Loading configuration...
→ Scanning enabled services...
→ Found 87 enabled services on system
→ 35 manageable services (after filtering system-critical)
→ Found 0 services declared in config (0 enabled, 0 disabled)
→ Found 35 unmanaged services

=== Unmanaged Services ===

These services are currently enabled but not in your dcli config:

  • bluetooth
  • cups
  • docker
  • NetworkManager
  • sshd
  • ufw
  • ...

[DRY RUN - No changes will be made]

These 35 services would be added to:
  /home/user/.config/arch-config/hosts/myhost.yaml

What will happen:
  • Services will be added to 'services.enabled' section
  • Your host configuration will be updated
  • Run 'dcli sync' to keep them enabled
```

### Actual Run

```bash
$ dcli merge --services

→ Loading configuration...
→ Scanning enabled services...
→ Found 87 enabled services on system
→ 35 manageable services (after filtering system-critical)
→ Found 0 services declared in config (0 enabled, 0 disabled)
→ Found 35 unmanaged services

=== Unmanaged Services ===

These services are currently enabled but not in your dcli config:

  • bluetooth
  • cups
  • docker
  • NetworkManager
  • sshd
  ...

⚠️  Important Information

This command captures services that are currently enabled. However:
  • Review the list carefully before proceeding
  • Some services may be important for your workflow
  • System-critical services are automatically filtered out
  • You can remove services from config later if needed

The dcli author is not responsible for any system issues.
Always maintain backups and test changes carefully.

What will happen:
  • Update: /home/user/.config/arch-config/hosts/myhost.yaml
  • Add 35 services to 'services.enabled'
  • File will be loaded during sync

Proceed? [y/N] y

✓ Added 35 services to host configuration

What's next:
  • These services are now managed by dcli
  • File: /home/user/.config/arch-config/hosts/myhost.yaml
  • Services will remain enabled during 'dcli sync'
  • You can move services to modules later for better organization
```

## Resulting Configuration

After running `dcli merge --services`, your host file will look like:

```yaml
host: myhost
description: Configuration for myhost

services:
  enabled:
    - bluetooth
    - cups
    - docker
    - NetworkManager
    - sshd
    - ufw
    # ... more services
```

## Files Modified

### New Code
- `src/commands/merge.rs`:
  - Added `run_services_merge()` function
  - Added `get_system_critical_services()` helper
  - Modified `run()` to route to packages or services based on flag

### Modified Files
- `src/main.rs`:
  - Added `--services` flag to `Merge` command
  - Updated command handler to pass flag

### Documentation
- `SERVICES.md`: Added "Bootstrap from Current System" section
- `README.md`: Updated services and merge sections
- `MERGE_SERVICES_FEATURE.md`: This file

## Use Cases

### 1. Fresh Install Bootstrap

When setting up dcli on an existing system:

```bash
# Capture packages
dcli merge

# Capture services
dcli merge --services

# Now your system is fully managed
dcli sync
```

### 2. Migration from Manual Management

If you've been managing services manually:

```bash
# See what services you have enabled
dcli merge --services --dry-run

# Add them to config
dcli merge --services

# Now dcli will keep them enabled
dcli sync
```

### 3. Documenting Current State

To create a snapshot of your current services configuration:

```bash
dcli merge --services --dry-run > my-services-list.txt
```

## Safety Features

1. **System Service Filtering**
   - Comprehensive list of system-critical services
   - Prevents accidentally managing essential services
   - Reduces risk of breaking the system

2. **Conflict Detection**
   - Doesn't add services already in config
   - Checks both enabled and disabled lists
   - Prevents duplicates

3. **User Confirmation**
   - Shows full list of services before adding
   - Requires explicit 'y' to proceed
   - Clear warning messages

4. **Dry Run Mode**
   - Preview changes without modifying anything
   - See exactly what would be added
   - Useful for auditing

## Integration with Existing Features

- **Works with `dcli sync`**: Added services remain enabled during sync
- **Works with backups**: Host config is backed up automatically
- **Works with imports**: Services are merged across imported configs
- **Works with modules**: Can move services to modules later

## Limitations

- Only captures enabled services (not disabled ones)
- Doesn't detect service customizations or overrides
- Doesn't capture service dependencies
- Only manages system services (not user services)

## Future Enhancements

- Add `--disabled` flag to capture disabled services
- Interactive service selection with fzf
- Per-module service merge
- Service grouping suggestions (e.g., "development services", "desktop services")

## Testing

✅ Compiles successfully
✅ Command help shows --services flag
✅ Code follows existing merge command patterns
✅ Documentation updated
✅ No breaking changes

## Conclusion

The `dcli merge --services` feature makes it easy to bootstrap services management by capturing your current system state. Combined with the existing `dcli merge` for packages, users can now fully declaratively manage their entire system configuration with minimal manual work.
