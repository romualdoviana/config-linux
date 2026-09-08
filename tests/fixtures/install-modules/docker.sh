#!/usr/bin/env bash
# shellcheck shell=bash

docker_install_all() {
  echo "CALLED:docker" >>"${STUB_CALL_LOG}"
  [[ "${STUB_FAIL_MODULE:-}" == "docker" ]] && return 1
  return 0
}
