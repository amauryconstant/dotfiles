#!/usr/bin/env bash
set -euo pipefail

# Validate staged chezmoi source files that shellcheck never sees.
#
# lint/staged.sh only matches *.sh / *.bash / *.sh.tmpl, so modify_ generators
# and plain templates were previously unvalidated — which is how `chezmoi
# merge-all` was able to overwrite three generators with rendered data (and put
# a decrypted API key into a tracked file) without anything noticing.
#
# Three checks:
#   1. corruption   — regression against HEAD; a generator that LOST its marker
#   2. render       — `chezmoi cat` actually executes generators and parses
#                     chezmoi_modify_manager directives
#   3. secrets      — gitleaks over the staged diff

# Paths are NUL-separated: one tracked path contains a literal backslash
# (private_dot_config/systemd/user/app-nm\x2dapplet@autostart.service.d/...).
mapfile -d '' -t staged < <(git diff --cached --name-only --diff-filter=ACM -z)

if [ ${#staged[@]} -eq 0 ]; then
	exit 0
fi

echo "🔍 Validating staged chezmoi source files..."

validation_failed=0

# Managed target set, computed once.
#
# `chezmoi target-path` is a pure path computation: it succeeds even for
# chezmoi-IGNORED entries, happily returning e.g.
# /home/amaury/archives/kde/.config/kdeglobals for a file under archives/.
# `chezmoi cat` then fails with "not managed". So target-path cannot decide
# whether a generator is runnable — membership in `chezmoi managed` can.
managed_targets=$(chezmoi managed --path-style=absolute 2>/dev/null || true)

# has_marker <content> <marker-kind>
has_marker() {
	case "$2" in
	shebang) printf '%s' "$1" | head -n 1 | grep -q '^#!/usr/bin/env chezmoi_modify_manager' ;;
	modify-template) printf '%s' "$1" | grep -q 'chezmoi:modify-template' ;;
	template) printf '%s' "$1" | grep -q '{{' ;;
	esac
}

# Human-readable label + the recovery hint for a lost marker.
marker_label() {
	case "$1" in
	shebang) echo "chezmoi_modify_manager shebang" ;;
	modify-template) echo "chezmoi:modify-template marker" ;;
	template) echo "Go template syntax ({{ }})" ;;
	esac
}

for file in "${staged[@]}"; do
	# Vendored upstream subtrees are not ours to validate.
	case "$file" in
	_ai/*) continue ;;
	esac

	base=$(basename "$file")

	# Which markers must this file preserve?
	#
	# Scoped by filename on purpose: documentation files legitimately contain
	# the literal string "chezmoi:modify-template", so an unscoped check would
	# false-positive whenever a doc example is edited.
	markers=()
	case "$base" in
	modify_*) markers=(shebang modify-template template) ;;
	esac
	case "$file" in
	*.tmpl) markers+=(template) ;;
	esac

	if [ ${#markers[@]} -eq 0 ]; then
		continue
	fi

	# --- Check 1: corruption, as a REGRESSION against HEAD -------------------
	#
	# An absolute "every *.tmpl contains {{ }}" rule would false-positive on the
	# six legitimately template-free tracked .tmpl files (wlogout/style.css.tmpl,
	# voxtype/config.toml.tmpl, theme-switcher.tmpl, theme-menu.tmpl,
	# private_kdeglobals.tmpl, archives/kde/.../modify_private_kdeglobals.tmpl).
	# Comparing against HEAD and failing only on LOSS has no false positives and
	# needs no allowlist. Files new in this commit have no HEAD blob to compare.
	if head_content=$(git show "HEAD:$file" 2>/dev/null); then
		staged_content=$(git show ":$file")
		for marker in "${markers[@]}"; do
			if has_marker "$head_content" "$marker" && ! has_marker "$staged_content" "$marker"; then
				echo "    ❌ $file"
				echo "       lost its $(marker_label "$marker") since HEAD."
				echo "       A generator overwritten by rendered output looks exactly like this."
				echo "       Recover with: git checkout HEAD -- '$file'"
				validation_failed=1
			fi
		done
	fi

	# --- Check 2: render validation ------------------------------------------
	#
	# `chezmoi cat` renders the template AND executes the generator AND parses
	# every chezmoi_modify_manager directive AND performs the merge, exiting
	# non-zero on any failure.
	#
	# NOT `chezmoi execute-template`: it fails permanently on native
	# modify-templates ("map has no entry for key \"stdin\"", because with no
	# args the template itself is read from stdin so .chezmoi.stdin is never
	# set), and it PASSES on rendered-output corruption, since raw INI and JSON
	# are valid Go templates with zero actions.
	#
	# Caveat: chezmoi reads the WORKING TREE, not the staged blob — the same
	# limitation lint/staged.sh already accepts.
	if [[ "$base" == modify_* ]]; then
		if target=$(chezmoi target-path "$file" 2>/dev/null) &&
			printf '%s\n' "$managed_targets" | grep -qxF -- "$target"; then
			# Output is discarded deliberately: `chezmoi cat` on the opencode
			# target emits a DECRYPTED API key on stdout. Never log or tee it.
			if ! chezmoi cat "$target" >/dev/null 2>/tmp/chezmoi-cat-err.$$; then
				echo "    ❌ $file"
				echo "       generator failed to execute for target: $target"
				sed 's/^/       /' /tmp/chezmoi-cat-err.$$ >&2 || true
				validation_failed=1
			fi
			rm -f /tmp/chezmoi-cat-err.$$
		fi
	fi
done

# --- Check 3: secret scanning ------------------------------------------------
#
# Scoped backstop, not general coverage: default rules catch sk-* style tokens
# (the decrypted-key-into-source case) but will NOT catch a QSettings-obfuscated
# password in an INI file.
if command -v gitleaks >/dev/null 2>&1; then
	if ! gitleaks git --staged --no-banner --redact >/dev/null 2>&1; then
		echo "    ❌ gitleaks found a secret in the staged diff:"
		gitleaks git --staged --no-banner --redact 2>&1 | sed 's/^/       /' || true
		validation_failed=1
	fi
else
	echo "    ⚠️  gitleaks not installed — secret scan skipped"
fi

if [ $validation_failed -ne 0 ]; then
	echo ""
	echo "❌ chezmoi source validation failed!"
	echo ""
	echo "Fix issues above or:"
	echo "  - Skip validation: git commit --no-verify"
	echo "  - Preview output:  chezmoi cat <target-path>"
	echo "  - Recover a file:  git checkout HEAD -- <path>"
	exit 1
fi

echo "✅ Staged chezmoi source files passed validation"
