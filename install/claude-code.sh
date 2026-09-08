#!/usr/bin/env bash
# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/idempotent.sh
source "${SCRIPT_DIR}/lib/idempotent.sh"

: "${CLAUDE_CODE_INSTALL_URL:=https://claude.ai/install.sh}"

install_claude_code() {
  log_info "instalando Claude Code CLI (${CLAUDE_CODE_INSTALL_URL})"
  curl -fsSL "${CLAUDE_CODE_INSTALL_URL}" | bash
}

_claude_code_mark_pending_login() {
  log_info "login pendente: rode 'claude login' para autenticar"
  mark_pending_login "claude"
}

claude_code_install_all() {
  local marker="claude-code"

  if is_already_done "${marker}"; then
    log_info "Claude Code CLI já instalado, pulando"
  else
    install_claude_code
    mark_done "${marker}"
  fi

  _claude_code_mark_pending_login
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  claude_code_install_all "$@"
fi
