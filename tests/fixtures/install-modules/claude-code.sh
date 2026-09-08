#!/usr/bin/env bash
# shellcheck shell=bash

claude_code_install_all() {
  echo "CALLED:claude-code" >>"${STUB_CALL_LOG}"
  [[ "${STUB_FAIL_MODULE:-}" == "claude-code" ]] && return 1
  return 0
}
