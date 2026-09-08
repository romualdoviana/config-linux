#!/usr/bin/env bash
# shellcheck shell=bash

codex_install_all() {
  echo "CALLED:codex" >>"${STUB_CALL_LOG}"
  [[ "${STUB_FAIL_MODULE:-}" == "codex" ]] && return 1
  return 0
}
