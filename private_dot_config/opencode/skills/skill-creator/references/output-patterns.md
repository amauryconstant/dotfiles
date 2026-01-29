# Output Patterns

Use these patterns to ensure consistent, high-quality output from skills. Choose based on output type, strictness requirements, and quality standards needed.

## Template Pattern

Provide structured templates for output format. Match strictness to your needs.

### When to Use
- Output must follow specific structure
- Multiple sections or components required
- Consistency across generations matters

### Strict Template (Exact Structure Required)

Use when output format is critical and deviations cause issues.

```markdown
## Analysis Report Structure

ALWAYS use this exact template:

# [Analysis Title]

## Executive Summary
[One-paragraph overview of key findings]

## Key Findings
- Finding 1 with supporting data
- Finding 2 with supporting data
- Finding 3 with supporting data

## Recommendations
1. Specific actionable recommendation
2. Specific actionable recommendation

## Appendix
- Additional data or references
```

### Flexible Template (Adaptable Structure)

Use when adaptation is valuable but framework provides guidance.

```markdown
## Analysis Report Structure

Here is a sensible default format, but adapt based on analysis type:

# [Analysis Title]

## Executive Summary
[Overview of findings]

## Key Findings
[Include 3-5 main findings with data]
- Adjust number and depth based on available information

## Recommendations
[Provide 2-4 actionable recommendations]
- Tailor to specific context and feasibility

## Next Steps
[If applicable: what should happen next]
- Optional section if not relevant

Adjust sections as needed for specific analysis type.
```

---

## Examples Pattern

Provide input/output pairs to demonstrate desired style, tone, and level of detail.

### When to Use
- Output quality depends on seeing examples
- Style conventions are non-obvious
- Need to demonstrate format beyond structure

### Example

```markdown
## Commit Message Format

Generate commit messages following these examples:

**Example 1:**
Input: Added user authentication with JWT tokens
Output:
```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

**Example 2:**
Input: Fixed bug where dates displayed incorrectly in reports
Output:
```
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation
```

**Example 3:**
Input: Updated documentation for new API endpoints
Output:
```
docs(api): document v2 endpoints and breaking changes

Update API.md with new endpoint signatures and migration guide
```

Follow this pattern: `type(scope): brief description`, then detailed explanation on next line.
```

---

## Checklist Pattern

Define verification steps to complete before considering output finished.

### When to Use
- Multi-component output requiring validation
- Quality gates before finalization
- Preventing common mistakes or omissions

### Example

```markdown
## Code Output Completion Checklist

Before finalizing code, verify:

### Core Functionality
- [ ] Code solves the stated problem
- [ ] Handles edge cases
- [ ] Error messages are helpful and specific
- [ ] No obvious bugs or logic errors

### Code Quality
- [ ] Variable and function names are descriptive
- [ ] Code follows project conventions
- [ ] Comments only for non-obvious logic
- [ ] Consistent formatting throughout

### Testing
- [ ] Code compiles/runs without errors
- [ ] Type checks pass (if applicable)
- [ ] Tests included for non-trivial logic
- [ ] Manual test completed successfully

### Documentation
- [ ] README or usage instructions included
- [ ] Dependencies documented
- [ ] Examples provided where helpful
- [ ] Known limitations noted
```

---

## Data Validation Pattern

Define input constraints, validation rules, and error handling for data processing.

### When to Use
- Skills process user input or external data
- Need to validate before processing
- Provide clear error feedback

### Example

```markdown
## Input Validation Requirements

### Field Constraints

```json
{
  "title": {
    "type": "string",
    "required": true,
    "minLength": 1,
    "maxLength": 100,
    "pattern": "^[\\w\\s\\-]+$"
  },
  "priority": {
    "type": "string",
    "required": true,
    "enum": ["low", "medium", "high", "critical"]
  },
  "description": {
    "type": "string",
    "required": false,
    "maxLength": 500
  }
}
```

### Validation Steps

1. **Type validation**: Ensure field types match schema
2. **Required field check**: All required fields present
3. **Constraint validation**: Min/max length, values, patterns
4. **Enum validation**: Values match allowed options
5. **Business logic validation**: Custom rules for specific use case

### Error Response Format

For each validation failure, provide:

```json
{
  "error": {
    "field": "title",
    "code": "MAX_LENGTH_EXCEEDED",
    "message": "Title too long (150 characters). Maximum is 100 characters.",
    "currentValue": "This title is way too long and exceeds the maximum...",
    "expectedRange": "1-100 characters"
  }
}
```

### Common Error Codes

- `INVALID_TYPE`: Field type mismatch
- `MISSING_REQUIRED`: Required field not provided
- `MIN_LENGTH_EXCEEDED`: Value too short
- `MAX_LENGTH_EXCEEDED`: Value too long
- `INVALID_PATTERN`: Value doesn't match pattern
- `INVALID_ENUM_VALUE`: Value not in allowed list
```

---

## Schema-Based Pattern

Define structured data formats (JSON, YAML, XML) for output.

### When to Use
- Output must be machine-readable
- Integration with other tools/systems
- Data exchange requirements

### Example

```markdown
## API Response Schema

### Success Response

```json
{
  "status": "success",
  "data": {
    "id": "string (uuid)",
    "name": "string (1-100 chars)",
    "createdAt": "ISO-8601 timestamp",
    "updatedAt": "ISO-8601 timestamp",
    "metadata": {
      "version": "string (semantic version)",
      "tags": ["array of strings"]
    }
  }
}
```

### Error Response

```json
{
  "status": "error",
  "error": {
    "code": "ERROR_CODE",
    "message": "Human-readable description",
    "details": {
      "field": "optional field name",
      "value": "optional problematic value",
      "suggestion": "optional fix suggestion"
    }
  }
}
```

### Required Fields

- `status`: "success" or "error"
- `data` or `error`: Payload based on status

### Field Specifications

- **id**: UUID v4 format
- **name**: Alphanumeric with spaces and hyphens, 1-100 chars
- **createdAt/updatedAt**: ISO-8601 format (e.g., "2026-01-29T10:30:00Z")
- **metadata.version**: Semantic version (X.Y.Z)
- **metadata.tags**: Array of strings, max 50 tags

### Common Error Codes

- `VALIDATION_ERROR`: Input validation failed
- `NOT_FOUND`: Resource not found
- `UNAUTHORIZED`: Authentication required
- `RATE_LIMITED`: Too many requests
- `INTERNAL_ERROR`: Server-side error
```

---

## Progressive Disclosure Pattern

Structure output from summary to detailed levels, allowing readers to digest at their own pace.

### When to Use
- Complex information with varying audience needs
- Need both quick overview and deep details
- Technical reports or documentation

### Example

```markdown
## System Health Report

### Executive Summary (30 seconds)
**Status**: Healthy | **Uptime**: 99.9% | **Issues**: 2 minor

All systems operational. Two minor warnings require attention this week.

### Key Metrics (2 minutes)
- **API Response Time**: 45ms (target: <100ms) ✅
- **Database Connections**: 85% utilized (warning threshold: 90%) ⚠️
- **Error Rate**: 0.01% (target: <0.1%) ✅
- **Disk Usage**: 78% full (warning threshold: 80%) ⚠️

### Issues Detected (5 minutes)
**Issue 1: Database Connection Usage**
- Current: 85% | Warning threshold: 90%
- Trend: Increasing 2% per week
- Impact: If trend continues, will hit threshold in ~3 weeks
- Recommendation: Optimize queries or increase connection pool

**Issue 2: Disk Usage**
- Current: 78% | Warning threshold: 80%
- Trend: Stable for past month
- Impact: Will hit warning threshold in ~1 week
- Recommendation: Review logs for cleanup opportunities

### Detailed Analysis (15 minutes)
**Database Performance:**
- Top 5 slow queries identified
- Query optimization recommendations
- Connection pool configuration details
- Historical performance charts

**Disk Analysis:**
- Directory breakdown by size
- Log rotation recommendations
- Archive strategy options

**Full Metrics:**
- All 47 system metrics with historical trends
- Service-level agreements (SLAs) status
- Incident history for past 30 days
```

---

## Choosing a Pattern

| Pattern | Output Type | Strictness | Best For |
|----------|-------------|------------|-----------|
| Template | Structured documents, reports | Exact or Flexible | Multi-section outputs, consistency matters |
| Examples | Code, text, messages | Style-focused | Learning conventions, tone, format |
| Checklist | Multi-component outputs | Verification | Quality gates, preventing omissions |
| Data Validation | Forms, APIs, inputs | Constraint-driven | User input, external data |
| Schema-Based | JSON, YAML, XML | Structured | Machine-readable, data exchange |
| Progressive Disclosure | Complex information | Tiered depth | Reports, documentation, briefings |

---

## Strictness Levels

Choose the right level for your use case:

### Exact (No Deviations)
- **Use when**: Automation, APIs, data exchange
- **Enforce via**: Schema validation, automated tests
- **Risk**: Inflexibility if requirements change

### Flexible (Adaptable Framework)
- **Use when**: Documents, reports, general guidance
- **Enforce via**: Examples, guidelines, human review
- **Risk**: Inconsistency without oversight

### Adaptive (Context-Dependent)
- **Use when**: Creative outputs, varied contexts
- **Enforce via**: Principles, examples, judgment
- **Risk**: Quality varies based on agent

---

## Quality Rubrics

### Code Quality
- **Correctness**: Solves the problem, handles edge cases
- **Maintainability**: Clear naming, comments for non-obvious logic
- **Testability**: Can be tested, has tests
- **Efficiency**: Appropriate performance for use case

### Document Quality
- **Completeness**: All required sections present
- **Clarity**: Clear, concise language
- **Accuracy**: Factual, correct information
- **Structure**: Logical flow, good formatting

### Data Quality
- **Validity**: Meets all constraints and schemas
- **Consistency**: No contradictions, follows patterns
- **Completeness**: Required fields present
- **Timeliness**: Current, not outdated

### Overall Quality
- **Purpose alignment**: Meets user's actual needs
- **Context awareness**: Appropriate for audience/use case
- **Actionability**: Enables next steps or decisions
- **Verifiability**: Can be checked or tested

---

## Common Mistakes to Avoid

❌ **Over-strict templates**: Rigid templates break when edge cases appear. Use flexible templates or progressive disclosure instead.

❌ **Missing examples**: Without examples, agents may guess wrong style. Always provide 2-3 concrete examples when using Examples pattern.

❌ **Generic checklists**: Checklists that don't catch actual issues are useless. Make each checklist item specific and verifiable.

❌ **Silent validation failures**: Always provide clear error messages. Don't fail validation without explaining what's wrong.

❌ **Schema without examples**: JSON/YAML schemas are hard to read. Combine Schema-Based pattern with Examples pattern.

❌ **Flat structure in complex outputs**: Don't dump all information at once. Use Progressive Disclosure for complex topics.

❌ **No fallback for validation**: When validation fails, provide guidance on how to fix it or what to do next.
