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

: "${CONFIG_LINUX_PENDING_LOGINS_DIR:="${HOME}/.config/config-linux/pending-logins"}"

_pending_logins_dir() {
  mkdir -p "${CONFIG_LINUX_PENDING_LOGINS_DIR}"
  echo "${CONFIG_LINUX_PENDING_LOGINS_DIR}"
}

mark_pending_login() {
  local name="$1"
  local dir
  dir="$(_pending_logins_dir)"
  touch "${dir}/${name}"
}

is_pending_login() {
  local name="$1"
  local dir
  dir="$(_pending_logins_dir)"
  [[ -f "${dir}/${name}" ]]
}

clear_pending_login() {
  local name="$1"
  local dir
  dir="$(_pending_logins_dir)"
  rm -f "${dir}/${name}"
}
