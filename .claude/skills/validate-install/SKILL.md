---
name: validate-install
description: Pre-apply safety check for chezmoi dotfiles - validates templates, scripts, packages, and configs before applying. Use when about to run 'chezmoi apply' or when user wants to validate dotfiles changes.
allowed-tools: Bash, Read, Grep, Glob
---

# Validate Install

Comprehensive validation before `chezmoi apply` to prevent broken sessions.

## When to Use

- User is about to run `chezmoi apply`
- User asks "is it safe to apply?"
- User wants to validate dotfiles changes
- User mentions validation, checking, or testing dotfiles

## Execution Steps

1. **Run validation script**
   ```bash
   bash ~/.local/share/chezmoi/.claude/skills/validate-install/scripts/validate-dotfiles.sh
   ```

2. **Parse JSON output**
   - Exit code: 0 = pass, non-zero = fail
   - JSON format: `{summary: {total, passed, failed, warnings}, checks: [...]}`

3. **Interpret results**

   For each failed check, provide:
   - Root cause explanation
   - Specific fix command
   - Reference to relevant CLAUDE.md section

   **Common remediation patterns**:
   - Template errors → Check `chezmoi data | jaq '.variableName'`
   - Shellcheck errors → Fix specific SC codes
   - Package conflicts → Show conflicting modules
   - Driver issues → Explain NVIDIA detection logic

4. **Present results**

   **All checks pass**:
   ```
   ✅ All validation checks passed (8/8)

   Safe to apply:
     chezmoi apply
   ```

   **Some checks fail**:
   ```
   ❌ Validation failed (6/8 checks passed)

   Critical Issues:
   [Interpreted error with fix command]

   Warnings:
   [Interpreted warning]

   Fix these issues before running:
     chezmoi apply
   ```

5. **Offer next actions**
   - View detailed diff: `chezmoi diff`
   - Fix specific file: `chezmoi edit <file>`
   - Re-run validation: `/validate-install`
   - Force apply (with warning): `chezmoi apply --force`

## Validation Checks (8)

1. Merge conflicts (`chezmoi status`)
2. Template syntax (`chezmoi execute-template`)
3. Shellcheck validation (scripts + rendered templates)
4. packages.yaml syntax (`yq eval`)
5. Package module conflicts (`package-manager validate`)
6. Hyprland config syntax (if changed)
7. NVIDIA driver compatibility (if changed)
8. Dry-run chezmoi apply

## Error Categorization

- **Critical**: Blocks apply (template errors, shellcheck errors, merge conflicts)
- **Warning**: Degrades functionality (missing packages, driver mismatches)
- **Info**: Best practices (outdated patterns, performance tips)
