#!/usr/bin/env bash
# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

: "${DOTFILES_SOURCE_DIR:=${SCRIPT_DIR}/dotfiles}"
: "${DOTFILES_TARGET_HOME:=${HOME}}"

_dotfiles_source_line() {
  echo 'source ~/.bashrc_aliases'
}

ensure_bashrc_sources_aliases() {
  local bashrc_file="$1"
  local source_line
  source_line="$(_dotfiles_source_line)"

  touch "${bashrc_file}"

  if ! grep -qxF "${source_line}" "${bashrc_file}"; then
    printf '%s\n' "${source_line}" >>"${bashrc_file}"
  fi
}

install_bashrc_aliases() {
  local target_home="${1:-${DOTFILES_TARGET_HOME}}"

  log_info "copiando dotfiles/bashrc_aliases para ${target_home}/.bashrc_aliases"
  cp "${DOTFILES_SOURCE_DIR}/bashrc_aliases" "${target_home}/.bashrc_aliases"

  ensure_bashrc_sources_aliases "${target_home}/.bashrc"
}

dotfiles_install_all() {
  local target_home="${DOTFILES_TARGET_HOME}"

  install_bashrc_aliases "${target_home}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  dotfiles_install_all "$@"
fi
