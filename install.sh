#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${REPO_ROOT}/lib/common.sh"
# shellcheck source=lib/os-detect.sh
source "${REPO_ROOT}/lib/os-detect.sh"
# shellcheck source=lib/idempotent.sh
source "${REPO_ROOT}/lib/idempotent.sh"

: "${INSTALL_OS_RELEASE_FILE:=/etc/os-release}"
: "${INSTALL_MODULES_DIR:=${REPO_ROOT}/install}"

INSTALL_MODULE_ORDER=(php node docker claude-code codex dotfiles)
declare -A INSTALL_MODULE_STATUS

_install_gate_distro() {
  local codename

  if ! codename="$(detect_ubuntu_codename "${INSTALL_OS_RELEASE_FILE}")"; then
    log_error "não foi possível detectar uma distro Ubuntu suportada em ${INSTALL_OS_RELEASE_FILE}"
    exit 1
  fi

  if ! is_supported_codename "${codename}"; then
    log_error "distro Ubuntu '${codename}' não é suportada (suportado: 24.04/noble, 26.04/resolute)"
    exit 1
  fi
}

_install_module_function() {
  local module="$1"

  case "${module}" in
    php) echo "php_install_all" ;;
    node) echo "node_install_all" ;;
    docker) echo "docker_install_all" ;;
    claude-code) echo "claude_code_install_all" ;;
    codex) echo "codex_install_all" ;;
    dotfiles) echo "dotfiles_install_all" ;;
  esac
}

_install_module_label() {
  local module="$1"

  case "${module}" in
    php) echo "PHP" ;;
    node) echo "Node.js" ;;
    docker) echo "Docker" ;;
    claude-code) echo "Claude Code CLI" ;;
    codex) echo "Codex CLI" ;;
    dotfiles) echo "Dotfiles" ;;
  esac
}

_install_php_already_done() {
  local version

  for version in 8.2 8.3 8.4 8.5; do
    is_already_done "php-${version}" || return 1
  done

  return 0
}

_install_module_already_done() {
  local module="$1"

  case "${module}" in
    php) _install_php_already_done ;;
    node) is_already_done "nodejs" ;;
    docker) is_already_done "docker" ;;
    claude-code) is_already_done "claude-code" ;;
    codex) is_already_done "codex" ;;
    dotfiles) return 1 ;;
  esac
}

_install_run_module() {
  local module="$1"
  local func
  func="$(_install_module_function "${module}")"

  local status="instalado"
  if _install_module_already_done "${module}"; then
    status="já estava instalado — pulado"
  fi

  # shellcheck disable=SC1090
  source "${INSTALL_MODULES_DIR}/${module}.sh"

  "${func}"

  INSTALL_MODULE_STATUS["${module}"]="${status}"
}

_install_pending_logins() {
  local tool

  for tool in claude codex; do
    if is_pending_login "${tool}"; then
      echo "${tool}"
    fi
  done
}

_install_print_summary() {
  local module

  echo ""
  echo "== Resumo da instalação =="
  for module in "${INSTALL_MODULE_ORDER[@]}"; do
    printf '%s: %s\n' "$(_install_module_label "${module}")" "${INSTALL_MODULE_STATUS[${module}]}"
  done

  local pending
  pending="$(_install_pending_logins)"
  if [[ -n "${pending}" ]]; then
    echo ""
    echo "Logins pendentes:"
    local tool
    while IFS= read -r tool; do
      printf '  - %s\n' "${tool}"
    done <<<"${pending}"
  fi
}

install_main() {
  _install_gate_distro

  local module
  for module in "${INSTALL_MODULE_ORDER[@]}"; do
    _install_run_module "${module}"
  done

  _install_print_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  install_main "$@"
fi
