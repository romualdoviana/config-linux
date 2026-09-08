#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  FIXTURES_DIR="${REPO_ROOT}/tests/fixtures"

  export INSTALL_MODULES_DIR="${FIXTURES_DIR}/install-modules"
  export STUB_CALL_LOG="${BATS_TEST_TMPDIR}/calls.log"
  : >"${STUB_CALL_LOG}"

  export CONFIG_LINUX_STATE_DIR="${BATS_TEST_TMPDIR}/state"
  export CONFIG_LINUX_PENDING_LOGINS_DIR="${BATS_TEST_TMPDIR}/pending-logins"
}

@test "distro não suportada aborta antes de chamar qualquer módulo" {
  export INSTALL_OS_RELEASE_FILE="${FIXTURES_DIR}/os-release-22.04"

  run "${REPO_ROOT}/install.sh"

  [ "$status" -ne 0 ]
  [ ! -s "${STUB_CALL_LOG}" ]
}

@test "distro suportada chama todos os módulos na ordem certa" {
  export INSTALL_OS_RELEASE_FILE="${FIXTURES_DIR}/os-release-24.04"

  run "${REPO_ROOT}/install.sh"

  [ "$status" -eq 0 ]
  [ "$(cat "${STUB_CALL_LOG}")" = "$(printf 'CALLED:php\nCALLED:node\nCALLED:docker\nCALLED:claude-code\nCALLED:codex\nCALLED:dotfiles')" ]
}

@test "falha no docker impede claude-code, codex e dotfiles de rodar" {
  export INSTALL_OS_RELEASE_FILE="${FIXTURES_DIR}/os-release-24.04"
  export STUB_FAIL_MODULE="docker"

  run "${REPO_ROOT}/install.sh"

  [ "$status" -ne 0 ]

  local calls
  calls="$(cat "${STUB_CALL_LOG}")"
  [[ "${calls}" == *"CALLED:php"* ]]
  [[ "${calls}" == *"CALLED:node"* ]]
  [[ "${calls}" == *"CALLED:docker"* ]]
  [[ "${calls}" != *"CALLED:claude-code"* ]]
  [[ "${calls}" != *"CALLED:codex"* ]]
  [[ "${calls}" != *"CALLED:dotfiles"* ]]
}
