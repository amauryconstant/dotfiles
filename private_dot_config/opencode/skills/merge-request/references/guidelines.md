# Merge Request Guidelines

This file contains title guidelines, anti-patterns, and validation checklists for merge requests.

## Title Guidelines

### Good Examples

- "Add OAuth2 authentication support"
- "Fix session restore hanging on notification timeout"
- "Refactor theme system with semantic variables"
- "Improve error handling across all modules"
- "Update Git log examples to show full commit format"
- "Add interactive confirmation prompts for destructive operations"

### Avoid

- Too vague: "Update stuff", "Fix things", "Add feature"
- Implementation details: "Modify 7 files to add theme support"
- AI/automation mentions: "Add AI-generated code", "Automated refactoring"
- Overly technical: "Implement singleton pattern for config manager"
- Too long: "Add really really long description that goes on and on and on forever and never seems to end"
- Action-only: "Update files", "Change config" (WHAT changed?)

### Title Length

- **Recommended**: ≤100 characters (flexible, unlike commits)
- **Goal**: Descriptive but concise
- **Focus**: What was accomplished, not how

### Title Style

- More flexible than commit titles
- Can use different tenses/styles
- Not strictly required to be imperative
- Focus on reviewer understanding

## Description Anti-Patterns

### Title Anti-Patterns

- ❌ Too vague: "Fix config", "Update code", "Add feature"
- ❌ Implementation details: "Update theme.py, colors.py, config.py to add theme support"
- ❌ AI mentions: "Add AI-powered theme switching"
- ❌ Non-specific: "Update stuff", "Fix things", "Make changes"

### Description Anti-Patterns

- ❌ Copy-pasting commit messages without synthesis
- ❌ Only listing files changed (no context or purpose)
- ❌ Missing testing guidance for non-trivial changes
- ❌ Overly verbose (summarize, don't duplicate code)
- ❌ Unclear organization (group related changes by category)
- ❌ Mixing unrelated changes (split into multiple MRs instead)

## Description Sections

### Summary

**Purpose**: 2-3 sentences, high-level purpose

**Good**:
```markdown
Add OAuth2 authentication support for user login and token management.
```

**Bad**:
```markdown
I added OAuth2. The OAuth2 provider configuration is now done. Token refresh logic is implemented too. Error handling is there.
```

### Changes

**Purpose**: Bullet points organized by category

**Good**:
```markdown
- Add OAuth2 provider configuration
- Implement token refresh logic
- Add error handling for failed authentications
```

**Bad**:
```markdown
- Updated auth.py with OAuth2 logic
- Modified token.py to add refresh
- Added error.py for handling failures
- Updated tests/
- Modified config/
```

### Testing

**Purpose**: Specific steps for verification (omit if obvious)

**Good**:
```markdown
1. Configure OAuth2 provider credentials
2. Try logging in with OAuth2
3. Verify token refresh works after expiry
```

**Bad**:
```markdown
Test it works
```

**When to omit**:
- Trivial changes (typo fix, documentation update)
- Obvious changes (adding a simple flag)

### Breaking Changes

**Purpose**: Only include if applicable

**Good**:
```markdown
Old configuration format no longer supported. Run migration script:
`bin/migrate-config --from-legacy`

See `MIGRATION.md` for details.
```

**Bad**:
```markdown
Some things might break.
```

**When to omit**:
- No breaking changes
- Minor changes that don't affect compatibility

### Related Issues

**Purpose**: Optional, include if relevant

**Good**:
```markdown
Closes #123
Related to #456, #789
```

**Bad**:
```markdown
Issues: 123, 456, 789 (without context)
```

## Validation Checklist

Before presenting the merge request description, verify:

**Content**:
- [ ] Target branch is confirmed
- [ ] Current branch is not the target
- [ ] Title is descriptive and reviewer-friendly
- [ ] Summary clearly explains overall purpose
- [ ] Changes are organized logically by category
- [ ] Testing guidance included for non-trivial changes
- [ ] Breaking changes documented (if applicable)
- [ ] Related issues referenced (if applicable)

**Format**:
- [ ] Format is markdown-ready for copy-paste
- [ ] Uses `###` for section headers
- [ ] No markdown formatting errors
- [ ] Proper code fences for examples

**Quality**:
- [ ] Not overly verbose (summarize, don't list every file)
- [ ] No copy-pasted commit messages without synthesis
- [ ] No implementation details in title
- [ ] No AI/automation mentions
- [ ] No vague or non-specific descriptions

## Section Order

Recommended order for MR description:

1. Summary (always)
2. Changes (always)
3. Testing (unless obvious/trivial)
4. Breaking Changes (if applicable)
5. Related Issues (if applicable)

## Common Mistakes

1. **Too much detail in Changes**: Don't list every file changed. Group by category.
2. **Missing Testing**: For non-trivial changes, reviewers need to know how to verify.
3. **Vague Summary**: "Add feature" tells reviewers nothing. What feature?
4. **Copy-pasting commits**: Synthesize commits into a cohesive summary, don't list them.
5. **Missing Breaking Changes**: Always document breaking changes with migration instructions.
6. **Too long**: Aim for concise, reviewer-focused descriptions.
