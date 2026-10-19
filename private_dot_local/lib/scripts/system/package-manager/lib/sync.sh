#!/usr/bin/env bash

# Script: sync.sh
# Purpose: Install the declared package set; remove what the previous sync declared and this one doesn't
# Requirements: pacman, paru, flatpak, yq (tripwire)
#
# State: $APPLIED_FILE = declared ∩ actually installed after the last sync (one name per line,
# Flatpaks as `flatpak:<id>`). No file yet → record only, remove nothing.

SYNC_MAX_REMOVALS=10

# Lines of $2 not in $1 (both sorted, unique).
_set_minus() { comm -13 "$2" "$1" 2>/dev/null; }

# Names from stdin that are installed (pacman).
_filter_installed_pacman() {
	local n
	while IFS= read -r n; do
		[[ -n "$n" ]] && pacman -Qq "$n" >/dev/null 2>&1 && echo "$n"
	done
}

# Names from stdin (`flatpak:<id>`) that are installed.
_filter_installed_flatpak() {
	local installed id
	installed=$(flatpak list --user --app --columns=application 2>/dev/null | sort -u)
	while IFS= read -r id; do
		[[ -n "$id" ]] && grep -qxF "${id#flatpak:}" <<<"$installed" && echo "$id"
	done
}

_sync_refresh_mirrors() {
	command -v rate-mirrors >/dev/null 2>&1 || return 0
	local list=/etc/pacman.d/mirrorlist hours country
	[[ -f "$list" ]] || return 0
	hours=$((($(date +%s) - $(stat -c %Y "$list" 2>/dev/null || echo 0)) / 3600))
	[[ $hours -gt 24 ]] || return 0
	ui_info "Mirrors stale (${hours}h), refreshing..."
	country=$(curl -s ipinfo.io/country 2>/dev/null || echo US)
	rate-mirrors --protocol https --entry-country "$country" arch | sudo tee "$list" >/dev/null 2>&1
	sudo pacman -Sy >/dev/null 2>&1
}

_sync_flatpak_remote() {
	flatpak remote-list --user 2>/dev/null | grep -q '^flathub' && return 0
	flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
	flatpak update --appstream --user >/dev/null 2>&1 || true
}

cmd_sync() {
	local declared_file="" dry_run=false
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--dry-run) dry_run=true ;;
		-*)
			ui_error "Unknown flag: $1"
			return 1
			;;
		*) declared_file="$1" ;;
		esac
		shift
	done
	if [[ ! -r "$declared_file" ]]; then
		ui_error "Usage: package-manager sync <declared-file> [--dry-run]"
		return 1
	fi

	local tmp
	tmp=$(mktemp -d) || return 1
	# shellcheck disable=SC2064  # expand now: $tmp is local
	trap "rm -rf '$tmp'" RETURN

	# --- Declared set -------------------------------------------------------
	local declared="$tmp/declared" pac_decl="$tmp/pac_decl" fp_decl="$tmp/fp_decl"
	sed -e 's/[[:space:]]*#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$declared_file" |
		grep -v '^$' | sort -u >"$declared"
	grep -v '^flatpak:' "$declared" >"$pac_decl" || true
	grep '^flatpak:' "$declared" >"$fp_decl" || true
	if [[ ! -s "$pac_decl" ]]; then
		# A broken render must never read as "remove everything"
		ui_error "Declared set has no pacman packages — refusing to sync"
		return 1
	fi

	# --- Classify + tripwire ------------------------------------------------
	# Official/chaotic (in a sync repo): no local PKGBUILD → pacman. True AUR → tripwire → paru.
	local bootstrap=false official="" aur="" blocked="" pkg
	_tripwire_is_bootstrap && bootstrap=true
	while IFS= read -r pkg; do
		if pacman -Si "$pkg" >/dev/null 2>&1; then
			official+=" $pkg"
		else
			aur+=" $pkg"
			_tripwire_check "$pkg" || blocked+=" $pkg"
		fi
	done <"$pac_decl"

	if [[ -n "$blocked" ]]; then
		ui_error "AUR build files new/changed/unverifiable since approval — sync blocked:"
		for pkg in $blocked; do ui_error "  • $pkg"; done
		ui_warning "Review and approve, then re-apply:  package-manager approve$blocked"
		return 1
	fi

	# --- Removals: (previous applied − declared) ∩ installed -----------------
	local rm_pac="$tmp/rm_pac" rm_fp="$tmp/rm_fp" first_run=false
	: >"$rm_pac"
	: >"$rm_fp"
	if [[ -f "$APPLIED_FILE" ]]; then
		sort -u "$APPLIED_FILE" >"$tmp/prev"
		_set_minus "$tmp/prev" "$declared" >"$tmp/retired"
		grep -v '^flatpak:' "$tmp/retired" | _filter_installed_pacman >"$rm_pac" || true
		grep '^flatpak:' "$tmp/retired" | _filter_installed_flatpak >"$rm_fp" || true
	else
		first_run=true
	fi

	local rm_count
	rm_count=$(($(wc -l <"$rm_pac") + $(wc -l <"$rm_fp")))
	if [[ $rm_count -gt $SYNC_MAX_REMOVALS && "${PACKAGE_MANAGER_ALLOW_REMOVE:-}" != 1 ]]; then
		ui_error "$rm_count removals exceeds guard ($SYNC_MAX_REMOVALS) — re-run with PACKAGE_MANAGER_ALLOW_REMOVE=1 if intended"
		sed 's/^/  - /' "$rm_pac" "$rm_fp" >&2
		return 1
	fi

	if [[ "$dry_run" == true ]]; then
		ui_title "package-manager sync --dry-run"
		ui_info "official/chaotic:${official:- (none)}"
		ui_info "AUR (tripwire clean):${aur:- (none)}"
		ui_info "flatpak: $(wc -l <"$fp_decl") declared"
		ui_info "remove: $(cat "$rm_pac" "$rm_fp" | tr '\n' ' ')"
		[[ "$first_run" == true ]] && ui_info "no previous state — first sync would record only"
		return 0
	fi

	# --- Apply ---------------------------------------------------------------
	_sync_refresh_mirrors

	# Remove first so a driver swap's conflicting packages are gone before installs.
	# Mark retired as deps and let the orphan pass take them: one that is still a
	# dependency of something stays put instead of aborting the whole transaction.
	if [[ -s "$rm_pac" ]]; then
		ui_step "Retiring $(wc -l <"$rm_pac") package(s): $(tr '\n' ' ' <"$rm_pac")"
		xargs -r sudo pacman -D --asdeps <"$rm_pac" >/dev/null
	fi

	# Declared packages must be explicit, or the orphan pass would sweep one that was
	# first installed as a dependency.
	if [[ -n "$official" ]]; then
		ui_step "Installing official-repo packages (pacman)..."
		# shellcheck disable=SC2086  # intentional word splitting
		sudo pacman -S --needed --noconfirm $official || {
			ui_error "Official package install failed"
			return 1
		}
	fi
	if [[ -n "$aur" ]]; then
		ui_step "Installing AUR packages (paru, tripwire-approved)..."
		# shellcheck disable=SC2086
		paru -S --needed --noconfirm $aur || {
			ui_error "AUR package install failed"
			return 1
		}
	fi
	_filter_installed_pacman <"$pac_decl" | xargs -r sudo pacman -D --asexplicit >/dev/null

	# Bootstrap TOFU ended: record the AUR packages that just installed (only when this
	# run started unseeded, so an established host never silently approves anything).
	if [[ "$bootstrap" == true && -n "$aur" ]]; then
		ui_step "Seeding AUR trust database (first sync)..."
		_tripwire_seed
	fi

	# Orphan pass (retired packages marked as deps above, plus any stray orphans)
	local orphans
	orphans=$(paru -Qtdq 2>/dev/null || true)
	if [[ -n "$orphans" ]]; then
		ui_step "Removing orphans: $(tr '\n' ' ' <<<"$orphans")"
		# shellcheck disable=SC2086
		paru -Rns --noconfirm $orphans || ui_warning "Some orphans could not be removed — see above"
	fi

	# --- Flatpak -------------------------------------------------------------
	if command -v flatpak >/dev/null 2>&1; then
		mkdir -p "$HOME/.local/share/flatpak" "$HOME/.var/app"
		if [[ -s "$fp_decl" ]]; then
			ui_step "Installing $(wc -l <"$fp_decl") Flatpak package(s)..."
			_sync_flatpak_remote
			sed 's/^flatpak://' "$fp_decl" |
				xargs -r flatpak install -y --user --noninteractive flathub ||
				ui_warning "Some Flatpaks failed to install (non-fatal)"
		fi
		if [[ -s "$rm_fp" ]]; then
			ui_step "Retiring Flatpak(s): $(tr '\n' ' ' <"$rm_fp")"
			sed 's/^flatpak://' "$rm_fp" | xargs -r flatpak uninstall --user -y
			flatpak uninstall --user --unused -y >/dev/null 2>&1 || true
		fi
	fi

	# --- Record applied set: declared ∩ actually installed ---------------------
	{
		_filter_installed_pacman <"$pac_decl"
		_filter_installed_flatpak <"$fp_decl"
	} | sort -u >"$tmp/applied"
	mv "$tmp/applied" "$APPLIED_FILE.new" && mv "$APPLIED_FILE.new" "$APPLIED_FILE"

	if [[ "$first_run" == true ]]; then
		ui_info "State seeded ($(wc -l <"$APPLIED_FILE") packages) — no removals on first sync"
	fi

	if [[ -x "$HOME/.local/lib/scripts/core/hook-runner" ]]; then
		"$HOME/.local/lib/scripts/core/hook-runner" package-sync sync 2>/dev/null || true
	fi
	ui_success "Package sync complete"
}
