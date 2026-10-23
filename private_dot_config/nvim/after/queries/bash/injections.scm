; extends

; `#MISE` header lines in file tasks (.mise/tasks/**) are TOML. No `#USAGE`/kdl: nothing here uses it.
; Source: https://mise.jdx.dev/mise-cookbook/neovim.html

; #MISE format
((comment) @injection.content
  (#lua-match? @injection.content "^#MISE ")
  (#offset! @injection.content 0 6 0 1)
  (#set! injection.language "toml"))

; # MISE format
((comment) @injection.content
  (#lua-match? @injection.content "^# MISE ")
  (#offset! @injection.content 0 7 0 1)
  (#set! injection.language "toml"))

; #[MISE] format
((comment) @injection.content
  (#lua-match? @injection.content "^#%[MISE%] ")
  (#offset! @injection.content 0 8 0 1)
  (#set! injection.language "toml"))

; # [MISE] format
((comment) @injection.content
  (#lua-match? @injection.content "^# %[MISE%] ")
  (#offset! @injection.content 0 9 0 1)
  (#set! injection.language "toml"))
