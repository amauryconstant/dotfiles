# Instruction Patterns

Patterns for writing AGENTS.md instructions that AI actually follows.

## Phrasing That Works

### Imperative Mood

```markdown
# Good - Direct commands
Run `npm test` before committing.
Use 2-space indentation for TypeScript.
Never commit directly to main.

# Bad - Passive or conditional
Tests should be run before committing.
It is recommended to use 2-space indentation.
Try to avoid committing to main.
```

### Negative Constraints

Negative constraints are followed more reliably than positive suggestions.

```markdown
# Good - Strong negatives
NEVER commit to main branch.
MUST NOT skip the typecheck.
DO NOT use `any` type.

# Weak - Easily ignored
Avoid committing to main.
Don't skip typecheck.
Prefer not using `any`.
```

### Specificity Hierarchy

From most to least effective:

1. **Exact command**: `npm run typecheck`
2. **Pattern with example**: "Use destructuring: `import { foo } from 'bar'`"
3. **General rule**: "Use ES modules"

Always include exact commands for critical operations.

## Placement Strategies

### Critical Rules: Top and Bottom

AI attention is highest at beginning (primacy) and end (recency) of files.

```markdown
# AGENTS.md

**CRITICAL**: Never commit to main. Always use feature branches.

[... other content ...]

## Quick Reference
- **Branch**: Feature branches only, never main
- **Tests**: Run before every commit
```

### Section Order

Most to least critical:

1. Critical safety rules (NEVER, MUST)
2. Essential commands (build, test, lint)
3. Code style specifics
4. Architecture patterns
5. Nice-to-have conventions

## What AI Follows

✅ **Effective patterns**:
- Direct imperative commands
- Exact commands with flags
- Code examples in blocks
- Explicit lists (numbered or bulleted)
- BOLD or CAPS for emphasis
- Negative constraints (NEVER, MUST NOT)

## What AI Ignores

❌ **Ineffective patterns**:
- Passive voice ("should be done")
- Conditional phrasing ("if possible", "when appropriate")
- Long explanatory paragraphs
- Abstract principles without examples
- Rules buried in long sections
- Conflicting instructions

## Common Phrasing Mistakes

| Bad | Good |
|-----|------|
| "Try to keep functions short" | "Max function length: 50 lines" |
| "Consider using TypeScript" | "All new files MUST be `.ts`" |
| "Ideally run tests" | "Run `npm test` before commit" |
| "It would be good to" | (Delete - if optional, AI decides) |
| "Feel free to" | (Delete - adds no value) |

## Handling Conflicts

When instructions conflict, AI may behave inconsistently.

**Common conflict sources**:
- Root AGENTS.md vs subdirectory AGENTS.md
- Multiple rules files matching same path
- Contradictory style preferences

**Resolution**:
- Document which takes precedence
- Use explicit "override" language: "This overrides root AGENTS.md style rules"
- Remove conflicting rules entirely

## Emphasis Patterns

Use emphasis strategically, not everywhere.

```markdown
# Strategic emphasis
**NEVER** commit secrets to the repository.

# Over-emphasis (gets ignored)
**Always** make sure to **carefully** review **all** changes **before** committing.
```

**Emphasis hierarchy**:
1. `**NEVER**` / `**MUST**` - Safety-critical
2. `**Important**:` - Key rules
3. Bold key terms in sentences - Scanning aid

## Instruction Density

High density = more rules followed per token.

```markdown
# Dense (good)
- Typecheck: `npm run typecheck`
- Test: `npm test`
- Lint: `npm run lint`

# Verbose (bad)
Before committing, you should run the typecheck command using npm run typecheck. 
Additionally, make sure to run the test suite with npm test. Finally, run the 
linter using npm run lint to catch style issues.
```

Target: 1 rule per 1-2 lines for critical instructions.

## Testing Instruction Effectiveness

After writing critical rules, test with specific prompts:

1. "What are the commit requirements?" → Should list exact commands
2. "What branch should I use?" → Should specify branch naming
3. "How do I run tests?" → Should give exact command

If AI answers incorrectly or vaguely, the instruction needs revision.
