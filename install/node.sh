#!/usr/bin/env bash
# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/os-detect.sh
source "${SCRIPT_DIR}/lib/os-detect.sh"
# shellcheck source=lib/idempotent.sh
source "${SCRIPT_DIR}/lib/idempotent.sh"

: "${NODE_OS_RELEASE_FILE:=/etc/os-release}"
: "${NODE_KEYRING_FILE:=/usr/share/keyrings/nodesource.gpg}"
: "${NODE_SOURCES_LIST_FILE:=/etc/apt/sources.list.d/nodesource.list}"
: "${NODE_GPG_KEY_URL:=https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key}"

resolve_nodesource_repo_url() {
  local codename="$1"

  if ! is_supported_codename "${codename}"; then
    log_error "codename Ubuntu não suportado para repositório NodeSource: ${codename}"
    return 1
  fi

  echo "https://deb.nodesource.com/node_current.x"
}

_ensure_node_dependencies() {
  local missing=()
  local cmd

  for cmd in curl gpg; do
    command -v "${cmd}" &>/dev/null || missing+=("${cmd}")
  done

  if ((${#missing[@]} > 0)); then
    log_info "instalando dependências: ${missing[*]}"
    apt-get update
    apt-get install -y ca-certificates curl gnupg
  fi
}

_ensure_nodesource_repo() {
  _ensure_node_dependencies

  local codename
  codename="$(detect_ubuntu_codename "${NODE_OS_RELEASE_FILE}")"

  local repo_url
  repo_url="$(resolve_nodesource_repo_url "${codename}")"

  log_info "adicionando repositório NodeSource (${repo_url})"

  curl -fsSL "${NODE_GPG_KEY_URL}" | gpg --dearmor -o "${NODE_KEYRING_FILE}"
  echo "deb [signed-by=${NODE_KEYRING_FILE}] ${repo_url} nodistro main" >"${NODE_SOURCES_LIST_FILE}"

  apt-get update
}

install_node() {
  _ensure_nodesource_repo

  log_info "instalando nodejs"
  apt-get install -y nodejs
}

node_install_all() {
  local marker="nodejs"

  if is_already_done "${marker}"; then
    log_info "Node.js já instalado, pulando"
    return 0
  fi

  install_node
  mark_done "${marker}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  node_install_all "$@"
fi
