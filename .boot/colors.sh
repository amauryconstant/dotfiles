#!/usr/bin/env sh
# Boot-stack colours: rEFInd, Plymouth and the SDDM greeter.
#
# A fixed palette, NOT themes/current. Boot runs before the session, darkman
# flips the live theme twice a day, and every Plymouth change costs a sudo and a
# UKI rebuild -- so these screens follow one colourset chosen here, and a theme
# switch never touches them.
#
# Same ROLE names as themes/*/colors.sh (see its header), so the renderer and the
# lock screen share one vocabulary. A subset: only the roles a boot screen draws.
# Scrim is not a key -- like Theme.scrim it is a literal black.
#
# Measured by `mise run lint:theme-contrast` (boot section), not judged.

# Background of every boot screen; the password field body.
readonly GROUND_BASE="#0a0a0a"

# rEFInd selection tile; the field hairline (Theme.edge).
readonly GROUND_RAISED="#171717"

# Spinner track; rEFInd selection tile.
readonly GROUND_FLOAT="#262626"

# Clock, date, typed text, the greeter's one line.
readonly INK_PRIMARY="#ededed"

# rEFInd icon tint (the icons are desaturated, then mapped between this and GROUND_FLOAT).
readonly INK_SECONDARY="#a1a1a1"

# Caret, spinner head, focus ring, progress bar; rEFInd selection outline.
readonly SIGNAL_FOCUS="#e5e5e5"

# Export all for subshells
export GROUND_BASE GROUND_RAISED GROUND_FLOAT
export INK_PRIMARY INK_SECONDARY
export SIGNAL_FOCUS
