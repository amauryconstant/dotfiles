#!/usr/bin/env sh

# Script: chezmoi-merge-guard.sh
# Purpose: Wrapper for `merge.command` that refuses to merge generator entries
#          (modify_ scripts, modify-templates, *.tmpl) and delegates plain
#          files to mergiraf.
# Requirements: Arch Linux, mergiraf
# Usage: Invoked by `chezmoi merge` / `chezmoi merge-all` via merge.command
# Args: <source> <destination> <target>   (order set by merge.args)
#
# WHY THIS EXISTS
#   `chezmoi merge` passes .Source = the raw source-state file. For a modify_
#   entry that is the *generator* (a chezmoi_modify_manager script or a native
#   modify-template), while .Destination/.Target are rendered config data.
#   A three-way merge across those is a category error, and the previous
#   `-o {{ .Source }}` argument made mergiraf write the merged result over the
#   generator — destroying it. Upstream has no `merge.exclude` and no per-entry
#   opt-out, so a wrapper is the only available guard.
#
# KNOWN LIMIT — this guard prevents corruption, it cannot repair it.
#   chezmoi's docs claim "If the target state cannot be computed ... a two-way
#   merge is performed instead." The implementation contradicts this:
#   internal/cmd/mergecmd.go carries a FIXME noting it "cannot fallback to a
#   two-way merge" because TargetStateEntry eagerly evaluates contents. So when
#   a source is *already* corrupt (shebang gone -> ENOEXEC), target-state
#   computation fails and merge-all aborts BEFORE this guard is ever invoked.
#   Recovery in that case is: git checkout HEAD -- <path>
#
# EXIT CODE CONTRACT — skipping MUST exit 0.
#   internal/cmd/mergeallcmd.go returns on the first doMerge error and has no
#   keepGoing check in that loop, so any non-zero exit aborts every remaining
#   entry. `-k/--keep-going` does not apply here.

set -eu

usage() {
	cat >&2 <<-EOF
		chezmoi-merge-guard.sh: expected exactly 3 arguments, got $#.

		  usage: $0 <source> <destination> <target>

		This is invoked by chezmoi via merge.command; the argument order is set
		by merge.args in .chezmoi.yaml.tmpl and MUST be Source, Destination,
		Target. If merge.args is ever removed, chezmoi appends its own defaults
		in Destination, Source, Target order — the inverse — and this guard
		would classify the rendered destination as a plain file and let mergiraf
		overwrite it. Refusing instead.
	EOF
	exit 2
}

[ "$#" -eq 3 ] || usage "$@"

source_path="$1"
destination_path="$2"
target_path="$3"

[ -f "$source_path" ] || {
	echo "chezmoi-merge-guard.sh: source is not a regular file: $source_path" >&2
	exit 2
}

# Classify by CONTENT first, then filename. Filename alone is insufficient:
# modify_opencode.jsonc has no .tmpl suffix, and modify_private_kwinrc has
# neither a suffix nor template syntax.
kind=""
advice=""

if head -n 1 "$source_path" | grep -q '^#!/usr/bin/env chezmoi_modify_manager'; then
	kind="chezmoi_modify_manager script"
	advice="chezmoi_modify_manager --smart-add $destination_path"
elif grep -q 'chezmoi:modify-template' "$source_path"; then
	# The marker is the bare string anywhere in the file — chezmoi strips every
	# line containing it and treats the rest as a template.
	kind="native modify-template"
	advice="chezmoi diff $destination_path   # then hand-edit the source"
else
	case "$(basename "$source_path")" in
	modify_*)
		kind="modify_ entry"
		advice="chezmoi diff $destination_path   # then hand-edit the source"
		;;
	*)
		case "$source_path" in
		*.tmpl)
			kind="template"
			advice="chezmoi diff $destination_path   # then hand-edit the source"
			;;
		esac
		;;
	esac
fi

if [ -n "$kind" ]; then
	cat >&2 <<-EOF
		⏭️  Skipping merge: $destination_path
		    source is a $kind, not a prior revision of the target.
		    Merging it would overwrite the generator with rendered data.

		    Use instead:
		      $advice
	EOF
	exit 0
fi

# Plain file: source is genuine content, so a three-way merge is meaningful and
# writing the result back into the source dir is chezmoi's intended idiom.
exec mergiraf merge "$source_path" "$destination_path" "$target_path" -o "$source_path"
