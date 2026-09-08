#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  export CONFIG_LINUX_STATE_DIR="${BATS_TEST_TMPDIR}/state"
  # shellcheck source=lib/idempotent.sh
  source "${REPO_ROOT}/lib/idempotent.sh"
}

@test "mark_done seguido de is_already_done retorna verdadeiro" {
  mark_done "php"

  run is_already_done "php"
  [ "$status" -eq 0 ]
}

@test "marker nunca marcado retorna falso" {
  run is_already_done "never-marked"
  [ "$status" -ne 0 ]
}

@test "markers distintos são independentes" {
  mark_done "php"

  run is_already_done "node"
  [ "$status" -ne 0 ]

  run is_already_done "php"
  [ "$status" -eq 0 ]
}

@test "mark_done é seguro de chamar 2x seguidas" {
  mark_done "docker"
  mark_done "docker"

  run is_already_done "docker"
  [ "$status" -eq 0 ]
}
