#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  export CONFIG_LINUX_STATE_DIR="${BATS_TEST_TMPDIR}/state"
  export CONFIG_LINUX_PENDING_LOGINS_DIR="${BATS_TEST_TMPDIR}/pending-logins"
  # shellcheck source=install.sh
  source "${REPO_ROOT}/install.sh"
}

@test "sem markers de pendência, lista de pendências fica vazia" {
  run _install_pending_logins

  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "com marker de claude pendente, lista contém exatamente claude" {
  mark_pending_login "claude"

  run _install_pending_logins

  [ "$output" = "claude" ]
}

@test "com markers de claude e codex pendentes, lista contém exatamente os dois" {
  mark_pending_login "claude"
  mark_pending_login "codex"

  run _install_pending_logins

  [ "$output" = "$(printf 'claude\ncodex')" ]
}
