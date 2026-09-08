#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  FIXTURES_DIR="${REPO_ROOT}/tests/fixtures"
  export FAKE_CMD_LOG="${BATS_TEST_TMPDIR}/cmd.log"
  : > "${FAKE_CMD_LOG}"
  export PATH="${FIXTURES_DIR}:${PATH}"
  # shellcheck source=lib/common.sh
  source "${REPO_ROOT}/lib/common.sh"
  # shellcheck source=lib/os-detect.sh
  source "${REPO_ROOT}/lib/os-detect.sh"
}

@test "detecta e suporta codename noble (24.04)" {
  codename="$(detect_ubuntu_codename "${FIXTURES_DIR}/os-release-24.04")"
  [ "${codename}" = "noble" ]

  run is_supported_codename "${codename}"
  [ "$status" -eq 0 ]

  run resolve_php_ppa_url "${codename}"
  [ "$output" = "https://ppa.launchpadcontent.net/ondrej/php/ubuntu/dists/noble" ]
}

@test "detecta e suporta codename resolute (26.04)" {
  codename="$(detect_ubuntu_codename "${FIXTURES_DIR}/os-release-26.04")"
  [ "${codename}" = "resolute" ]

  run is_supported_codename "${codename}"
  [ "$status" -eq 0 ]

  run resolve_php_ppa_url "${codename}"
  [ "$output" = "https://ppa.launchpadcontent.net/ondrej/php/ubuntu/dists/resolute" ]
}

@test "Ubuntu não suportado (22.04/jammy) retorna falso" {
  codename="$(detect_ubuntu_codename "${FIXTURES_DIR}/os-release-22.04")"
  [ "${codename}" = "jammy" ]

  run is_supported_codename "${codename}"
  [ "$status" -ne 0 ]
}

@test "distro não-Ubuntu (Debian) retorna falso" {
  run is_supported_codename "$(detect_ubuntu_codename "${FIXTURES_DIR}/os-release-debian" || true)"
  [ "$status" -ne 0 ]
}

@test "PPA com suíte publicada (noble) resolve pro próprio codename, sem fallback" {
  run resolve_php_ppa_codename "noble"
  [ "$status" -eq 0 ]
  [ "$output" = "noble" ]
}

@test "PPA sem suíte publicada ainda (resolute/26.04) cai pro fallback noble" {
  run resolve_php_ppa_codename "resolute"
  [ "$status" -eq 0 ]
  # log_warn vai pro stderr, então $output combina aviso + valor; o valor
  # resolvido é sempre a última linha impressa.
  [ "$(tail -n1 <<<"$output")" = "noble" ]
}
