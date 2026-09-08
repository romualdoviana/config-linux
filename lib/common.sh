#!/usr/bin/env bash
# shellcheck shell=bash

set -Eeuo pipefail

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

_common_on_error() {
  local exit_code=$?
  local failed_command=${BASH_COMMAND}
  log_error "comando '${failed_command}' falhou com exit code ${exit_code}"
  exit "${exit_code}"
}

trap '_common_on_error' ERR
