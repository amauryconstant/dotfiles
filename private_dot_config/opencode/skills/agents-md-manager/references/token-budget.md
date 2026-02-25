# Token Budget Management

Optimize AGENTS.md files for context efficiency.

## Token Estimation

**Rough formula**: 1 line ≈ 4 tokens

| Lines | Est. Tokens | % of Context |
|-------|-------------|--------------|
| 200 | 800 | 0.4% |
| 300 | 1200 | 0.6% |
| 500 | 2000 | 1% |
| 1000 | 4000 | 2% |

**Context window**: ~200k tokens

## Recommended Budgets

- AGENTS.md files combined: <5% context (<10,000 tokens)
- Root file: <1200 tokens (300 lines)
- Reserve 80%+ for code and conversation

## Warning Thresholds

**Per file**:
| Tokens | Status |
|--------|--------|
| <1200 | Excellent |
| 1200-2000 | Good (optimize if possible) |
| 2000-4000 | Warning (split recommended) |
| >4000 | Critical (may cause rule ignoring) |

## Measurement Commands

```bash
# Find all AGENTS.md files with line counts
find . -name "AGENTS.md" -exec wc -l {} \; | sort -n

# Calculate estimated total tokens
find . -name "AGENTS.md" -exec wc -l {} \; | \
  awk '{sum+=$1} END {print "Lines:", sum, "| Tokens:", sum*4}'

# Identify largest files
find . -name "AGENTS.md" -exec wc -l {} \; | sort -rn | head -5
```

## Token Savings Examples

**Progressive disclosure**:
- Before: All docs in root (5000 tokens)
- After: Index + subdirectory files (800 root, 4200 on-demand)
- Savings: 4200 tokens (84%) when not working in those areas

**Table optimization**:
- Before: Verbose descriptions (147 tokens/section)
- After: Table format (47 tokens/section)
- Savings: 100 tokens/section (68%)
