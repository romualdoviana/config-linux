#!/usr/bin/env bash
# shellcheck shell=bash

node_install_all() {
  echo "CALLED:node" >>"${STUB_CALL_LOG}"
  [[ "${STUB_FAIL_MODULE:-}" == "node" ]] && return 1
  return 0
}
