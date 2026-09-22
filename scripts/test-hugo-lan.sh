#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
trap 'rm -rf "$TEST_DIR"' EXIT
mkdir -p "$TEST_DIR/bin"

cat >"$TEST_DIR/bin/hugo" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$HUGO_ARGS"
exit "${HUGO_EXIT:-0}"
SH
chmod +x "$TEST_DIR/bin/hugo"

check_case() {
  local shell_path="$1" input="$2" expected_exit="$3" expected_ip="$4" hugo_exit="${5:-0}"
  local actual_exit=0
  local -a options
  case "$shell_path" in
  *zsh) options=(-f) ;;
  *) options=(--noprofile --norc) ;;
  esac
  rm -f "$TEST_DIR/args"
  # The child shell expands its own positional argument.
  # shellcheck disable=SC2016
  printf '%s' "$input" | env -i HOME="$TEST_DIR" PATH="$TEST_DIR/bin" \
    HUGO_ARGS="$TEST_DIR/args" HUGO_EXIT="$hugo_exit" \
    "$shell_path" "${options[@]}" -c 'source "$1"; hugo-lan' shell "$ROOT/shared/functions.sh" \
    >"$TEST_DIR/output" 2>&1 || actual_exit=$?

  if [[ "$actual_exit" != "$expected_exit" ]]; then
    printf 'Unexpected exit %s from %s (expected %s)\n' "$actual_exit" "$shell_path" "$expected_exit" >&2
    return 1
  fi
  if [[ -z "$expected_ip" ]]; then
    [[ ! -e "$TEST_DIR/args" ]]
    return
  fi
  printf '%s\n' server -D --bind "$expected_ip" --baseURL "http://$expected_ip:1313/" --port 1313 >"$TEST_DIR/expected"
  diff -u "$TEST_DIR/expected" "$TEST_DIR/args"
}

shells=("$(command -v bash)")
if command -v zsh >/dev/null 2>&1; then
  shells+=("$(command -v zsh)")
fi
for shell_path in "${shells[@]}"; do
  check_case "$shell_path" $'172.16.10.10\n' 0 '172.16.10.10'
  check_case "$shell_path" $'192.168.001.008\n' 0 '192.168.1.8'
  check_case "$shell_path" $'999.1.2.3\n0.0.0.0\nexample.com\n192.168.1.10\n' 0 '192.168.1.10'
  check_case "$shell_path" $'\n' 1 ''
  check_case "$shell_path" '' 1 ''
  check_case "$shell_path" $'192.168.1.10\n' 23 '192.168.1.10' 23
  printf 'Prompt, validation, arguments, cancellation, and exit checks passed: %s\n' "$shell_path"
done

rm "$TEST_DIR/bin/hugo"
for shell_path in "${shells[@]}"; do
  check_case "$shell_path" '' 127 ''
  printf 'Missing-Hugo check passed: %s\n' "$shell_path"
done
