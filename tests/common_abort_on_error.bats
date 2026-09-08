#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
}

@test "aborta no primeiro comando com erro e não executa o próximo" {
  run "${REPO_ROOT}/tests/fixtures/common_caller.sh"

  [ "$status" -ne 0 ]
  [[ "$output" != *"SHOULD_NOT_RUN"* ]]
}

@test "mensagem de erro identifica o comando que falhou" {
  run "${REPO_ROOT}/tests/fixtures/common_caller.sh"

  [[ "$output" == *"fake_command_exit1"* ]]
}
