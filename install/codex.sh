#!/usr/bin/env bash
# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/idempotent.sh
source "${SCRIPT_DIR}/lib/idempotent.sh"

: "${CODEX_NPM_PACKAGE:=@openai/codex}"

install_codex() {
  log_info "instalando Codex CLI (npm install -g ${CODEX_NPM_PACKAGE})"
  npm install -g "${CODEX_NPM_PACKAGE}"
}

_codex_mark_pending_login() {
  log_info "login pendente: rode 'codex login' para autenticar"
  mark_pending_login "codex"
}

codex_install_all() {
  local marker="codex"

  if is_already_done "${marker}"; then
    log_info "Codex CLI já instalado, pulando"
  else
    install_codex
    mark_done "${marker}"
  fi

  _codex_mark_pending_login
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  codex_install_all "$@"
fi
