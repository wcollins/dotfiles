#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/tmux/.config/tmux/copy-clipboard.sh"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

install_tool() {
  local dest="$1" name="$2" body="$3"
  mkdir -p "$dest"
  printf '%s\n' "$body" >"$dest/$name"
  chmod +x "$dest/$name"
}

tmux_body() {
  cat <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$TMUX_ARGS"
payload=
for arg in "$@"; do
  payload=$arg
done
if [ -f "$payload" ]; then
  cp "$payload" "$TMUX_PAYLOAD"
fi
exit "${TMUX_EXIT:-0}"
SH
}

record_body() {
  local payload_var="$1" args_var="${2:-}" extra="${3:-}"
  if [[ -n "$args_var" ]]; then
    cat <<SH
#!/bin/sh
printf '%s\\n' "\$@" > "\$$args_var"
cat > "\$$payload_var"
exit ${extra:-0}
SH
  else
    cat <<SH
#!/bin/sh
cat > "\$$payload_var"
exit ${extra:-0}
SH
  fi
}

prepare() {
  local bin="$1"
  rm -rf "$bin"
  mkdir -p "$bin"
  install_tool "$bin" tmux "$(tmux_body)"
  ln -s /usr/bin/mktemp "$bin/mktemp"
  ln -s /bin/cat "$bin/cat"
  ln -s /bin/cp "$bin/cp"
  ln -s /bin/rm "$bin/rm"
  rm -f "$TEST_DIR/tmux-args" "$TEST_DIR/tmux-payload" \
    "$TEST_DIR/pbcopy" "$TEST_DIR/xclip" "$TEST_DIR/xclip-args" \
    "$TEST_DIR/wlcopy" "$TEST_DIR/clip"
}

run_copy() {
  local bin="$1" input="$2" bash_bin
  bash_bin="$(command -v bash)"
  shift 2
  printf '%s' "$input" | env -i \
    PATH="$bin" \
    HOME="$TEST_DIR" \
    TMUX_ARGS="$TEST_DIR/tmux-args" \
    TMUX_PAYLOAD="$TEST_DIR/tmux-payload" \
    PBCOPY_PAYLOAD="$TEST_DIR/pbcopy" \
    XCLIP_ARGS="$TEST_DIR/xclip-args" \
    XCLIP_PAYLOAD="$TEST_DIR/xclip" \
    WLCOPY_PAYLOAD="$TEST_DIR/wlcopy" \
    CLIP_PAYLOAD="$TEST_DIR/clip" \
    "$@" \
    "$bash_bin" "$SCRIPT"
}

assert_file() {
  local path="$1" expected="$2" label="$3"
  [[ -f "$path" ]] || fail "$label: missing payload"
  cmp -s "$path" <(printf '%s' "$expected") || fail "$label: unexpected payload"
}

assert_absent() {
  local path="$1" label="$2"
  [[ ! -e "$path" ]] || fail "$label: unexpected $path"
}

assert_osc52() {
  local label="$1" input="$2"
  assert_file "$TEST_DIR/tmux-payload" "$input" "$label osc52"
  grep -q 'load-buffer' "$TEST_DIR/tmux-args" || fail "$label: tmux was not asked to load-buffer"
  grep -qx -- '-w' "$TEST_DIR/tmux-args" || fail "$label: tmux was not asked to set the terminal clipboard"
}

# Headless SSH: wl-copy and xclip exist, but no display. OSC 52 only.
prepare "$TEST_DIR/headless"
install_tool "$TEST_DIR/headless" wl-copy "$(record_body WLCOPY_PAYLOAD)"
install_tool "$TEST_DIR/headless" xclip "$(record_body XCLIP_PAYLOAD XCLIP_ARGS)"
run_copy "$TEST_DIR/headless" $'alpha\n'
assert_osc52 "headless" $'alpha\n'
assert_absent "$TEST_DIR/wlcopy" "headless"
assert_absent "$TEST_DIR/xclip" "headless"

# Wayland desktop prefers wl-copy over xclip, and still emits OSC 52.
prepare "$TEST_DIR/wayland"
install_tool "$TEST_DIR/wayland" wl-copy "$(record_body WLCOPY_PAYLOAD)"
install_tool "$TEST_DIR/wayland" xclip "$(record_body XCLIP_PAYLOAD XCLIP_ARGS)"
run_copy "$TEST_DIR/wayland" $'beta\n' WAYLAND_DISPLAY=wayland-1 DISPLAY=:0
assert_osc52 "wayland" $'beta\n'
assert_file "$TEST_DIR/wlcopy" $'beta\n' "wayland wl-copy"
assert_absent "$TEST_DIR/xclip" "wayland"

# X11 desktop writes the clipboard selection, not primary.
prepare "$TEST_DIR/x11"
install_tool "$TEST_DIR/x11" xclip "$(record_body XCLIP_PAYLOAD XCLIP_ARGS)"
run_copy "$TEST_DIR/x11" $'gamma\n' DISPLAY=:0
assert_osc52 "x11" $'gamma\n'
assert_file "$TEST_DIR/xclip" $'gamma\n' "x11 xclip"
grep -q 'clipboard' "$TEST_DIR/xclip-args" || fail "x11: xclip selection was not clipboard"

# A failed local tool must not skip OSC 52.
prepare "$TEST_DIR/x11-fail"
# shellcheck disable=SC2016
install_tool "$TEST_DIR/x11-fail" xclip "$(record_body XCLIP_PAYLOAD XCLIP_ARGS '${XCLIP_EXIT:-0}')"
run_copy "$TEST_DIR/x11-fail" 'delta' DISPLAY=:0 XCLIP_EXIT=1
assert_osc52 "x11-fail" "delta"

# macOS and WSL local tools still reach OSC 52.
prepare "$TEST_DIR/mac"
install_tool "$TEST_DIR/mac" pbcopy "$(record_body PBCOPY_PAYLOAD)"
install_tool "$TEST_DIR/mac" xclip "$(record_body XCLIP_PAYLOAD XCLIP_ARGS)"
run_copy "$TEST_DIR/mac" 'epsilon' DISPLAY=:0
assert_osc52 "mac" "epsilon"
assert_file "$TEST_DIR/pbcopy" "epsilon" "mac pbcopy"
assert_absent "$TEST_DIR/xclip" "mac"

prepare "$TEST_DIR/wsl"
install_tool "$TEST_DIR/wsl" clip.exe "$(record_body CLIP_PAYLOAD)"
run_copy "$TEST_DIR/wsl" 'zeta'
assert_osc52 "wsl" "zeta"
assert_file "$TEST_DIR/clip" "zeta" "wsl clip.exe"

# Custom tmux socket from TMUX is forwarded.
prepare "$TEST_DIR/socket"
run_copy "$TEST_DIR/socket" 'eta' TMUX="/tmp/tmux-custom.sock,99,0"
assert_osc52 "socket" "eta"
grep -q '/tmp/tmux-custom.sock' "$TEST_DIR/tmux-args" || fail "socket: custom socket was not used"

printf 'ok\n'
