#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  export CONFIG_LINUX_PENDING_LOGINS_DIR="${BATS_TEST_TMPDIR}/pending-logins"
  # shellcheck source=lib/idempotent.sh
  source "${REPO_ROOT}/lib/idempotent.sh"
}

@test "marcar login pendente 2x seguidas resulta em um único marker" {
  mark_pending_login "codex"
  mark_pending_login "codex"

  run find "${CONFIG_LINUX_PENDING_LOGINS_DIR}" -type f -name "codex"
  [ "${#lines[@]}" -eq 1 ]

  run is_pending_login "codex"
  [ "$status" -eq 0 ]
}

@test "limpar pendência é idempotente e marker não reaparece sozinho" {
  mark_pending_login "codex"

  clear_pending_login "codex"
  clear_pending_login "codex"

  run is_pending_login "codex"
  [ "$status" -ne 0 ]
}
