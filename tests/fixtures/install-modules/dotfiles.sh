#!/usr/bin/env bash
# shellcheck shell=bash

dotfiles_install_all() {
  echo "CALLED:dotfiles" >>"${STUB_CALL_LOG}"
  [[ "${STUB_FAIL_MODULE:-}" == "dotfiles" ]] && return 1
  return 0
}
