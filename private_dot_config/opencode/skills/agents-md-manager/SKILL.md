---
name: agents-md-manager
description: Manage AGENTS.md file quality and content. Use when creating, updating, validating, or refactoring AGENTS.md files. Ensures compliance with best practices including conciseness, specificity, token efficiency, and proper hierarchy. Triggers on tasks like "validate AGENTS.md", "improve documentation quality", "check for anti-patterns", "refactor AGENTS.md structure", or "create new AGENTS.md".
---

# AGENTS.md Manager

Manage AGENTS.md file quality and content based on best practices.

**Core principle**: For each line, ask "Would removing this cause mistakes?" If not, cut it.

## Reference Files

| File | When to Load |
|------|-------------|
| [guidelines.md](references/guidelines.md) | Include/exclude lists, examples, structure |
| [instruction-patterns.md](references/instruction-patterns.md) | Writing rules AI follows, phrasing, placement |
| [diagnostic-workflow.md](references/diagnostic-workflow.md) | Troubleshooting when rules aren't working |
| [quality-checklist.md](references/quality-checklist.md) | Manual quality review checklist |
| [task-patterns.md](references/task-patterns.md) | Creating, refactoring, improving files |
| [hierarchy.md](references/hierarchy.md) | Root vs subdirectory organization |
| [token-budget.md](references/token-budget.md) | Optimizing token usage |

## Validation Workflow

### Step 1: Run Automated Validation

```bash
# Validate single file
python3 ~/.config/opencode/skills/agents-md-manager/scripts/validate_agents_md.py AGENTS.md

# Validate all AGENTS.md files in repository
python3 ~/.config/opencode/skills/agents-md-manager/scripts/validate_agents_md.py .
```

**Checks**:
- File length (warns >500 lines, errors >1000)
- Token estimation (calculates approximate cost)
- Common anti-patterns (generic advice, tutorials, verbose descriptions)
- Vague language (properly, correctly, as needed)
- Markdown structure (code blocks, heading hierarchy)
- Progressive disclosure usage (imports, cross-references)

### Step 2: Manual Quality Review

Use the checklist: [quality-checklist.md](references/quality-checklist.md)

**Key checks**:
- [ ] Conciseness test (every line justified)
- [ ] Specificity test (no vague instructions)
- [ ] Value test (AI can't infer from code)
- [ ] Structure quality (scannable, organized)
- [ ] Token efficiency (tables, cross-refs, no duplication)

### Step 3: Guidelines Compliance

Refer to: [guidelines.md](references/guidelines.md)

**Validate against**:
- Include/exclude lists
- Structure recommendations
- Import syntax usage
- Location hierarchy appropriateness

## Quick Commands

```bash
# Validate all AGENTS.md files
python3 ~/.config/opencode/skills/agents-md-manager/scripts/validate_agents_md.py .

# Check specific file
python3 ~/.config/opencode/skills/agents-md-manager/scripts/validate_agents_md.py path/to/AGENTS.md

# Find all AGENTS.md files
find . -name "AGENTS.md" -type f

# Check file lengths
find . -name "AGENTS.md" -exec wc -l {} \; | sort -n

# Check for vague language
grep -n "properly\|correctly\|appropriately" AGENTS.md

# Check for generic advice
grep -ni "clean code\|best practices\|good code" AGENTS.md
```

## Target Lengths

| Scope | Ideal | Max |
|-------|-------|-----|
| Root file | 200-300 lines | 500 lines |
| Subdirectory | 150-250 lines | 400 lines |
| Total tokens | <1200 | <4000 |

## When to Split

- File >500 lines → Split into `.opencode/rules/`
- AI ignores rules → File too long, needs pruning
- Duplicate content → Use imports or cross-references
- Topics are distinct → Separate into modular files

**See**: [task-patterns.md](references/task-patterns.md) for refactoring strategies

## Troubleshooting

**See**: [diagnostic-workflow.md](references/diagnostic-workflow.md) for systematic troubleshooting when AI ignores rules
