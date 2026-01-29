# Workflow Patterns

Use these patterns to structure multi-step processes in skills. Choose based on complexity, error-proneness, and task dependencies.

## Sequential Workflows

For fixed-order processes where steps must execute in sequence.

### When to Use
- Clear dependency chain (step 2 needs step 1 output)
- No branching or conditional logic
- Straightforward linear process

### Example

```markdown
Filling a PDF form involves these steps:

1. Analyze the form (run analyze_form.py)
2. Create field mapping (edit fields.json)
3. Validate mapping (run validate_fields.py)
4. Fill the form (run fill_form.py)
5. Verify output (run verify_output.py)
```

---

## Conditional Workflows

For tasks with binary branching logic based on a single decision point.

### When to Use
- Two distinct approaches based on one condition
- Clear decision criteria
- Each branch is self-contained

### Example

```markdown
1. Determine the modification type:
   **Creating new content?** → Follow "Creation workflow" below
   **Editing existing content?** → Follow "Editing workflow" below

2. Creation workflow:
   - Analyze requirements
   - Draft initial content
   - Review and refine

3. Editing workflow:
   - Locate existing content
   - Understand current state
   - Make targeted changes
   - Verify integrity
```

---

## Decision Tree Workflows

For multi-variant decisions with 3+ branches.

### When to Use
- Multiple distinct approaches based on type or category
- Clear classification criteria
- Each branch handles different scenarios

### Example

```markdown
## Document Processing Decision Tree

1. Determine document type:

   **PDF form?** → See "PDF Form Workflow"
   **Word document (.docx)?** → See "DOCX Workflow"
   **Plain text document?** → See "Text Workflow"
   **Scanned image (PDF/JPG)?** → See "OCR Workflow"

## PDF Form Workflow
1. Extract form fields (scripts/extract_fields.py)
2. Validate field structure
3. Fill fields with data
4. Save and verify

## DOCX Workflow
1. Parse document structure (scripts/parse_docx.py)
2. Identify sections to modify
3. Apply changes using docx API
4. Preserve formatting
5. Output modified document

## Text Workflow
1. Read file content
2. Process with text manipulation
3. Write output
```

---

## Validation-Driven Workflows

For error-prone processes requiring checkpoints and error recovery.

### When to Use
- Operations that can fail midway
- Need to verify intermediate results
- Rollback or recovery options exist

### Example

```markdown
## Data Import Workflow

### Phase 1: Load Input

1. Read input file
2. **Validate format**: Check file structure and required fields
   - If validation fails: Return specific error message
   - If validation passes: Proceed to Phase 2

### Phase 2: Transform Data

1. Apply transformations
2. **Verify output**: Check transformed data integrity
   - If verification fails: Attempt recovery or abort
   - If verification passes: Proceed to Phase 3

### Phase 3: Write Output

1. Write to destination
2. **Confirm write**: Verify file exists and is readable
   - If confirmation fails: Report write error
   - If confirmation passes: Return success
```

---

## Retry/Fallback Workflows

For fragile operations with alternative approaches.

### When to Use
- External API calls that may fail
- Network-dependent operations
- Multiple implementation options available

### Example

```markdown
## API Data Fetch Workflow

### Primary Method (HTTP GET)

1. Attempt API call with timeout
2. **If successful after N retries**: Use response data
3. **If all retries failed**: Proceed to Fallback Method

### Fallback Method (Cached Data)

1. Check for cached data (within freshness threshold)
2. **If cache valid and recent**: Use cached data
3. **If cache invalid or missing**: Proceed to Final Fallback

### Final Fallback (Mock Data)

1. Return mock/sample data
2. Include warning that data is not live
3. Log the failure for debugging
```

---

## Parallel Processing Workflows

For independent tasks that can run simultaneously.

### When to Use
- Multiple operations with no dependencies
- Performance optimization needed
- Tasks are isolated from each other

### Example

```markdown
## Batch Report Generation

Execute these tasks in parallel:

- Task 1: Generate sales report
- Task 2: Generate inventory report
- Task 3: Generate user analytics report
- Task 4: Generate financial summary

After all tasks complete:

## Aggregation

1. Combine all reports into single document
2. Generate table of contents
3. Create executive summary
4. Output final package
```

---

## Stateful Workflows

For processes that need to maintain context across steps.

### When to Use
- Steps share common state or configuration
- Incremental builds or processing
- Need to track progress or decisions

### Example

```markdown
## Gradual Code Refactoring

**Maintain state file `refactor_state.json`:**

```json
{
  "current_phase": "identify_candidates",
  "files_processed": [],
  "decisions_made": [],
  "issues_encountered": []
}
```

### Phase 1: Identify Candidates

1. Scan codebase for refactoring opportunities
2. Write candidates to `refactor_state.json`
3. Save checkpoint

### Phase 2: Plan Changes

1. Load `refactor_state.json`
2. For each candidate: Determine refactoring approach
3. Update state with decisions
4. Save checkpoint

### Phase 3: Execute Refactorings

1. Load `refactor_state.json`
2. Apply changes in order
3. Update progress in state
4. After each change: Verify compilation

### Phase 4: Verify

1. Run test suite
2. Check for regressions
3. Update state with results
4. Generate final report
```

---

## Choosing a Pattern

| Pattern | Complexity | Error Prone | Parallelizable | Best For |
|----------|-------------|-------------|-----------------|-----------|
| Sequential | Low | Low | No | Fixed processes, clear dependencies |
| Conditional | Medium | Low | No | Binary decisions, distinct approaches |
| Decision Tree | High | Low | No | Multi-variant tasks, type-specific handling |
| Validation-Driven | Medium | High | No | Error-prone operations, data processing |
| Retry/Fallback | Medium | High | No | Fragile operations, APIs, network calls |
| Parallel Processing | Medium | Medium | Yes | Independent tasks, batch operations |
| Stateful | High | Medium | No | Incremental processing, context tracking |

---

## Common Mistakes to Avoid

❌ **Too many decision points**: If a workflow has >3 decision points, consider breaking into multiple workflows or using a Decision Tree instead.

❌ **Missing validation checkpoints**: Always validate before proceeding to the next step, especially for external inputs or file operations.

❌ **Overly complex state**: If stateful workflows become difficult to understand, consider simplifying or using Sequential workflows with intermediate file outputs.

❌ **No error recovery**: For Validation-Driven workflows, always define what happens when validation fails (abort, retry, or use fallback).

❌ **Unnecessary parallelism**: Parallel processing adds complexity. Only use when tasks are truly independent and performance matters.

❌ **No rollback mechanism**: For multi-step workflows that modify resources, ensure you can rollback or undo changes if later steps fail.
