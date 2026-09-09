#!/usr/bin/env bash
# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/os-detect.sh
source "${SCRIPT_DIR}/lib/os-detect.sh"
# shellcheck source=lib/idempotent.sh
source "${SCRIPT_DIR}/lib/idempotent.sh"

: "${PHP_OS_RELEASE_FILE:=/etc/os-release}"

PHP_TARGET_VERSIONS=(8.2 8.3 8.4 8.5)

_PHP_PPA_ADDED=false

php_extension_names() {
  local version="$1"

  case "${version}" in
    8.2)
      echo "cli fpm common bz2 curl gd imagick intl mbstring mysql opcache readline xml zip"
      ;;
    8.3)
      echo "cli fpm common bcmath bz2 curl intl mbstring mysql opcache readline xml zip"
      ;;
    8.4)
      echo "cli fpm common bcmath curl intl mbstring mysql opcache pgsql readline sqlite3 xml zip"
      ;;
    8.5)
      echo "cli fpm common"
      ;;
    *)
      log_error "versão de PHP desconhecida: ${version}"
      return 1
      ;;
  esac
}

php_extension_packages() {
  local version="$1"
  local name
  local packages=()

  for name in $(php_extension_names "${version}"); do
    packages+=("php${version}-${name}")
  done

  echo "${packages[@]}"
}

_ensure_php_ppa() {
  if [[ "${_PHP_PPA_ADDED}" == true ]]; then
    return 0
  fi

  local codename
  codename="$(detect_ubuntu_codename "${PHP_OS_RELEASE_FILE}")"

  if ! is_supported_codename "${codename}"; then
    log_error "codename Ubuntu não suportado para PPA do PHP: ${codename}"
    return 1
  fi

  local ppa_codename
  ppa_codename="$(resolve_php_ppa_codename "${codename}")"

  local ppa_url
  ppa_url="$(resolve_php_ppa_url)"

  log_info "adicionando PPA ondrej/php (${ppa_url})"
  add-apt-repository -y "deb ${ppa_url} ${ppa_codename} main"

  _PHP_PPA_ADDED=true
}

_php_alternatives_priority() {
  local version="$1"
  echo "${version//./}0"
}

install_php_version() {
  local version="$1"
  local packages

  _ensure_php_ppa

  packages="$(php_extension_packages "${version}")"
  log_info "instalando PHP ${version}: ${packages}"
  # shellcheck disable=SC2086
  apt-get install -y ${packages}

  update-alternatives --install /usr/bin/php php "/usr/bin/php${version}" "$(_php_alternatives_priority "${version}")"

  local latest=""
  local candidate
  for candidate in "${PHP_TARGET_VERSIONS[@]}"; do
    if command -v "php${candidate}" &>/dev/null; then
      latest="${candidate}"
    fi
  done

  if [[ -n "${latest}" ]]; then
    update-alternatives --set php "/usr/bin/php${latest}"
  fi
}

php_install_all() {
  local version
  local marker

  for version in "${PHP_TARGET_VERSIONS[@]}"; do
    marker="php-${version}"

    if is_already_done "${marker}"; then
      log_info "PHP ${version} já instalado, pulando"
      continue
    fi

    install_php_version "${version}"
    mark_done "${marker}"
  done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  php_install_all "$@"
fi
