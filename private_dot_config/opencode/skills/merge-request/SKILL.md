---
name: merge-request
description: Generate markdown-formatted merge request/PR descriptions and titles. Analyzes branch changes against target branch (default: main, auto-detects alternatives). Use when user asks to create MR/PR, "write PR description", or for help with merge request content.
license: MIT
---

Generate markdown-formatted merge request/PR descriptions and titles.

**Input**: Optionally specify a target branch. If omitted, default to `main` and auto-detect alternatives. If multiple targets exist, ask user to select.

## When to Use

- User wants to create a merge request/PR
- User asks "write PR description" / "MR description"
- User mentions creating MR/PR for current branch
- User asks for help with MR/PR content

**Steps**

1. **Determine current branch and target**

   ```bash
   git branch --show-current
   git branch -r | grep -E 'origin/(main|master|develop)$' | sed 's|origin/||'
   ```

   - Use provided target branch if specified
   - Default to `main`
   - If multiple targets detected, ask user:
     ```
     Multiple target branches detected: main, master, develop
     Which branch should be used for comparison?
     ```
   - Always announce: "Target branch: <name>" and "Current branch: <name>"

2. **Get change context**

   ```bash
   # Find divergence point
   MERGE_BASE=$(git merge-base <target> HEAD)

   # Commits since divergence
   git log <target>..HEAD --oneline

   # Files changed summary
   git diff <target>...HEAD --stat

   # Full diff (only if needed for understanding)
   git diff <target>...HEAD
   ```

3. **Analyze overall change purpose**

   - Identify primary change type: feature, bugfix, refactor, docs, chore
   - Group related changes logically
   - If purpose is unclear → Read key files or **ask user** for motivation
   - Determine if breaking changes exist

4. **Draft MR title**

   - More flexible than commit titles (aim ≤100 chars if possible)
   - Descriptive but concise
   - Can use different tenses/styles (not strictly imperative)
   - Focus on what was accomplished, not implementation

   See [references/guidelines.md](references/guidelines.md) for title guidelines and examples.

5. **Draft MR description**

   Follow this structure:

   ```markdown
   ### Summary
   [Brief overview of what was accomplished]

   ### Changes
   - [Category]: [Description]
   - [Category]: [Description]

   ### Testing
   [How reviewers can verify the changes]

   ### Breaking Changes
   [Any breaking changes or migration notes, if applicable]

   ### Related Issues
   [Issue numbers or links, if applicable]
   ```

   **Section guidelines**:
   - **Summary**: 2-3 sentences, high-level purpose
   - **Changes**: Bullet points organized by category
   - **Testing**: Specific steps (omit if obvious)
   - **Breaking Changes**: Only include if applicable
   - **Related Issues**: Optional

6. **Present to user for review**

   Display title and description in markdown format. Ask user to:
   1. Copy and use as-is
   2. Make revisions
   3. Regenerate with different focus

**Output Format**


      ## Merge Request Description

      **Title**: <title>

      ```markdown
      ### Summary
      <summary>

      ### Changes
      - <change 1>
      - <change 2>

      ### Testing
      <testing guidance>
      ```

      Choose an option:

      1. Copy this description for you
      2. Make revisions
      3. Regenerate with different focus


**Guardrails**
- Always check current branch before starting
- Auto-detect target branches (`main`, `master`, `develop`) before asking
- Read key files only if change purpose is unclear from diff
- Keep descriptions concise and reviewer-focused
- Don't list every file changed - summarize by category
- Include testing guidance for non-trivial changes
- Ask user for clarification if purpose is unclear
- Don't guess motivation - ask if ambiguous
- Use `###` for section headers (copy-paste ready)
- Output must be markdown-formatted for GitHub/GitLab
- Pause if breaking changes detected and confirm with user

**References**

- **Examples**: See [references/examples.md](references/examples.md) for detailed MR examples (simple features, bugfixes, refactors, documentation)
- **Special cases**: See [references/special-cases.md](references/special-cases.md) for WIP MRs, backports, breaking changes, security fixes, performance improvements
- **Guidelines**: See [references/guidelines.md](references/guidelines.md) for title guidelines, anti-patterns, and validation checklist
- **Git documentation**: `git help diff`, `git help log`, `git help merge-base`
