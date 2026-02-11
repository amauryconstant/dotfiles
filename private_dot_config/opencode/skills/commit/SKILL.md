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
- Instead of "Update script" → "Update background task scheduler to support multiple patterns"
- Instead of "Add feature" → "Add interactive confirmation prompts for destructive operations"

**Describe the impact**: Commit messages should clearly indicate which part of the codebase changes (e.g., "authentication", "argument parser", "shell configuration", "API", "database").

## Focus on Substance, Not Action

Good commit messages describe **what changed** (the content), not **what you did** (the action).

**Action-focused (avoid)**:

- "Fix config" - What was fixed?
- "Update docs" - What was updated?
- "Amend specs" - What was amended?

**Content-focused (prefer)**:

- "Fix authentication token expiration" - Describes the actual problem
- "Add interactive confirmation prompts" - Describes the actual feature
- "Update shell functions for POSIX compliance" - Describes the actual change

**Rule**: Your message should be understandable to someone who doesn't know what actions you took.

**Test**: Would someone unfamiliar with the change understand what was modified by reading just the subject line?

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

### 3.5. Understand Substance of Changes

Before drafting the message, understand WHAT changed (not just HOW many):

**For large changes** (5+ files):

- Read key changed files to understand the actual modifications
- Identify the core substance of the change
- Ask: "If I described this to another developer, what would I say changed?"

**For spec/docs changes**:

- List what was added vs what was removed
- Identify the direction of the change

**Example transformation**:

- Instead of: "Amend specs" (action)
- Use: "Update configuration schema to domain-specific format" (substance)

**Goal**: Before categorizing (fix/add/update), be able to articulate the actual change in one sentence to a colleague.

### 4. Classify change type

Determine the primary verb from the diff:

| Category       | Verbs                             | When to Use                             |
| -------------- | --------------------------------- | --------------------------------------- |
| Bug fixes      | Fix, Resolve, Correct             | Broken functionality, error corrections |
| New features   | Add, Implement, Introduce         | New capabilities, functionality         |
| Improvements   | Improve, Enhance, Optimize        | Better performance, UX                  |
| Changes        | Update, Change, Modify            | Existing feature modifications          |
| Cleanup        | Remove, Delete, Clean             | Deleting code, removing features        |
| Restructure    | Refactor, Consolidate, Reorganize | Internal changes (no behavior change)   |
| Documentation  | Document, Add docs                | README, comments, docs changes          |
| Enable/Disable | Enable, Disable, Make             | Configuration toggles                   |

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
git log -20
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
sleep 1
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
Fix argument parsing for subcommands

Subcommands were failing when passed with the --separator flag due to incorrect argument order handling.

Root cause: Parsing separator flag before establishing subcommand context

Fix: Process subcommand argument before global flags

Closes: #123
```

OR

```
Amend existing specs to match actual implementation

- domain-models: Claude Code format (name, tools, model) instead of planned fields
- project-layout: internal/ packages instead of pkg/, removed schemas/adapters
- ci-workflow: 4-stage pipeline (no tag stage/job)
- mise-task-runner: .mise/config.toml, check task, updated tasks
- validation-scripts: Release validation scripts, check task for comprehensive validation
- cli-framework: Version defaults (dev, ""), hardcoded description
- yaml-parsing: Memory paths array instead of title/applies_to
```

## Anti-Patterns

**Subject line**:

- ❌ Past tense: "Added feature", "Fixed bug"
- ❌ Present continuous: "Adding feature", "Fixing bug"
- ❌ Lowercase: "add feature"
- ❌ Period at end: "Add feature."
- ❌ Vague: "Update stuff", "Fix things", "Update config", "Fix script"
- ❌ Non-specific verbs: "Update", "Fix" without context (be more precise)
- ❌ Action-only: "Update files", "Change config", "Fix stuff" (WHAT changed?)
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

**Action-focused vs Content-focused**:
❌ Action-focused:

- Update config
- Fix script
- Amend specs
- Change files

✓ Content-focused:

- Add OAuth2 support for user authentication
- Fix argument parsing for subcommands
- Migrate shell config to POSIX compliance
- Refactor database query builder to use fluent interface

**Good** (diverse examples):

```
✓ Fix authentication token expiration
✓ Add interactive confirmation prompts for destructive operations
✓ Migrate shell config to POSIX-compliant syntax
✓ Add rate limiting middleware
✓ Refactor argument parser to support subcommands
✓ Add Git hooks to enforce commit message standards
✓ Update user profile validation logic
✓ Fix JSON output formatting for downstream tool integration
✓ Consolidate validation logic into shared module
✓ Improve error handling across all modules
```

These examples demonstrate specific, descriptive commit messages that clearly state what changes and which component is affected across web, CLI, and dotfiles development.

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
✓ Add argument subcommands
❌ Update parser.go, handler.go, and flags.go
```

### Splitting commits

When changes include unrelated modifications, split into multiple commits:

**Use interactive staging**:

```bash
git add -p              # Interactively stage hunks
git add file1.py        # Stage specific files
git commit -m "Fix argument parsing bug"
git add file2.go file3.sh
git commit -m "Add validation hooks"
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
Refactor command-line argument interface

- Migrate from flags to subcommands
- Add argument validation
- Update documentation

BREAKING CHANGE: Old flag-based interface no longer supported
```

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
- [ ] Message describes **what changed** (substance), not just action taken
- [ ] Changes are related (if not, suggest splitting commits)

## Reference

- **Repository conventions**: `git log -20`
- **Git documentation**: `git help commit`
