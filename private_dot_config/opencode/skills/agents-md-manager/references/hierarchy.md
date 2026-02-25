# AGENTS.md Location Hierarchy

Guidelines for organizing AGENTS.md files across project structure.

## Loading Order

Files load in hierarchical order:
1. User memory (`~/.config/opencode/AGENTS.md`)
2. Project root (`./AGENTS.md` or `./.opencode/AGENTS.md`)
3. Parent directories (walks up from cwd)
4. Child directories (loaded on-demand when working in subdirectories)

## Root AGENTS.md

**Scope**: Repository-wide standards, architecture, core patterns

**Include**:
- Critical safety protocols
- Architecture overview (high-level only)
- Coding standards (patterns, not exhaustive)
- Quality requirements
- Cross-references to subdirectories

**Targets**:
| Metric | Ideal | Max |
|--------|-------|-----|
| Lines | 200-300 | 500 |
| Tokens | 800-1200 | 2000 |

## Subdirectory AGENTS.md

**Scope**: Component-specific implementation details

**Include**:
- Component purpose and structure
- Configuration syntax (specific patterns only)
- Integration points
- Testing/reload procedures
- Cross-references to parent/root

**Targets**:
| Metric | Ideal | Max |
|--------|-------|-----|
| Lines | 150-250 | 400 |
| Tokens | 600-1000 | 1600 |

**Pattern**:
```markdown
**Location**: `/path/to/directory`
**Parent**: See `../AGENTS.md` for overview
**Root**: See `/AGENTS.md` for core standards

**CRITICAL**: Be concise. Sacrifice grammar for token-efficiency.
```

## Modular Rules (`.opencode/rules/`)

**Scope**: Topic-specific instructions

**When to use**:
- File >500 lines
- Distinct topics that can be separated
- Path-specific rules needed

**Structure**:
```
.opencode/rules/
├── topic1.md
├── topic2.md
└── category/
    ├── subtopic1.md
    └── subtopic2.md
```

**Path-scoped rules** (YAML frontmatter):
```markdown
---
paths:
  - "src/api/**/*.ts"
  - "lib/api/**/*.ts"
---

# API Development Rules
- All endpoints must include input validation
- Use standard error response format
```

**Supported glob patterns**:
- `**/*.ts` - All TypeScript files
- `src/**/*` - All files under src/
- `*.md` - Markdown in root
- `src/**/*.{ts,tsx}` - Multiple extensions
