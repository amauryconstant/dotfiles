# Diagnostic Workflow

Systematic troubleshooting when AGENTS.md instructions aren't working.

## Symptom → Cause Mapping

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| AI asks questions answered in file | File too long / phrasing unclear | Split file, simplify phrasing |
| AI ignores documented rules | Rule buried / needs emphasis / conflicts | Move to top, add emphasis, remove conflicts |
| Inconsistent behavior | Conflicting instructions | Find and resolve conflicts |
| AI follows some rules but not others | Placement / specificity issues | Reorganize, add commands |
| Rules worked but stopped working | File grew too long | Prune or split |

## Diagnostic Steps

### Step 1: Check File Length

```bash
wc -l AGENTS.md
```

| Lines | Status | Action |
|-------|--------|--------|
| <300 | Good | Look elsewhere for cause |
| 300-500 | Warning | Consider pruning |
| >500 | Problem | Split or prune immediately |

### Step 2: Check for Conflicts

Search for contradictory instructions:

```bash
# Find potential conflicts
grep -n "always\|never\|must\|should" AGENTS.md | head -20
```

Common conflict patterns:
- "Always X" vs "Sometimes Y"
- Root says one thing, subdirectory says another
- Multiple rules files with overlapping paths

### Step 3: Check Rule Placement

For ignored rules, check position:

| Position | Effectiveness |
|----------|---------------|
| First 20 lines | Highest |
| Last 20 lines | High |
| Middle of file | Lower |
| Middle of long section | Lowest |

Move critical ignored rules to top or bottom.

### Step 4: Check Phrasing

Review ignored rule for:

| Issue | Pattern | Fix |
|-------|---------|-----|
| Passive voice | "should be done" | Change to imperative |
| Conditional | "if possible" | Remove or make absolute |
| Vague | "properly", "correctly" | Add specific command |
| No example | Abstract description | Add code block |

### Step 5: Test Isolated

1. Create minimal test file with just the problematic rule
2. Test with specific prompt
3. If works → problem is context (file too long, conflicts)
4. If doesn't work → problem is phrasing

## Common Fixes

### File Too Long

**Quick fix**: Move non-critical content to subdirectory files or `.opencode/rules/`

```markdown
# In AGENTS.md (before: 800 lines)
## Architecture
See `docs/architecture.md` for details.

## API Reference
See `docs/api.md` for endpoints.
```

**Result**: 800 → 300 lines, critical rules get more attention

### Rule Gets Ignored

1. Move to top of file
2. Add emphasis: `**NEVER**` or `**MUST**`
3. Add specific command if abstract
4. Remove any conflicting rule

### Conflicting Instructions

1. Identify both sources (root vs subdirectory vs rules/)
2. Decide which should win
3. Either remove loser or add explicit override:
   ```markdown
   # In subdirectory AGENTS.md
   **Note**: This overrides the root AGENTS.md style rules for this directory.
   ```

### Vague Instructions

Transform step by step:

```markdown
# Original (vague)
Run tests appropriately before committing.

# Step 1: Add command
Run `npm test` before committing.

# Step 2: Add when
Run `npm test` before every commit.

# Step 3: Add emphasis if critical
Run `npm test` before **every** commit.
```

## Testing Methodology

### A/B Testing

1. Note current behavior (baseline)
2. Make ONE change
3. Test with same prompt
4. Compare results
5. Keep or revert

### Verification Prompts

After making changes, test with:

```
What are the testing requirements?
What branch should I commit to?
How do I build this project?
What code style should I follow?
```

Correct answers should match your documented rules exactly.

### Iteration Pattern

```
Problem → Hypothesis → Change → Test → Result
   ↑                                              ↓
   ←←←←←←←←←←←←←←← Revert if no improvement ←←←←←←
```

## Maintenance Triggers

Re-run diagnostics when:

- Adding new rules (check for conflicts)
- File grows >100 lines since last review
- AI behavior changes unexpectedly
- New team member reports confusion
- After major project changes

## Quick Reference

```bash
# Check file length
wc -l AGENTS.md

# Find potential conflicts
grep -ni "always\|never\|must" AGENTS.md

# Find vague language
grep -ni "properly\|correctly\|appropriately\|should" AGENTS.md

# Find buried critical rules
head -20 AGENTS.md  # Should have most important rules
tail -20 AGENTS.md  # Should reinforce critical rules
```
