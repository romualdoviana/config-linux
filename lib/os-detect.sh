#!/usr/bin/env bash
# shellcheck shell=bash

detect_ubuntu_codename() {
  local os_release_file="${1:-/etc/os-release}"

  if [[ ! -f "${os_release_file}" ]]; then
    return 1
  fi

  local id=""
  local codename=""
  # shellcheck disable=SC1090
  source <(grep -E '^(ID|VERSION_CODENAME)=' "${os_release_file}")
  id="${ID:-}"
  codename="${VERSION_CODENAME:-}"

  if [[ "${id}" != "ubuntu" ]] || [[ -z "${codename}" ]]; then
    return 1
  fi

  echo "${codename}"
}

is_supported_codename() {
  local codename="${1:-}"

  case "${codename}" in
    noble|resolute)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

resolve_php_ppa_url() {
  echo "https://ppa.launchpadcontent.net/ondrej/php/ubuntu"
}

# Fallback usado quando a PPA ondrej/php ainda não publicou pacotes pro
# codename atual (ex.: Ubuntu recém-lançado). Pacotes do ondrej costumam
# funcionar numa versão de Ubuntu à frente da suíte em que foram publicados.
PHP_PPA_FALLBACK_CODENAME="noble"

php_ppa_has_suite() {
  local codename="${1:-}"
  curl -fsSL -o /dev/null "$(resolve_php_ppa_url)/dists/${codename}/Release"
}

resolve_php_ppa_codename() {
  local codename="${1:-}"

  if php_ppa_has_suite "${codename}"; then
    echo "${codename}"
    return 0
  fi

  log_warn "PPA ondrej/php ainda não publica pacotes pra '${codename}'; usando '${PHP_PPA_FALLBACK_CODENAME}' como fallback"
  echo "${PHP_PPA_FALLBACK_CODENAME}"
}
