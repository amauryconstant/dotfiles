#!/usr/bin/env sh
# Theme colours for shell scripts and for the Quickshell Theme singleton.
#
# 🚨 Named by ROLE, never by the module that spends the value. A token names a
# meaning ("is this broken?") or it names a consumer ("media", "performance"),
# and only the first kind can be reasoned about: a module-named scheme cannot
# even state the requirement that a CPU readout and a failed service must stay
# tellable apart. See design page Shell-01-Colour.
#
# A role is the question the interface asks; the value below is this theme's
# answer. Two roles sharing one value is not a defect on its own -- it is one
# only when it breaks the separation rule: the five SIGNAL roles stay mutually
# separable in every theme, and the IDENTITY slots stay separable from
# SIGNAL_ERROR and SIGNAL_FOCUS, the two roles a user acts on.
#
# Contrast is measured, not judged: `mise run lint:theme-contrast` reads all
# eight colorsets and checks the pairs the shell actually renders.
#
# Edited by hand. (An earlier header called this file generated from
# waybar.css; no such generator has ever existed in this repository.)

# GROUND -- what surface am I on? Fixed at three: a theme that cannot supply
# three separable surfaces is unsupportable rather than degraded.
# Bars, panels, popovers, the OSD. The only ground that may carry INK_SECONDARY.
readonly GROUND_BASE="#eff1f5"

# Rows at hover, chips, tracks, and every hairline. Carries INK_PRIMARY only.
readonly GROUND_RAISED="#ccd0da"

# Anything that casts a shadow: cards, tooltips, modals. INK_PRIMARY only.
readonly GROUND_FLOAT="#e6e9ef"

# MATERIAL -- what is this made of, if it is neither text nor signal?
# A MATERIAL, not a ground: meter and trough fill, the body of a disabled
# control. Owes 3:1 as a graphic and NEVER accepts text.
readonly FILL_INERT="#bcc0cc"

# INK -- how loud is this text?
# Every label, number and glyph. Legal on all three grounds.
readonly INK_PRIMARY="#4c4f69"

# Dates, footers, exec lines, empty states. Offered on GROUND_BASE only, and
# withdrawn by the consumer wherever it fails 4.5:1 against it.
readonly INK_SECONDARY="#5c5f77"

# TERMINAL ONLY, and the one role the shell may not draw: it fails both as
# text and as an outline. gum-ui.sh and organize-wallpapers-by-color still
# spend it, and a terminal is not a lit surface.
readonly INK_MUTED="#7c7f93"

# Never drawn directly. One of the two candidates a consumer measures when
# it needs ink ON a signal fill; the other candidate is GROUND_BASE.
readonly INK_CONTRAST_CANDIDATE="#dce0e8"

# SIGNAL -- what is the system telling me? Fixed at five, never collapsed.
# The one accent: attention, selection, the active thing, a primary action.
readonly SIGNAL_FOCUS="#1e66f5"

# Failure, and the top step of any urgency ramp.
readonly SIGNAL_ERROR="#d20f39"

# Degraded but working. The middle step of the ramp.
readonly SIGNAL_WARN="#df8e1d"

# Confirmation. Not "normal" -- a healthy system is neutral, not green.
readonly SIGNAL_OK="#40a02b"

# Connected, linked, in flight.
readonly SIGNAL_INFO="#179299"

# IDENTITY -- which of several like things is this? Elastic: assigned by
# index, never load-bearing, always redundant with a label or a position, so
# a theme repeating a value here is a valid answer rather than a defect.
readonly IDENTITY_1="#dc8a78"
readonly IDENTITY_2="#dd7878"
readonly IDENTITY_3="#ea76cb"
readonly IDENTITY_4="#8839ef"
readonly IDENTITY_5="#fe640b"

# Export all for subshells
export GROUND_BASE GROUND_RAISED GROUND_FLOAT
export FILL_INERT
export INK_PRIMARY INK_SECONDARY INK_MUTED INK_CONTRAST_CANDIDATE
export SIGNAL_FOCUS SIGNAL_ERROR SIGNAL_WARN SIGNAL_OK SIGNAL_INFO
export IDENTITY_1 IDENTITY_2 IDENTITY_3 IDENTITY_4 IDENTITY_5
