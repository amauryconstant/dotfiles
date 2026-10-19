#!/usr/bin/env bash

# Script: sync.sh
# Purpose: Install the declared package set; remove what the previous sync declared and this one doesn't
# Requirements: pacman, paru, flatpak, yq (tripwire)
#
# State: $APPLIED_FILE = declared ∩ actually installed after the last sync (one name per line,
# Flatpaks as `flatpak:<id>`). No file yet → record only, remove nothing.

SYNC_MAX_REMOVALS=10

# Lines of $2 not in $1 (both sorted, unique).
_set_minus() { comm -13 "$2" "$1"; }

# Fetch build files for the given AUR packages in parallel (max 8) into <dir>/<name>.blob.
_sync_prefetch() {
	local dir="$1" n running=0
	shift
	for n in "$@"; do
		(_tripwire_fetch "$n" >"$dir/$n.blob") &
		if ((++running >= 8)); then
			wait -n
			((running--))
		fi
	done
	wait
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
	# No bare `pacman -Sy` here: refreshing the DBs without upgrading is a partial upgrade
	# (it broke systemd-sysvcompat once). The new mirrors take effect on the next -Syu.
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
	# One set operation, not a `pacman -Si` per package (that was ~28 s on chaotic-aur).
	# In a sync repo (official/chaotic): no local PKGBUILD → pacman. Declared but in none → AUR.
	local installed="$tmp/installed" repo="$tmp/repo"
	pacman -Qq | sort -u >"$installed"
	pacman -Sl | awk '{print $2}' | sort -u >"$repo"
	if [[ ! -s "$repo" ]]; then
		ui_error "pacman -Sl returned nothing (sync databases missing?) — refusing to sync"
		return 1
	fi
	local off_all="$tmp/off_all" aur_all="$tmp/aur_all" off_todo="$tmp/off_todo" aur_todo="$tmp/aur_todo"
	comm -12 "$pac_decl" "$repo" >"$off_all"
	comm -23 "$pac_decl" "$repo" >"$aur_all"
	comm -23 "$off_all" "$installed" >"$off_todo"
	# AUR packages this sync would build: missing, or upgradable (paru -S rebuilds those).
	# An installed, current one is never built here, so gating it would be wasted network.
	{
		comm -23 "$aur_all" "$installed"
		paru -Qua 2>/dev/null | awk '{print $1}' | sort -u | comm -12 - "$aur_all"
	} | sort -u >"$aur_todo"

	local bootstrap=false blocked="" pkg
	_tripwire_is_bootstrap && bootstrap=true
	if [[ -s "$aur_todo" ]]; then
		mkdir -p "$tmp/blobs"
		local -a _todo=()
		mapfile -t _todo <"$aur_todo"
		_sync_prefetch "$tmp/blobs" "${_todo[@]}"
		for pkg in "${_todo[@]}"; do
			_tripwire_check "$pkg" "$tmp/blobs/$pkg.blob" || blocked+=" $pkg"
		done
	fi

	if [[ -n "$blocked" ]]; then
		ui_error "AUR build files new/changed/unverifiable since approval — sync blocked:"
		for pkg in $blocked; do ui_error "  • $pkg"; done
		ui_warning "Review and approve, then re-apply:  package-manager approve$blocked"
		return 1
	fi
	ui_info "$(wc -l <"$pac_decl") declared: $(wc -l <"$off_todo") to install, $(wc -l <"$aur_todo") to build"

	# --- Removals: (previous applied − declared) ∩ installed -----------------
	local rm_pac="$tmp/rm_pac" rm_fp="$tmp/rm_fp" first_run=false
	: >"$rm_pac"
	: >"$rm_fp"
	if [[ -f "$APPLIED_FILE" ]]; then
		sort -u "$APPLIED_FILE" >"$tmp/prev"
		_set_minus "$tmp/prev" "$declared" >"$tmp/retired"
		grep -v '^flatpak:' "$tmp/retired" | comm -12 - "$installed" >"$rm_pac" || true
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
		ui_info "install (official/chaotic): $(tr '\n' ' ' <"$off_todo")"
		ui_info "build (AUR, tripwire clean): $(tr '\n' ' ' <"$aur_todo")"
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
		xargs -r sudo pacman -D --asdeps <"$rm_pac" >/dev/null || ui_warning "Could not mark retired packages as deps"
	fi

	if [[ -s "$off_todo" ]]; then
		ui_step "Installing official-repo packages (pacman)..."
		xargs -r sudo pacman -S --needed --noconfirm <"$off_todo" || {
			ui_error "Official package install failed"
			return 1
		}
	fi
	if [[ -s "$aur_todo" ]]; then
		ui_step "Building AUR packages (paru, tripwire-approved)..."
		xargs -r paru -S --needed --noconfirm <"$aur_todo" || {
			ui_error "AUR package install failed"
			return 1
		}
	fi

	# Declared packages must be explicit, or the orphan pass would sweep one that was first
	# installed as a dependency. Only the ones currently flagged as deps need touching.
	pacman -Qq | sort -u >"$installed"
	pacman -Qdq 2>/dev/null | sort -u | comm -12 - "$pac_decl" >"$tmp/to_explicit"
	if [[ -s "$tmp/to_explicit" ]]; then
		xargs -r sudo pacman -D --asexplicit <"$tmp/to_explicit" >/dev/null ||
			ui_warning "Could not mark declared packages explicit — the orphan pass may misjudge them"
	fi

	# Bootstrap TOFU ended: record the AUR packages that just installed (only when this
	# run started unseeded, so an established host never silently approves anything).
	if [[ "$bootstrap" == true && -s "$aur_all" ]]; then
		ui_step "Seeding AUR trust database (first sync)..."
		_tripwire_seed
	fi

	# Orphan pass, limited to what this sync retired: orphans the user installed --asdeps or by
	# hand are none of its business. -Rns also takes the retired package's now-unneeded deps.
	local orphans=""
	if [[ -s "$rm_pac" ]]; then
		orphans=$(comm -12 "$rm_pac" <(paru -Qtdq 2>/dev/null | sort -u) || true)
	fi
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
	# Retired packages that survived (still a dependency, failed uninstall) stay recorded so the
	# next sync retries and warns instead of forgetting them.
	pacman -Qq | sort -u >"$installed"
	{
		comm -12 "$pac_decl" "$installed"
		_filter_installed_flatpak <"$fp_decl"
		comm -12 "$rm_pac" "$installed"
		_filter_installed_flatpak <"$rm_fp"
	} | sort -u >"$tmp/applied"
	local survivors
	survivors=$(comm -12 <(sort -u "$rm_pac" "$rm_fp") "$tmp/applied" | tr '\n' ' ')
	[[ -n "$survivors" ]] && ui_warning "Retired but still installed (kept as a dependency?): $survivors"
	mv "$tmp/applied" "$APPLIED_FILE.new" && mv "$APPLIED_FILE.new" "$APPLIED_FILE"

	if [[ "$first_run" == true ]]; then
		ui_info "State seeded ($(wc -l <"$APPLIED_FILE") packages) — no removals on first sync"
	fi

	if [[ -x "$HOME/.local/lib/scripts/core/hook-runner" ]]; then
		"$HOME/.local/lib/scripts/core/hook-runner" package-sync sync 2>/dev/null || true
	fi
	ui_success "Package sync complete"
}
