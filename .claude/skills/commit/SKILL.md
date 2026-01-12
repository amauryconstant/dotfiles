---
name: commit
description: Write concise classical commit messages with imperative mood, ≤50 char subjects. Use when creating commits or user asks for commit help.
allowed-tools: Bash, Read, Grep
---

# Commit Skill

Generate concise commit messages following repository conventions.

## When to Use

- User wants to create a commit
- User asks "write a commit message"
- User mentions committing changes
- User asks for help with git commit
- User runs `/commit`

## Execution Steps

### 1. Analyze current changes

Run in parallel to understand the full scope:

```bash
# View all changes (staged + unstaged)
git diff HEAD

# Check status
git status

# View recent commits for style
git log --oneline -20
```

### 2. Check for blockers and commit strategy

Verify the repository is ready for commit:

- **No changes** → Warn "nothing to commit"
- **Merge conflict** → Warn "resolve conflicts first" (git status shows "both modified")
- **Only untracked** → Suggest `git add <files>`
- **Nothing staged** → Suggest staging changes first

**Assess if changes should be split**:
- **Unrelated changes** → Suggest splitting into multiple commits (`git add -p`)
- **Multiple features/fixes** → Each should be its own commit
- **Mixed refactor + feature** → Separate commits
- **Single logical change** → One commit (even if multiple files)

### 3. Review changed files (if context needed)

If changes are unclear from the diff:
- Read modified files to understand context
- Ask user about reasoning behind changes
- Understand the "why" not just the "what"

Example questions:
- "What prompted this refactoring?"
- "What bug does this fix?"
- "What's the purpose of this new feature?"

### 4. Classify change type

Determine the primary verb from the diff:

| Verb | Use When | Indicators |
|------|----------|------------|
| **Add** | New files, features, functionality | New files, new functions, new capabilities |
| **Fix** | Bug corrections, error fixes | Bug fixes, error handling, corrections |
| **Update** | Enhancements to existing features | Modified existing code, improvements |
| **Refactor** | Code restructure (no behavior change) | File moves, renames, reorganization |
| **Remove** | Deletions | Deleted files, removed code |
| **Document** | Docs only | README, comments, docs changes only |

### 5. Draft commit message

**Subject line** (≤50 characters):
- Start with verb: Add, Fix, Update, Refactor, Remove, Document
- Use imperative mood (NOT Added, Fixed, Updated)
- Capitalize first word
- No period at end
- Focus on **what** changed at high level

**Body** (for complex changes):
- Blank line after subject
- Use bullet points with "- " prefix
- Explain **why** the change was made (diff shows what)
- Keep reasonably short but descriptive
- Each bullet should be a single line (≤72 chars)
- Wrap lines at 72 characters

**When to add body**:
- Complex changes requiring context
- Non-obvious reasoning behind the change
- Breaking changes (use BREAKING CHANGE footer)
- Multiple related subsystems affected
- Important impact or implications

**When to skip body**:
- Simple, self-explanatory changes
- Trivial updates
- Single obvious fix or addition

**When description gets long**:
- **Consider splitting into multiple commits** instead
- Each commit should be a focused, logical unit
- Unrelated changes belong in separate commits

### 6. Validate against repository patterns

Check that the message matches existing style:

```bash
git log --oneline -20
```

**This repository's conventions**:
- ✓ Imperative mood (Add, Fix, Update, Refactor)
- ✓ Capitalized first word
- ✓ Concise subjects (usually <50 chars)
- ✓ No periods at end
- ✓ No AI/automation mentions
- ✓ Focus on changes, not implementation details

**Good examples from this repo**:
```
Add Claude skills for package management, script creation, and validation
Refactor omarchy-changes to simplified command
Fix package-manager duplicate detection and output formatting
Separate theme state from settings using modify scripts
```

### 7. Present commit message

Format the presentation clearly:

```
Proposed commit message:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Subject line]

[Body if complex - with bullets]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Subject: XX/50 characters

Would you like me to:
1. Commit with this message
2. Let you commit manually
3. Revise the message
```

### 8. Execute commit (if approved)

**CRITICAL**: Use HEREDOC for proper formatting (from CLAUDE.md):

```bash
git commit -m "$(cat <<'EOF'
[Subject line]

[Body if present with bullets]
EOF
)"
```

**Why HEREDOC?**
- Preserves multi-line formatting
- Handles special characters correctly
- Prevents quote escaping issues

After committing, verify:
```bash
git log -1 --oneline
git show --stat
```

## Commit Message Format

### Simple commits
```
Add wallpaper rotation system
```

### Complex commits
```
Add user authentication system

- Implement JWT-based login/logout for secure sessions
- Add bcrypt password hashing for security compliance
- Update protected routes to require authentication
```

## Classification Guide

| Verb | Use When | Example |
|------|----------|---------|
| Add | New feature, file, functionality | Add theme switching system |
| Fix | Bug fix, correction | Fix wallpaper path resolution |
| Update | Enhance existing feature | Update package manager output |
| Refactor | Code restructure, no behavior change | Refactor keybindings to modules |
| Remove | Delete feature, file, code | Remove deprecated config |
| Document | Documentation only | Document skill architecture |

## Anti-Patterns

**Subject line**:
❌ **Past tense**: "Added feature", "Fixed bug"
❌ **Present continuous**: "Adding feature", "Fixing bug"
❌ **Lowercase**: "add feature"
❌ **Period at end**: "Add feature."
❌ **Vague**: "Update stuff", "Fix things"
❌ **AI mentions**: "Add AI-assisted feature"
❌ **Too long**: "Add really long feature description that exceeds the fifty character limit"
❌ **Implementation details**: "Add function foo() that calls bar()"

**Body (when used)**:
❌ **Overly verbose**: Long multi-line explanations per bullet
❌ **Implementation details**: Explaining code mechanics (diff shows this)
❌ **Redundant context**: Repeating what's obvious from subject
❌ **Unnecessary body**: Adding body for simple, self-explanatory changes
❌ **Mixing unrelated changes**: Long body listing unrelated changes → split into multiple commits instead

## Repository Examples

**Good** (from git log):
```
✓ Add Claude skills for package management, script creation, and validation
✓ Refactor omarchy-changes to simplified command
✓ Fix package-manager duplicate detection and output formatting
✓ Separate theme state from settings using modify scripts
✓ Add comprehensive Unicode font coverage
✓ Document package-manager v3.0 modular architecture
```

**Bad**:
```
❌ fixed bug
❌ updated stuff
❌ Added new feature using AI assistance
❌ adding user authentication
❌ updates to the configuration files
❌ Fix the bug in the authentication system that was causing users to not be able to log in
```

## Special Cases

### No changes staged
```
No changes staged for commit.

Use:
  git add <file>   # Stage specific files
  git add .        # Stage all changes
  git add -p       # Interactive staging
```

### Merge commits
Use Git's auto-generated merge message. Don't override unless necessary.

### Revert commits
Use `git revert` auto-generated message format:
```
Revert "Original commit message"

This reverts commit <hash>.
```

### Initial commit
"Initial commit" is acceptable for brand new repositories.

### Multi-file changes with unified purpose
Focus on the overall goal, not individual files:
```
✓ Add authentication system
❌ Update auth.js, login.js, and routes.js
```

### Splitting commits
When changes include unrelated modifications, split into multiple commits:

**Use interactive staging**:
```bash
git add -p              # Interactively stage hunks
git add file1.js        # Stage specific files
git commit -m "Fix authentication bug"
git add file2.js file3.js
git commit -m "Add user profile feature"
```

**Signs you should split**:
- Fixing bug A + adding feature B
- Refactoring + new functionality
- Multiple unrelated fixes
- Long commit body listing disparate changes

**Keep commits atomic**: Each commit should represent one logical change that could be reverted independently

### Breaking changes
Consider adding a footer:
```
Add new configuration format

- Migrate from JSON to YAML
- Add schema validation
- Update documentation

BREAKING CHANGE: Old JSON configs no longer supported
```

## Validation Checklist

Before presenting the message, verify:

- [ ] Subject ≤50 characters
- [ ] Imperative mood (Add, Fix, not Added, Fixed)
- [ ] Capitalized first word
- [ ] No period at end
- [ ] Body reasonably short but descriptive (if present)
- [ ] Body wraps at 72 characters (if present)
- [ ] No AI/automation mentions
- [ ] Matches repository style (check `git log`)
- [ ] Focuses on "what" and "why", not implementation details
- [ ] Verb accurately describes the change type
- [ ] Changes are related (if not, suggest splitting commits)

## Reference

- **Repository conventions**: `git log --oneline -20`
- **Git config**: `private_dot_config/git/CLAUDE.md`
- **CLAUDE.md**: HEREDOC commit pattern (lines 288-330)
- **Commit guidelines**: CLAUDE.md core standards
