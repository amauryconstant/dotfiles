# CLAUDE.md Quality Checklist

Use this checklist to validate CLAUDE.md files against official Anthropic best practices.

## Content Quality

### Conciseness Test
- [ ] Every line passes the test: "Would removing this cause Claude to make mistakes?"
- [ ] No generic advice Claude already knows ("write clean code")
- [ ] No self-evident information (standard language conventions)
- [ ] No redundant explanations
- [ ] File length appropriate (consider splitting if >500 lines)

### Specificity Test
- [ ] Instructions are specific, not vague
  - ✅ "Use 2-space indentation for TypeScript"
  - ❌ "Format code properly"
- [ ] Commands are complete and runnable
  - ✅ "`npm run typecheck` after code changes"
  - ❌ "Run the typechecker"
- [ ] Examples include actual code/commands, not placeholders

### Value Test (Claude Can't Infer)
- [ ] Contains project-specific commands Claude can't guess
- [ ] Documents non-standard conventions
- [ ] Explains project-specific architectural decisions
- [ ] Includes environment-specific quirks
- [ ] Lists gotchas and non-obvious behaviors
- [ ] No standard library documentation (link instead)
- [ ] No file-by-file codebase descriptions

## Structure Quality

### Markdown Formatting
- [ ] Proper heading hierarchy (# → ## → ###)
- [ ] Scannable lists for related items
- [ ] Code blocks for commands and examples
- [ ] Tables for structured comparisons
- [ ] No wall-of-text paragraphs

### Organization
- [ ] Logical sections with clear purposes
- [ ] Related content grouped together
- [ ] Quick reference section at top (optional but helpful)
- [ ] Each section focused on one topic
- [ ] Cross-references clear and accurate

### Modularity
- [ ] Consider splitting if file >500 lines
- [ ] Use `.claude/rules/` for topic-specific content
- [ ] Use `@imports` for referencing external docs
- [ ] Path-specific rules use YAML frontmatter appropriately
- [ ] No circular imports

## Hierarchy Quality

### Location Appropriateness
- [ ] Content in correct location for scope:
  - Organization-wide → `/etc/claude-code/CLAUDE.md`
  - User preferences → `~/.claude/CLAUDE.md`
  - Team-shared → `./CLAUDE.md` or `./.claude/CLAUDE.md`
  - Private → `./CLAUDE.local.md`
  - Modular → `./.claude/rules/*.md`

### Parent-Child Relationships
- [ ] Parent files cover general principles
- [ ] Child files provide specific details
- [ ] No duplication between parent and child
- [ ] Child files reference parent appropriately
- [ ] Subdirectory CLAUDE.md files loaded correctly

### Cross-References
- [ ] References to parent files include path
- [ ] References to sibling files accurate
- [ ] References to root file clear
- [ ] Import paths (`@`) resolve correctly
- [ ] No broken references

## Token Efficiency

### Length Indicators
- [ ] Total line count reasonable (<500 lines ideal, <1000 acceptable)
- [ ] Average section length <50 lines
- [ ] No section >100 lines (split into subsections)
- [ ] Code examples concise (not full implementations)
- [ ] Tables used instead of verbose lists where appropriate

### Redundancy Check
- [ ] No information duplicated from other CLAUDE.md files
- [ ] No information duplicated from code comments
- [ ] No information duplicated from README
- [ ] Use imports instead of copying content
- [ ] Cross-references instead of repetition

### Pruning Opportunities
- [ ] Remove information Claude hasn't needed
- [ ] Remove rules Claude already follows without instruction
- [ ] Remove outdated temporary workarounds
- [ ] Remove over-explained concepts
- [ ] Remove tutorial-style content (link instead)

## Effectiveness Indicators

### Positive Signs (Keep These)
- Commands Claude uses regularly
- Rules that prevent recurring mistakes
- Conventions that differ from defaults
- Project-specific patterns Claude references
- Environment quirks that cause issues

### Negative Signs (Consider Removing)
- Claude asks questions answered in file → Phrasing unclear or file too long
- Claude ignores documented rules → File too long or rule needs emphasis
- You never see Claude reference a section → Probably not needed
- Information hasn't been relevant in months → Remove or archive
- You find yourself explaining things that are documented → Improve clarity

## Common Issues

### Too Long
**Symptom**: Claude ignores documented rules
**Fix**:
- Ruthlessly prune content
- Split into modular `.claude/rules/` files
- Move detailed docs to references with imports
- Add emphasis to critical rules

### Too Vague
**Symptom**: Claude asks for clarification on documented topics
**Fix**:
- Add specific examples
- Include actual commands with flags
- Show concrete code patterns
- Use code blocks instead of descriptions

### Wrong Location
**Symptom**: Content duplicated or conflicts across files
**Fix**:
- Move personal preferences to `~/.claude/CLAUDE.md`
- Move team conventions to project CLAUDE.md
- Move topic-specific rules to `.claude/rules/`
- Use imports to reference, not duplicate

### Stale Content
**Symptom**: Documented patterns no longer used
**Fix**:
- Review periodically (quarterly)
- Remove deprecated information
- Update changed conventions
- Archive historical decisions not relevant to current work

## Maintenance Schedule

### Weekly
- Note when Claude violates or ignores rules
- Track questions Claude asks that are documented

### Monthly
- Review sections for continued relevance
- Prune content that hasn't been referenced
- Update changed workflows

### Quarterly
- Full audit against this checklist
- Reorganize if file grew >500 lines
- Validate all imports and cross-references
- Check effectiveness indicators

## Validation Commands

```bash
# Check file length
wc -l CLAUDE.md

# Find long sections (>50 lines between headings)
# (Manual review recommended)

# Check for common anti-patterns
grep -i "clean code\|best practices\|good code" CLAUDE.md

# Find vague language
grep -i "properly\|correctly\|appropriately" CLAUDE.md

# Validate imports resolve
# (Use skill's validation script)

# Check for duplicate content
# (Use skill's validation script)
```
