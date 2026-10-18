---
name: commit
description: Write concise commit messages — imperative mood, ≤80 char subject, naming the dotfiles component touched (Hyprland, Quickshell, theme system, package-manager, Zsh, Firefox profiles). Use when the user asks to commit, create a commit, write a commit message, or for help with git commits.
model: haiku
allowed-tools: Read, Grep, Bash("git diff *"), Bash("git status *"), Bash("git log *"), Bash("git add *"), Bash("git show *"), Bash("git commit *")
---

# Commit Skill

Short, specific commit messages matching this repo's history.

## Steps

1. **Inspect** in parallel: `git status`, `git diff HEAD`, `git log -20 --format=%s`.
2. **Blockers**: nothing to commit → say so. Merge conflict (`both modified`) → resolve first. Only untracked files → suggest `git add <files>`.
3. **Split check**: unrelated changes, several features/fixes, or refactor mixed with a feature → propose separate commits (`git add <paths>` per commit) instead of one long message.
4. **Draft**, show it, and commit once the user approves (or if they already asked you to commit). Stage only what belongs to the commit.

## Subject line

- Imperative verb first: Add, Fix, Update, Remove, Retire, Document, Gate, Pin…
- ≤80 characters, capitalised, no trailing period
- Name the component and the real change — never a bare "Fix config" or "Update script"
- Components: Hyprland, Quickshell (bar, launcher, notifications, lock…), theme system, package-manager, Zsh, shell scripts, Ghostty, Firefox profiles, mise, chezmoi scripts/templates/modify entries, plans/research docs

Real examples from this repo:

```
Show NouTube in the Quickshell media widget
Pin Firefox profiles to fixed workspaces on the primary monitor
Retire swaync; the Quickshell shell always owns notifications
Gate hyprsplit workspace order to DP-1 first on desktop
Document that sync --prune cannot retire unrecorded packages
```

## Body (optional)

Only when the reasoning is not obvious from the diff: a blank line, then `- ` bullets of ≤72 chars explaining **why**. Skip it for self-explanatory changes. If the body wants to be long, split the commit.

## Hard rules

- Never commit files that look like secrets (`.env`, keys, decrypted `.age` content).
- Never `--amend`, force-push or skip hooks unless asked. If pre-commit fails, fix the cause and make a new commit.
- Don't push unless asked.
