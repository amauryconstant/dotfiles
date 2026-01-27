---
name: commit
description: Write concise classical commit messages with imperative mood, ≤72 char subjects. Be specific about components and changes. Use when user asks to commit, create a commit, write a commit message, or for help with git commits.
---

# Commit Skill

Generate concise, descriptive commit messages following best practices. Focus on specific components and precise change descriptions.

## When to Use

- User wants to create a commit
- User asks "write a commit message"
- User mentions committing changes
- User asks for help with git commit
- User runs `/commit`

## Commit Message Principles

**Be precise and descriptive**: Focus on what specific aspect changes. Avoid generic terms like "fix" or "update" - describe the actual modification.

**Examples of improved messages**:
- Instead of "Fix config" → "Fix authentication token expiration"
- Instead of "Update script" → "Update payment scheduler to support multiple cron patterns"
- Instead of "Add feature" → "Add OAuth2 integration for third-party authentication"

**Describe the impact**: Commit messages should clearly indicate which part of the codebase changes (e.g., "authentication", "API", "database", "frontend", "validation logic").

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

| Category | Verbs | When to Use |
|----------|-------|-------------|
| Bug fixes | Fix, Resolve, Correct | Broken functionality, error corrections |
| New features | Add, Implement, Introduce | New capabilities, functionality |
| Improvements | Improve, Enhance, Optimize | Better performance, UX |
| Changes | Update, Change, Modify | Existing feature modifications |
| Cleanup | Remove, Delete, Clean | Deleting code, removing features |
| Restructure | Refactor, Consolidate, Reorganize | Internal changes (no behavior change) |
| Documentation | Document, Add docs | README, comments, docs changes |
| Enable/Disable | Enable, Disable, Make | Configuration toggles |

**Guideline**: Start with common verbs but be precise:
- "Fix" for bugs
- "Add" for new features
- "Update" for existing feature changes
- "Refactor" for internal restructuring
- "Remove" for deletions
- Use more specific verbs when they add clarity (e.g., "Consolidate", "Optimize", "Integrate")

### 5. Draft commit message

**Subject line** (≤72 characters):
- Start with verb: Add, Fix, Update, Refactor, Remove, Document
- Use imperative mood (NOT Added, Fixed, Updated)
- Capitalize first word
- No period at end
- Focus on **what specific part** changed at high level
- **Be precise**: Describe the actual change, not just "fix" or "update"
- Include component name when helpful: `auth: Fix token refresh`, `api: Add rate limiting`

**Body** (for complex changes):
- Blank line after subject
- Use bullet points with "- " prefix
- Explain **why** the change was made (diff shows what)
- Keep reasonably short but descriptive
- Each bullet should be a single line (≤72 chars)
- Wrap lines at 72 characters

**When to add body**:
- Multiple files changed
- Behavior changes with side effects
- Bug fixes requiring context
- Breaking changes (use BREAKING CHANGE footer)
- Performance changes with metrics
- Non-obvious reasoning behind the change

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

**Conventions**:
- ✓ Imperative mood (Add, Fix, Update, Refactor)
- ✓ Capitalized first word
- ✓ Concise subjects (≤72 characters, brevity preferred)
- ✓ No periods at end
- ✓ No AI/automation mentions
- ✓ Focus on changes, not implementation details

### 7. Present commit message

Format the presentation clearly:

```
Proposed commit message:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Subject line]

[Body if complex - with bullets]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Subject: XX/72 characters

Would you like me to:
1. Commit with this message
2. Let you commit manually
3. Revise the message
```

### 8. Execute commit (if approved)

**CRITICAL**: Use HEREDOC for proper formatting:

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
Fix authentication token expiration
```

### Complex commits
```
Fix authentication token expiration

Tokens were expiring 1 hour before the configured expiry time
due to incorrect timezone handling.

Root cause: Using local time instead of UTC for expiry checks
Fix: Convert all timestamps to UTC before comparison

Closes: #123
```

## Anti-Patterns

**Subject line**:
- ❌ Past tense: "Added feature", "Fixed bug"
- ❌ Present continuous: "Adding feature", "Fixing bug"
- ❌ Lowercase: "add feature"
- ❌ Period at end: "Add feature."
- ❌ Vague: "Update stuff", "Fix things", "Update config", "Fix script"
- ❌ Non-specific verbs: "Update", "Fix" without context (be more precise)
- ❌ AI mentions: "Add AI-assisted feature"
- ❌ Too long: "Add really long feature description that exceeds the limit"
- ❌ Implementation details: "Add function foo() that calls bar()"

**Body (when used)**:
- ❌ Overly verbose: Long multi-line explanations per bullet
- ❌ Implementation details: Explaining code mechanics (diff shows this)
- ❌ Redundant context: Repeating what's obvious from subject
- ❌ Unnecessary body: Adding body for simple, self-explanatory changes
- ❌ Mixing unrelated changes: Long body listing unrelated changes → split into multiple commits instead

## Repository Examples

**Good**:
```
✓ Fix authentication token expiration
✓ Add OAuth2 support for user authentication
✓ Refactor database query builder to use fluent interface
✓ Update user profile validation logic
✓ Reduce image upload latency by 40%
✓ Consolidate validation logic into shared module
```

These examples demonstrate specific, descriptive commit messages that clearly state what changes and which component is affected.

**Vague examples to avoid**:
```
❌ Fix config
❌ Update script
❌ Fix stuff
❌ Update codebase
❌ Add feature
❌ Fix bug
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

## Component Naming Patterns

When to include component names:
- Large/monolithic projects
- Changes span multiple areas
- Clear separation of concerns

Format options:
- `component: description`
- `[component] description`

Examples:
- `auth: Fix token refresh logic`
- `database: Refactor connection pooling`
- `api: Add rate limiting middleware`
- `frontend: Fix responsive layout for mobile`

When to omit component names:
- Small projects
- Single-purpose repositories
- Obvious component context

## Validation Checklist

Before presenting the message, verify:

- [ ] Subject ≤72 characters (hard limit)
- [ ] Imperative mood (Add, Fix, not Added, Fixed)
- [ ] Capitalized first word
- [ ] No period at end
- [ ] **Specific and descriptive**: Not just "fix" or "update"
- [ ] **Be precise**: Describes the actual change
- [ ] Body reasonably short but descriptive (if present)
- [ ] Body wraps at 72 characters (if present)
- [ ] No AI/automation mentions
- [ ] Matches repository style (check `git log`)
- [ ] Focuses on "what" and "why", not implementation details
- [ ] Verb accurately describes the change type
- [ ] Changes are related (if not, suggest splitting commits)

## Reference

- **Repository conventions**: `git log --oneline -20`
- **Git documentation**: `git help commit`
