#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  export CONFIG_LINUX_STATE_DIR="${BATS_TEST_TMPDIR}/state"
  # shellcheck source=install/php.sh
  source "${REPO_ROOT}/install/php.sh"
}

@test "versão já marcada como feita não chama install_php_version de novo" {
  mark_done "php-8.2"

  CALLED_VERSIONS=()
  install_php_version() {
    CALLED_VERSIONS+=("$1")
  }

  php_install_all

  [[ ! " ${CALLED_VERSIONS[*]} " == *" 8.2 "* ]]
  [[ " ${CALLED_VERSIONS[*]} " == *" 8.3 "* ]]
  [[ " ${CALLED_VERSIONS[*]} " == *" 8.4 "* ]]
  [[ " ${CALLED_VERSIONS[*]} " == *" 8.5 "* ]]
}
