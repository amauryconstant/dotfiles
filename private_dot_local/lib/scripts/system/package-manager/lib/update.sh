#!/usr/bin/env bash

# Script: update.sh
# Purpose: Tripwire-gated system + Flatpak update (topgrade pre-command)
# Requirements: pacman, paru, flatpak (optional)
#
# Never syncs or removes: the declared set (incl. NVIDIA driver choice) only exists inside chezmoi.

cmd_update() {
	local update_flatpak=true
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--no-flatpak) update_flatpak=false ;;
		*)
			ui_error "Unknown flag: $1"
			ui_info "Usage: package-manager update [--no-flatpak]"
			return 1
			;;
		esac
		shift
	done

	command -v paru >/dev/null 2>&1 || {
		ui_error "paru not found"
		return 1
	}

	ui_step "Updating Arch/AUR packages..."

	# Scan AUR packages with pending updates for PKGBUILD changes
	local -a aur_updates=()
	mapfile -t aur_updates < <(paru -Qua 2>/dev/null | awk '{print $1}')
	local blocked=""
	if [[ ${#aur_updates[@]} -gt 0 ]]; then
		blocked=$(_tripwire_scan "${aur_updates[@]}") || true
	fi

	if [[ -n "$blocked" ]]; then
		ui_warning "Tripwire held AUR upgrades (PKGBUILD changed or unapproved):"
		while IFS= read -r b; do
			[[ -n "$b" ]] && ui_warning "  • $b"
		done <<<"$blocked"
		ui_info "Review + approve: package-manager approve $(echo "$blocked" | tr '\n' ' ')"
		ui_step "Upgrading official repositories only (AUR held)..."
		sudo pacman -Syu --noconfirm || {
			ui_error "Official update failed"
			return 1
		}
		ui_warning "AUR upgrades skipped — approve held packages, then re-run 'package-manager update'"
	else
		# Direct call (paru needs a TTY for sudo prompts and progress)
		paru -Syu --noconfirm || {
			ui_error "Arch/AUR update failed"
			return 1
		}
	fi
	ui_success "Arch/AUR packages updated"

	if [[ "$update_flatpak" == true ]] && command -v flatpak >/dev/null 2>&1; then
		ui_step "Updating Flatpak packages..."
		flatpak update -y --user || ui_warning "Flatpak update failed (non-critical)"
	fi

	ui_success "System update complete"
}
