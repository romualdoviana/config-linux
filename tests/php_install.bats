#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  FIXTURES_DIR="${REPO_ROOT}/tests/fixtures"
  export FAKE_CMD_LOG="${BATS_TEST_TMPDIR}/cmd.log"
  : > "${FAKE_CMD_LOG}"
  export PATH="${FIXTURES_DIR}:${PATH}"
  export PHP_OS_RELEASE_FILE="${FIXTURES_DIR}/os-release-24.04"
  export CONFIG_LINUX_STATE_DIR="${BATS_TEST_TMPDIR}/state"
  # shellcheck source=install/php.sh
  source "${REPO_ROOT}/install/php.sh"
}

@test "install_php_version 8.2 pede exatamente os pacotes da lista 8.2" {
  install_php_version "8.2"

  run grep "^apt-get install" "${FAKE_CMD_LOG}"
  [ "$status" -eq 0 ]
  [ "$output" = "apt-get install -y php8.2-cli php8.2-fpm php8.2-common php8.2-bz2 php8.2-curl php8.2-gd php8.2-imagick php8.2-intl php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-readline php8.2-xml php8.2-zip" ]
}

@test "chamar install_php_version pra duas versões na mesma sessão não duplica add-apt-repository" {
  install_php_version "8.2"
  install_php_version "8.3"

  run grep -c "^add-apt-repository" "${FAKE_CMD_LOG}"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "Ubuntu 26.04 (resolute) usa fallback noble na PPA quando a suíte resolute não existe" {
  PHP_OS_RELEASE_FILE="${FIXTURES_DIR}/os-release-26.04" install_php_version "8.2"

  run grep "^add-apt-repository" "${FAKE_CMD_LOG}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"/dists/noble"* ]]
  [[ "$output" == *" noble main"* ]]
}
