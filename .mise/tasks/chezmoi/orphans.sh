#!/usr/bin/env bash
set -euo pipefail

# Report deployed files left behind by a deleted chezmoi source.
#
# Usage: mise run chezmoi:orphans            staged deletions (the pre-commit hook)
#        mise run chezmoi:orphans -- --all   audit fully-owned dirs, exit 1 on findings
#
# 🚨 The fix is a `.chezmoiremove` entry, NOT an `rm`. chezmoi never removes a
# target because its source is gone; `.chezmoiremove` is what makes `chezmoi
# apply` delete it, here and on the other chassis. Only targets chezmoi does not
# already plan to remove (`chezmoi status --include=remove`) are reported, so a
# covered orphan is silent: the next apply clears it.
#
# 🚨 The hook form sees STAGED deletions only, so it goes blind the moment the
# commit lands (`git diff --cached` is empty). `--all` is the after-the-fact
# check: `chezmoi unmanaged` over directories chezmoi fully owns.
#
# 🚨 REPORTS, never removes. Deleting from $HOME unattended, inside a hook the
# user did not ask to run, is not a pre-commit hook's job -- the orphan is
# harmless until someone decides otherwise, and `rm` is one command away. Never
# blocks the commit either: exit 0 is unconditional.
#
# 🚨 The command printed at the end is `rm`, NOT `chezmoi destroy`. `destroy`
# only acts on MANAGED targets, and by the time this hook runs the source entry
# is already deleted -- so chezmoi answers `<target>: not managed` and removes
# nothing. This printed `chezmoi destroy` until 2026-09-21, when running it
# against 17 real orphans deleted zero of them.
#
# 🚨 `chezmoi target-path` STATS the source file, so it fails on exactly the
# case this hook exists for -- the source is already gone from the worktree.
# The fix is to hand chezmoi a source tree that still HAS the file: extract just
# the deleted paths from HEAD into a temp dir and ask with `--source`. That
# keeps chezmoi's own attribute rules (private_, executable_, dot_, encrypted_,
# .tmpl, ...) as the single authority, instead of re-implementing them in sed
# and getting one wrong in a year.
#
# This replaced a `chezmoi destroy "$file"` loop that never worked: it passed
# SOURCE paths to a command that takes TARGET paths, so chezmoi resolved them
# against the cwd, found nothing managed, and failed into a `|| true`. It also
# ran without a tty for a command that prompts. Every source deletion since it
# was written left its deployed file behind -- found 2026-09-12.

# Directories chezmoi owns outright: anything in them that is not managed is a
# leftover. ~/.config is deliberately not here -- apps write their own state.
OWNED_DIRS=(
	"$HOME/.local/lib/scripts"
	"$HOME/.config/quickshell"
	"$HOME/.config/hypr"
	"$HOME/.config/systemd/user"
)
# Unmanaged on purpose: written by a tool, a symlink farm or systemctl, never by us.
IGNORE_UNMANAGED=(
	".config/hypr/monitors.lua"    # HyprDynamicMonitors output
	".config/themes/current"       # theme-switcher symlink
	".config/systemd/user/*.wants" # systemctl enable
)

# Targets chezmoi already plans to delete on the next apply, relative to $HOME.
# Status lines are ` D <path>`.
pending=$(chezmoi status --include=remove 2>/dev/null | sed 's/^.. //' || true)

is_pending() {
	[[ -n "$pending" ]] && grep -Fxq -- "$1" <<<"$pending"
}

is_ignored() {
	local pattern
	for pattern in "${IGNORE_UNMANAGED[@]}"; do
		# shellcheck disable=SC2053 -- the pattern is a glob on purpose
		[[ "$1" == $pattern ]] && return 0
	done
	return 1
}

report() {
	echo "Not covered by .chezmoiremove (chezmoi will leave these in place):"
	printf '  %s\n' "$@"
	echo
	echo "Add them to .chezmoiremove, one per line, so chezmoi apply removes them on"
	echo "every machine. Stopping a running unit or process stays manual."
}

if [[ "${1:-}" == "--all" ]]; then
	found=()
	for dir in "${OWNED_DIRS[@]}"; do
		[[ -d "$dir" ]] || continue
		while IFS= read -r rel; do
			[[ -n "$rel" ]] || continue
			is_ignored "$rel" && continue
			is_pending "$rel" && continue
			found+=("$rel")
		done < <(chezmoi unmanaged "$dir" 2>/dev/null)
	done
	[[ "${#found[@]}" -gt 0 ]] || exit 0
	report "${found[@]}"
	exit 1
fi

git rev-parse --verify HEAD >/dev/null 2>&1 || exit 0

# -z and a null-delimited read: a source path may contain spaces.
# _ai/ is a vendored subtree, never chezmoi-managed -- its deletions are noise.
mapfile -d '' -t deleted < <(
	git diff --cached -z --name-status --diff-filter=D |
		while IFS= read -r -d '' status && IFS= read -r -d '' path; do
			[[ "$status" == D ]] || continue
			case "$path" in
			_ai/*) continue ;;
			*) printf '%s\0' "$path" ;;
			esac
		done
)

[[ "${#deleted[@]}" -gt 0 ]] || exit 0

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

git archive HEAD -- "${deleted[@]}" | tar -x -C "$tmp"

orphans=()
for path in "${deleted[@]}"; do
	# Not every deleted file is a chezmoi source: .mise/, _research/ and
	# anything in .chezmoiignore translate to a path that was never deployed.
	# The existence check below is what filters them, so a failure here is
	# only for paths chezmoi cannot name at all.
	target=$(chezmoi target-path --source "$tmp" "$tmp/$path" 2>/dev/null) || continue
	[[ -e "$target" ]] || continue
	rel="${target#"$HOME"/}"
	is_pending "$rel" && continue
	orphans+=("$rel")
done

[[ "${#orphans[@]}" -gt 0 ]] || exit 0

report "${orphans[@]}"
