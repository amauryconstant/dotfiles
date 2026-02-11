---
name: commit
description: Write concise classical commit messages with imperative mood, ≤80 char subjects. Be specific about dotfiles components (Hyprland, Waybar, Zsh, package-manager). Use when user asks to commit, create a commit, write a commit message, or for help with git commits.
allowed-tools: Read, Grep, Bash("git diff *"), Bash("git status *"), Bash("git log *"), Bash("git add *"), Bash("git show *"), Bash("git commit *"),
---

# Commit Skill

Generate concise, descriptive commit messages following dotfiles repository conventions. Focus on specific components and precise change descriptions.

## When to Use

- User wants to create a commit
- User asks "write a commit message"
- User mentions committing changes
- User asks for help with git commit
- User runs `/commit`

## Commit Message Principles

**Be precise and descriptive**: Focus on what specific aspect of the dotfiles changes. Avoid generic terms like "fix" or "update" - describe the actual modification.

**Examples of improved messages**:
- Instead of "Fix config" → "Fix Hyprland keybinding conflict with terminal"
- Instead of "Update script" → "Update wallpaper timer to support multiple directories"
- Instead of "Add feature" → "Add theme integration for Firefox userChrome.css"

**Describe the dotfiles impact**: Commit messages should clearly indicate which part of the dotfiles ecosystem changes (e.g., "Hyprland", "Waybar", "shell", "theme system", "package management").

## Execution Steps

### 1. Analyze current changes

Run in parallel to understand the full scope:

```bash
# View all changes (staged + unstaged)
git diff HEAD

# Check status
git status

# View recent commits for style
git log -20
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

**Subject line** (≤80 characters):
- Start with verb: Add, Fix, Update, Refactor, Remove, Document
- Use imperative mood (NOT Added, Fixed, Updated)
- Capitalize first word
- No period at end
- Focus on **what specific part of dotfiles** changed at high level
- **Be precise**: Describe the actual change, not just "fix" or "update"
- Include the component name: "Hyprland", "Waybar", "Zsh", "package-manager", etc.

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
git log -20
```

**This repository's conventions**:
- ✓ Imperative mood (Add, Fix, Update, Refactor)
- ✓ Capitalized first word
- ✓ Concise subjects (≤80 characters, brevity preferred)
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

Subject: XX/80 characters

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

## Anti-Patterns

**Subject line**:
❌ **Past tense**: "Added feature", "Fixed bug"
❌ **Present continuous**: "Adding feature", "Fixing bug"
❌ **Lowercase**: "add feature"
❌ **Period at end**: "Add feature."
❌ **Vague**: "Update stuff", "Fix things", "Update config", "Fix script"
❌ **Non-specific verbs**: "Update", "Fix" without context (be more precise)
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

These examples demonstrate specific, descriptive commit messages that clearly state what changes and which component is affected.

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

### Dotfiles Commit Patterns

**Describe the impact on dotfiles ecosystem**: Dotfiles changes affect multiple interconnected systems. Be specific about which component changes.

**Component names to use**:
- Hyprland, Waybar, Wofi, Dunst (desktop environment)
- Zsh, shell scripts, terminal (shell environment)
- Theme system, color schemes (theming)
- Package management, package-manager (software)
- chezmoi templates, modify scripts (configuration framework)

**Examples of descriptive commit messages**:
```
✓ Fix Hyprland keybinding conflict with terminal
✓ Update wallpaper timer to support multiple directories
✓ Add theme integration for Firefox userChrome.css
✓ Refactor package-manager to modular architecture
✓ Fix Zsh alias syntax for Git workflow commands
✓ Update Waybar module to display battery percentage
✓ Add darkman integration for automatic theme switching
✓ Fix chezmoi template variable resolution in script
```

**Vague examples to avoid**:
```
❌ Fix config
❌ Update script
❌ Fix stuff
❌ Update dotfiles
❌ Add feature
❌ Fix bug
```

## Validation Checklist

Before presenting the message, verify:

- [ ] Subject ≤80 characters (hard limit)
- [ ] Imperative mood (Add, Fix, not Added, Fixed)
- [ ] Capitalized first word
- [ ] No period at end
- [ ] **Specific and descriptive**: Not just "fix" or "update"
- [ ] **Includes component name**: Hyprland, Waybar, Zsh, package-manager, etc.
- [ ] **Describes dotfiles impact**: Clear what part of dotfiles changes
- [ ] Body reasonably short but descriptive (if present)
- [ ] Body wraps at 72 characters (if present)
- [ ] No AI/automation mentions
- [ ] Matches repository style (check `git log`)
- [ ] Focuses on "what" and "why", not implementation details
- [ ] Verb accurately describes the change type
- [ ] Changes are related (if not, suggest splitting commits)

## Reference

- **Repository conventions**: `git log -20`
- **Git config**: `private_dot_config/git/CLAUDE.md`
- **CLAUDE.md**: HEREDOC commit pattern (lines 288-330)
- **Commit guidelines**: CLAUDE.md core standards
