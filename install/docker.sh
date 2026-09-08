#!/usr/bin/env bash
# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/os-detect.sh
source "${SCRIPT_DIR}/lib/os-detect.sh"
# shellcheck source=lib/idempotent.sh
source "${SCRIPT_DIR}/lib/idempotent.sh"

: "${DOCKER_OS_RELEASE_FILE:=/etc/os-release}"
: "${DOCKER_KEYRING_FILE:=/etc/apt/keyrings/docker.gpg}"
: "${DOCKER_SOURCES_LIST_FILE:=/etc/apt/sources.list.d/docker.list}"
: "${DOCKER_GPG_KEY_URL:=https://download.docker.com/linux/ubuntu/gpg}"

resolve_docker_repo_url() {
  local codename="$1"

  if ! is_supported_codename "${codename}"; then
    log_error "codename Ubuntu não suportado para repositório Docker: ${codename}"
    return 1
  fi

  echo "https://download.docker.com/linux/ubuntu"
}

_ensure_docker_repo() {
  local codename
  codename="$(detect_ubuntu_codename "${DOCKER_OS_RELEASE_FILE}")"

  local repo_url
  repo_url="$(resolve_docker_repo_url "${codename}")"

  log_info "adicionando repositório oficial do Docker (${repo_url})"

  mkdir -p "$(dirname -- "${DOCKER_KEYRING_FILE}")"
  curl -fsSL "${DOCKER_GPG_KEY_URL}" | gpg --dearmor -o "${DOCKER_KEYRING_FILE}"

  local arch
  arch="$(dpkg --print-architecture)"
  echo "deb [arch=${arch} signed-by=${DOCKER_KEYRING_FILE}] ${repo_url} ${codename} stable" >"${DOCKER_SOURCES_LIST_FILE}"

  apt-get update
}

install_docker() {
  _ensure_docker_repo

  log_info "instalando docker-ce docker-ce-cli containerd.io docker-compose-plugin"
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
}

_add_user_to_docker_group() {
  if id -nG "${USER}" | grep -qw docker; then
    log_info "usuário ${USER} já está no grupo docker, pulando"
    return 0
  fi

  log_info "adicionando usuário ${USER} ao grupo docker"
  usermod -aG docker "${USER}"
}

docker_install_all() {
  local marker="docker"

  if is_already_done "${marker}"; then
    log_info "Docker já instalado, pulando"
  else
    install_docker
    mark_done "${marker}"
  fi

  _add_user_to_docker_group
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  docker_install_all "$@"
fi
