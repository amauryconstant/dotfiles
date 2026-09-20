#!/usr/bin/env bash
set -euo pipefail

# Report deployed files left behind by a staged source deletion.
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
	if [[ -e "$target" ]]; then
		orphans+=("$target")
	fi
done

[[ "${#orphans[@]}" -gt 0 ]] || exit 0

echo "Orphaned deployed files (source deleted, target still present):"
printf '  %s\n' "${orphans[@]}"
echo
echo "Remove them with (one line -- a wrapped paste runs each fragment as its"
echo "own command), then delete any directory it empties:"
printf '  rm -f'
printf ' %q' "${orphans[@]}"
echo
