#!/usr/bin/env bash
# Copy a tmux selection to the clipboard the attached terminal can use.
# Local tools cover a desktop session. OSC 52 covers SSH, where xclip and
# wl-copy are installed but have no display the host can see.
set -euo pipefail

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat >"$tmp"

if command -v pbcopy >/dev/null 2>&1; then
  pbcopy <"$tmp" || true
elif command -v clip.exe >/dev/null 2>&1; then
  clip.exe <"$tmp" || true
elif [[ -n "${WAYLAND_DISPLAY:-}" ]] && command -v wl-copy >/dev/null 2>&1; then
  wl-copy <"$tmp" || true
elif [[ -n "${DISPLAY:-}" ]] && command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard -in <"$tmp" >/dev/null || true
fi

# copy-pipe may not export TMUX. Use its socket when present.
if [[ -n "${TMUX:-}" ]]; then
  tmux -S "${TMUX%%,*}" load-buffer -w "$tmp"
else
  tmux load-buffer -w "$tmp"
fi
