# AGENTS.md Task Patterns

Common workflows for creating and maintaining AGENTS.md files.

## Creating New AGENTS.md

**Workflow**:
1. Determine location (root, subdirectory, or `.opencode/rules/`)
2. Start with minimal template
3. Add only essential, non-inferable content
4. Validate with script
5. Manual review against checklist

**Minimal template**:
```markdown
# [Component] Reference

**Location**: `/path/to/directory`
**Parent**: See `../AGENTS.md` for overview

**CRITICAL**: Be concise. Sacrifice grammar for token-efficiency.

## Quick Reference
- Purpose: [Brief description]
- Key files: [Main files]
- Integration: [How it connects]

## [Main Content Sections]
```

## Refactoring Existing AGENTS.md

**When to refactor**:
- File >500 lines
- AI ignores documented rules
- AI asks questions answered in file
- Duplicate content across files
- Stale or outdated sections

### Strategy 1: Split into Modular Rules

```
# Before: Single 800-line file
AGENTS.md (800 lines)

# After: Modular structure
.opencode/
├── AGENTS.md (200 lines - core only)
└── rules/
    ├── scripts.md
    ├── templates.md
    └── workflows.md
```

### Strategy 2: Use Imports

```markdown
# In main AGENTS.md
## Script Standards
@.opencode/rules/scripts.md

## Template System
@.opencode/rules/templates.md
```

### Strategy 3: Location-Based Hierarchy

```
# Before: Everything in root
AGENTS.md (1200 lines covering all)

# After: Location-based
AGENTS.md (300 lines - architecture)
src/
├── AGENTS.md (frontend overview)
├── api/AGENTS.md (API-specific)
└── db/AGENTS.md (database-specific)
```

## Improving Specificity

**Pattern: Vague → Specific**

Before:
```markdown
Test your code properly before committing.
Run the appropriate validation commands.
```

After:
```markdown
# Pre-Commit Validation
1. `npm run typecheck` - TypeScript check
2. `npm test -- --related` - Run affected tests
3. `npm run lint` - Style check
```

**Pattern: Generic → Concrete**

Before:
```markdown
Follow coding best practices.
Write clean, maintainable code.
```

After:
```markdown
# Code Style
- Use `const` over `let` when possible
- Max function length: 50 lines
- Destructure imports: `import { foo } from 'bar'`
```

## Reducing Token Waste

### Use Tables Instead of Verbose Lists

Before (147 tokens):
```markdown
- config.ts: This file handles application configuration
  including environment variables and defaults.
- utils.ts: This file contains utility functions for
  string manipulation and date formatting.
```

After (47 tokens):
```markdown
| File | Purpose |
|------|---------|
| config.ts | App configuration, env vars |
| utils.ts | String/date utilities |
```

### Use Cross-References Instead of Duplication

Before:
```markdown
# In multiple files: 400 lines of duplicated API docs
```

After:
```markdown
# In each file:
**API Reference**: See `docs/api.md` for complete documentation
```

### Front-Load Essentials

Before:
```markdown
[500 lines of detailed content]
## Summary
Key points buried at end
```

After:
```markdown
## Quick Reference
- Purpose: [Brief]
- Commands: [Key commands]
- Files: [Count]

[Detailed content follows]
```
