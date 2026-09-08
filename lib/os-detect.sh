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
  local codename="${1:-}"
  echo "https://ppa.launchpadcontent.net/ondrej/php/ubuntu/dists/${codename}"
}
