#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  export CONFIG_LINUX_STATE_DIR="${BATS_TEST_TMPDIR}/state"
  # shellcheck source=install/php.sh
  source "${REPO_ROOT}/install/php.sh"
}

@test "8.2 pacotes batem byte-a-byte com a lista esperada" {
  run php_extension_packages "8.2"
  [ "$status" -eq 0 ]
  [ "$output" = "php8.2-cli php8.2-fpm php8.2-common php8.2-bz2 php8.2-curl php8.2-gd php8.2-imagick php8.2-intl php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-readline php8.2-xml php8.2-zip" ]
}

@test "8.3 pacotes batem byte-a-byte com a lista esperada" {
  run php_extension_packages "8.3"
  [ "$status" -eq 0 ]
  [ "$output" = "php8.3-cli php8.3-fpm php8.3-common php8.3-bcmath php8.3-bz2 php8.3-curl php8.3-intl php8.3-mbstring php8.3-mysql php8.3-opcache php8.3-readline php8.3-xml php8.3-zip" ]
}

@test "8.4 pacotes batem byte-a-byte com a lista esperada" {
  run php_extension_packages "8.4"
  [ "$status" -eq 0 ]
  [ "$output" = "php8.4-cli php8.4-fpm php8.4-common php8.4-bcmath php8.4-curl php8.4-intl php8.4-mbstring php8.4-mysql php8.4-opcache php8.4-pgsql php8.4-readline php8.4-sqlite3 php8.4-xml php8.4-zip" ]
}

@test "8.5 pacotes batem byte-a-byte com a lista esperada" {
  run php_extension_packages "8.5"
  [ "$status" -eq 0 ]
  [ "$output" = "php8.5-cli php8.5-fpm php8.5-common" ]
}

@test "nenhuma lista de versão contém xdebug" {
  for version in 8.2 8.3 8.4 8.5; do
    run php_extension_packages "${version}"
    [[ "$output" != *xdebug* ]]
  done
}
