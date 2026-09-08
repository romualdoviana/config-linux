#!/usr/bin/env bash
# shellcheck shell=bash

php_install_all() {
  echo "CALLED:php" >>"${STUB_CALL_LOG}"
  [[ "${STUB_FAIL_MODULE:-}" == "php" ]] && return 1
  return 0
}
