---
description: Check for new releases in omarchy with AI-powered semantic classification and integration recommendations
allowed-tools: Bash(bash:*), Read, Task(subagent_type:general-purpose)
---

# Omarchy Release Tracker

Check for new version releases in the omarchy repository since the last check. Uses AI-powered semantic analysis to classify changes and identify integration opportunities.

## Instructions

1. Run the omarchy-changes script to fetch release data:

!`OMARCHY_AUTO_UPDATE=true bash ~/.local/share/chezmoi/.claude/commands/omarchy-changes/script.sh`

The script will:
- Check for new version tags (e.g., v3.2.2 → v3.2.3)
- Fetch release notes from GitHub
- Output formatted release data for analysis

2. When the script outputs "RELEASE DATA FOR AI CLASSIFICATION", invoke the omarchy-release-classifier agent to analyze:

Use the Task tool with the omarchy-release-classifier agent, passing the release data as context.

3. Review the AI classification:
   - **Semantic categories**: Features, bug fixes, breaking changes, improvements
   - **Integration opportunities**: Specific recommendations for dotfiles
   - **Package changes**: New packages to consider
   - **Configuration updates**: Config file changes to review
   - **Recommended actions**: Prioritized next steps

4. If the user wants to explore specific changes:
   - Read relevant files from `~/Projects/omarchy/`
   - Explain what changed and implementation details
   - Suggest adaptation strategies for chezmoi dotfiles
   - Consider existing patterns (see CLAUDE.md files)

5. For integration tasks:
   - Show omarchy's implementation approach
   - Propose chezmoi-compatible adaptation (templates, packages, scripts)
   - Align with existing conventions and architecture
   - Reference relevant CLAUDE.md documentation

## Example Workflow

```
User: /omarchy-changes

Script runs:
→ Fetching updates from omarchy repository...
→ Release: v3.2.3
→ Fetching release notes from GitHub...
→ [RELEASE DATA FOR AI CLASSIFICATION output]

You analyze with omarchy-release-classifier:
→ ## Release Summary: Omarchy v3.2.3
→ ### Features (5 items)
→ - Alacritty fallback for terminal compatibility
→ - Channel switching (stable/edge/dev)
→ ...
→ ### Integration Opportunities
→ 1. **Alacritty fallback pattern** (Priority: High)
→    - Review: bin/omarchy-launch-terminal
→    ...

User explores integration:
"Tell me more about the Alacritty fallback pattern"

You read ~/Projects/omarchy/bin/omarchy-launch-terminal:
→ [Explain implementation and suggest adaptation]
```

## Notes

- The script handles state migration from commit-based to tag-based tracking automatically
- Multiple releases are processed if the user hasn't checked in a while
- GitHub release notes are preferred; falls back to commit summaries if unavailable
- State updates after user reviews classifications
