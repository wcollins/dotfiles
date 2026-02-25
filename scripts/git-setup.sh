#!/usr/bin/env bash
#
# git-setup - configure git identity and SSH signing key
#
# Creates ~/.gitconfig.local with user identity and signing key.
# Generates an ed25519 SSH key pair if one doesn't exist.
# Sets up ~/.ssh/allowed_signers for commit verification.
#
# Usage:
#   git-setup           Interactive setup (prompts for name/email)
#   git-setup --check   Verify current configuration
#   git-setup --help    Show this help message

set -euo pipefail

GITCONFIG_LOCAL="${HOME}/.gitconfig.local"
SSH_KEY_DIR="${HOME}/.ssh/keys"
SSH_KEY_PATH="${SSH_KEY_DIR}/github"
SSH_PUB_PATH="${SSH_KEY_DIR}/github.pub"
ALLOWED_SIGNERS="${HOME}/.ssh/allowed_signers"

info() { printf "[git-setup] %s\n" "$1"; }
error() { printf "[git-setup] ERROR: %s\n" "$1" >&2; }

show_help() {
  cat <<EOF
Usage: git-setup [command]

Commands:
  (none)     Interactive setup — prompts for name/email, configures SSH signing
  --check    Verify current git identity and signing configuration
  --help     Show this help message

What it does:
  1. Prompts for git user.name and user.email
  2. Checks for SSH key at ~/.ssh/keys/github — generates if missing
  3. Creates ~/.ssh/allowed_signers for commit verification
  4. Writes identity and signing key to ~/.gitconfig.local

After setup, add your key to GitHub (https://github.com/settings/ssh/new):
  - Once as 'Authentication Key' (for push/pull)
  - Once as 'Signing Key' (for verified commits)

On re-run, existing values are shown as defaults (press Enter to keep).
SSH key generation is skipped if the key already exists.

To add a passphrase to your key after setup:
  ssh-keygen -p -f ~/.ssh/keys/github
EOF
}

check_existing_config() {
  local current_name="" current_email=""
  if [[ -f "${GITCONFIG_LOCAL}" ]]; then
    current_name=$(git config --file "${GITCONFIG_LOCAL}" user.name 2>/dev/null || true)
    current_email=$(git config --file "${GITCONFIG_LOCAL}" user.email 2>/dev/null || true)
  fi
  printf '%s\n%s' "${current_name}" "${current_email}"
}

prompt_identity() {
  local current_name="$1" current_email="$2"
  local input_name input_email

  if [[ -n "${current_name}" ]]; then
    printf "  Name [%s]: " "${current_name}"
  else
    printf "  Name: "
  fi
  read -r input_name
  NAME="${input_name:-${current_name}}"

  if [[ -n "${current_email}" ]]; then
    printf "  Email [%s]: " "${current_email}"
  else
    printf "  Email: "
  fi
  read -r input_email
  EMAIL="${input_email:-${current_email}}"

  if [[ -z "${NAME}" || -z "${EMAIL}" ]]; then
    error "Name and email are required"
    exit 1
  fi
}

ensure_ssh_key() {
  mkdir -p "${SSH_KEY_DIR}"
  chmod 700 "${HOME}/.ssh"
  chmod 700 "${SSH_KEY_DIR}"

  if [[ -f "${SSH_KEY_PATH}" && -f "${SSH_PUB_PATH}" ]]; then
    info "SSH key exists at ${SSH_KEY_PATH}"
    return
  fi

  if [[ -f "${SSH_KEY_PATH}" && ! -f "${SSH_PUB_PATH}" ]]; then
    error "Private key exists but public key missing at ${SSH_PUB_PATH}"
    error "Regenerate with: ssh-keygen -y -f ${SSH_KEY_PATH} > ${SSH_PUB_PATH}"
    exit 1
  fi

  info "Generating ed25519 SSH key pair..."
  ssh-keygen -t ed25519 -C "${EMAIL}" -f "${SSH_KEY_PATH}" -N ""
  info "SSH key pair created at ${SSH_KEY_PATH}"
}

setup_allowed_signers() {
  local pub_key
  pub_key=$(cat "${SSH_PUB_PATH}")
  local signer_entry="${EMAIL} ${pub_key}"

  mkdir -p "$(dirname "${ALLOWED_SIGNERS}")"

  if [[ -f "${ALLOWED_SIGNERS}" ]]; then
    # Remove existing entry for this email, then add current one
    local escaped_email
    escaped_email=$(printf '%s' "${EMAIL}" | sed 's/[.[\*^$()+?{|\\]/\\&/g')
    local tmp
    tmp=$(grep -v "^${escaped_email} " "${ALLOWED_SIGNERS}" 2>/dev/null || true)
    if [[ -n "${tmp}" ]]; then
      printf '%s\n' "${tmp}" > "${ALLOWED_SIGNERS}"
    else
      : > "${ALLOWED_SIGNERS}"
    fi
  fi

  echo "${signer_entry}" >> "${ALLOWED_SIGNERS}"

  info "Updated ${ALLOWED_SIGNERS}"
}

write_gitconfig_local() {
  git config --file "${GITCONFIG_LOCAL}" user.name "${NAME}"
  git config --file "${GITCONFIG_LOCAL}" user.email "${EMAIL}"
  git config --file "${GITCONFIG_LOCAL}" user.signingKey "${SSH_PUB_PATH}"

  info "Wrote identity and signing key to ${GITCONFIG_LOCAL}"
}

verify_config() {
  local ok=true

  info "Verifying configuration..."

  local name email key
  name=$(git config user.name 2>/dev/null || true)
  email=$(git config user.email 2>/dev/null || true)
  key=$(git config user.signingKey 2>/dev/null || true)

  [[ -n "${name}" ]]  && info "  user.name       = ${name}"  || { error "  user.name not set"; ok=false; }
  [[ -n "${email}" ]] && info "  user.email      = ${email}" || { error "  user.email not set"; ok=false; }
  [[ -n "${key}" ]]   && info "  user.signingKey = ${key}"   || { error "  user.signingKey not set"; ok=false; }

  [[ -f "${SSH_KEY_PATH}" ]] && info "  SSH key         = ${SSH_KEY_PATH}" || { error "  SSH key missing"; ok=false; }
  [[ -f "${ALLOWED_SIGNERS}" ]] && info "  allowed_signers = ${ALLOWED_SIGNERS}" || { error "  allowed_signers missing"; ok=false; }

  if [[ "${ok}" == true ]]; then
    info "Git signing is fully configured locally"
    info "  Ensure your key is added to GitHub as both Authentication and Signing key"
  else
    error "Configuration incomplete — run git-setup to fix"
    return 1
  fi
}

run_setup() {
  info "Configuring git identity and SSH signing..."
  echo ""

  local config_output current_name current_email
  config_output=$(check_existing_config)
  current_name=$(sed -n '1p' <<< "${config_output}")
  current_email=$(sed -n '2p' <<< "${config_output}")

  prompt_identity "${current_name}" "${current_email}"
  ensure_ssh_key
  setup_allowed_signers
  write_gitconfig_local

  echo ""
  verify_config

  echo ""
  info "Add this key to GitHub (https://github.com/settings/ssh/new):"
  info "  1. Add as 'Authentication Key' — for git push/pull over SSH"
  info "  2. Add as 'Signing Key' — for verified commit signatures"
  info "  Both are required. The same key can be used for both."
  echo ""
  cat "${SSH_PUB_PATH}"
}

# Parse arguments
CMD=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --check) CMD="check"; shift ;;
    --help)  CMD="help"; shift ;;
    *)       show_help; exit 1 ;;
  esac
done

case "${CMD}" in
  check) verify_config ;;
  help)  show_help ;;
  *)     run_setup ;;
esac
