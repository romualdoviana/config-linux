#!/usr/bin/env bash
# shellcheck shell=bash

: "${CONFIG_LINUX_STATE_DIR:="${HOME}/.config/config-linux/state"}"

_idempotent_state_dir() {
  mkdir -p "${CONFIG_LINUX_STATE_DIR}"
  echo "${CONFIG_LINUX_STATE_DIR}"
}

mark_done() {
  local marker="$1"
  local state_dir
  state_dir="$(_idempotent_state_dir)"
  touch "${state_dir}/${marker}"
}

is_already_done() {
  local marker="$1"
  local state_dir
  state_dir="$(_idempotent_state_dir)"
  [[ -f "${state_dir}/${marker}" ]]
}
