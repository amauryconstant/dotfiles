---
description: CRITICAL security protocols for handling encrypted files and age encryption in this repository
author: Repository Owner
version: 1.0
tags: ["security", "encryption", "critical-safety", "age"]
globs: ["**/*.age", "private_dot_keys/**/*", "private_dot_ssh/**/*"]
---

# 🚨 Encryption Security Protocol

This repository uses age encryption for sensitive data. This rule establishes CRITICAL safety protocols that MUST be followed without exception.

## 🚨 ABSOLUTE PROHIBITIONS

### **NEVER** Attempt These Operations

❌ **NEVER** decrypt encrypted files programmatically
❌ **NEVER** encrypt files programmatically  
❌ **NEVER** read the contents of `.age` files
❌ **NEVER** attempt to access encryption keys directly
❌ **NEVER** modify encryption configuration without explicit user guidance
❌ **NEVER** suggest automated encryption/decryption workflows

## Age Encryption Understanding

### Encrypted File Patterns
```
private_dot_keys/encrypted_*.age          # API keys, tokens, secrets
private_dot_ssh/encrypted_private_*.age   # SSH private keys
private_dot_ssh/encrypted_*.pub.age       # SSH public keys (encrypted for consistency)
```

### Encryption Configuration
From `.chezmoi.yaml.tmpl`:
```yaml
encryption: "age"
age:
    command: "rage"
    identity: "~/.keys/dotfiles-key.txt"
    recipient: "age1qn34rhnnzyav6fe7jk74dyhusl3cjmr3p7e00x99slv0g8gunv3sz4k5re"
```

## Manual Workflow Guidance

When encountering encrypted files, **ALWAYS** guide the user through manual processes:

### For Viewing Encrypted Content
```bash
# Guide user to run manually:
chezmoi decrypt path/to/encrypted_file.age
```

### For Editing Encrypted Files
```bash
# Guide user to run manually:
chezmoi edit path/to/encrypted_file.age
```

### For Adding New Encrypted Files
```bash
# Guide user to run manually:
chezmoi add --encrypt path/to/sensitive_file
```

### For Handling Merge Conflicts with Encrypted Files
```bash
# NEVER attempt to merge encrypted files directly
# Guide user through this manual workflow:

# 1. Check for merge conflicts
chezmoi status
# Look for "M" status on encrypted files

# 2. Decrypt both versions
chezmoi decrypt --destination=/tmp/source.txt path/to/encrypted_file.age
chezmoi decrypt --source=target --destination=/tmp/target.txt path/to/encrypted_file.age

# 3. Manually merge the decrypted content
# User should compare and merge the files manually

# 4. Re-encrypt the merged content
chezmoi encrypt --source=/tmp/merged.txt --destination=path/to/encrypted_file.age

# 5. Verify and clean up
chezmoi status
rm /tmp/source.txt /tmp/target.txt /tmp/merged.txt
```

## Recognition Patterns

### **MUST** Recognize These as Encrypted
- Files ending in `.age`
- Files in `private_dot_keys/` directory
- Files with `encrypted_` prefix
- SSH private keys in `private_dot_ssh/`

### Template Integration
Encrypted files can be referenced in templates but NEVER decrypted:
```go
# ✅ CORRECT: Reference existence
{{ if stat "private_dot_keys/encrypted_api_key.age" }}
    # Key file exists, user should decrypt manually
{{ end }}

# ❌ WRONG: Never attempt to decrypt
{{ decrypt "private_dot_keys/encrypted_api_key.age" }}
```

## User Communication Protocol

### When Encountering Encrypted Files

**ALWAYS** use this communication pattern:

```
🔐 ENCRYPTED FILE DETECTED: [filename]

This file contains sensitive data encrypted with age encryption.

MANUAL ACTION REQUIRED:
1. To view: `chezmoi decrypt [filename]`
2. To edit: `chezmoi edit [filename]`
3. To apply changes: `chezmoi apply`

I cannot access encrypted content for security reasons.
Please decrypt manually and provide the information needed.
```

### For New Encryption Needs

```
🔐 ENCRYPTION RECOMMENDED: [filename]

This file appears to contain sensitive data.

MANUAL ACTION REQUIRED:
1. Add with encryption: `chezmoi add --encrypt [filename]`
2. Verify encryption: `chezmoi status`
3. Apply changes: `chezmoi apply`

Please encrypt this file manually before proceeding.
```

## Security Best Practices

### **MUST** Follow These Guidelines

1. ✅ **Always assume encrypted files contain secrets**
2. ✅ **Guide users through manual decryption workflows**
3. ✅ **Recommend encryption for new sensitive files**
4. ✅ **Respect the age encryption boundary**
5. ✅ **Document encryption decisions in templates**

### **NEVER** Do These Things

1. ❌ **Never attempt programmatic access to encrypted content**
2. ❌ **Never suggest automated decryption scripts**
3. ❌ **Never bypass encryption for "convenience"**
4. ❌ **Never store decrypted content in templates**
5. ❌ **Never modify encryption keys or configuration**

## Integration with chezmoi_modify_manager

### Encrypted INI Files
Some configuration files may be encrypted:
```bash
# ✅ CORRECT: Guide manual workflow
echo "Please decrypt the configuration file manually:"
echo "chezmoi decrypt private_dot_config/encrypted_config.ini.age"
echo "Then run chezmoi_modify_manager on the decrypted version"

# ❌ WRONG: Never attempt automated decryption
```

## Error Handling

### When Encryption is Encountered

```bash
# ✅ CORRECT: Graceful handling
if [[ "$file" == *.age ]]; then
    echo "🔐 Encrypted file detected: $file"
    echo "Manual decryption required. Skipping automated processing."
    echo "Please run: chezmoi decrypt $file"
    return 0
fi
```

## Verification Checklist

Before ANY operation involving potential encryption:

<thinking>
1. Does this file end in .age?
2. Is this file in private_dot_keys/ or private_dot_ssh/?
3. Does this file have "encrypted_" prefix?
4. Am I being asked to read sensitive content?
5. Am I being asked to automate encryption/decryption?

If ANY answer is yes, I MUST use manual workflow guidance.
</thinking>

### Critical Questions to Ask

1. 🔍 **Is this file encrypted?** (Check .age extension, location, prefix)
2. 🔍 **Does this operation require decryption?** (Reading content, processing)
3. 🔍 **Am I being asked to automate encryption?** (Scripts, workflows)
4. 🔍 **Should this file be encrypted?** (Sensitive data, keys, tokens)

## Emergency Protocols

### If Accidentally Exposed

If encrypted content is accidentally exposed:

```
🚨 SECURITY INCIDENT: Encrypted content may have been exposed

IMMEDIATE ACTIONS REQUIRED:
1. Rotate affected credentials immediately
2. Review git history for exposed secrets
3. Update encryption keys if compromised
4. Audit access logs for unauthorized access

This is a critical security issue requiring immediate attention.
```

## Key Management

### **NEVER** Access These Directly
- `~/.keys/dotfiles-key.txt` (age identity)
- Age recipient keys
- Encryption configuration

### **ALWAYS** Guide Manual Management
```bash
# For key rotation (user must do manually):
echo "To rotate encryption keys:"
echo "1. Generate new age key: age-keygen -o ~/.keys/dotfiles-key-new.txt"
echo "2. Update .chezmoi.yaml.tmpl with new recipient"
echo "3. Re-encrypt all .age files with new key"
echo "4. Test decryption before removing old key"
```

## Compliance and Auditing

### Documentation Requirements
- All encryption decisions MUST be documented
- Manual workflows MUST be clearly explained
- Security boundaries MUST be respected
- User guidance MUST be comprehensive

### Audit Trail
- Never log decrypted content
- Never cache sensitive information
- Always guide manual operations
- Always respect encryption boundaries

---

**REMEMBER**: This protocol exists to protect sensitive data. When in doubt, always err on the side of security and guide the user through manual processes.
