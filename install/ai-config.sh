#!/usr/bin/env bash
# shellcheck shell=bash

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

: "${AI_CONFIG_CLAUDE_SOURCE_DIR:=${SCRIPT_DIR}/claude}"
: "${AI_CONFIG_CODEX_SOURCE_DIR:=${SCRIPT_DIR}/codex}"
: "${AI_CONFIG_CLAUDE_TARGET_DIR:=${HOME}/.claude}"
: "${AI_CONFIG_CODEX_TARGET_DIR:=${HOME}/.codex}"

AI_CONFIG_ALLOWLIST=(
  "settings.json"
  "skills"
  "agents"
  "commands"
  "hooks"
  "CLAUDE.md"
  "AGENTS.md"
)

AI_CONFIG_EXCLUDELIST=(
  ".credentials.json"
  "auth.json"
  "history.jsonl"
  "sessions"
  "session-env"
  "cache"
  "logs"
  "*.sqlite*"
)

_ai_config_is_excluded() {
  local name="$1"
  local pattern

  for pattern in "${AI_CONFIG_EXCLUDELIST[@]}"; do
    # shellcheck disable=SC2053
    if [[ "${name}" == ${pattern} ]]; then
      return 0
    fi
  done

  return 1
}

_ai_config_copy_filtered() {
  local src_path="$1"
  local dest_path="$2"
  local child
  local name

  if [[ -d "${src_path}" ]]; then
    mkdir -p "${dest_path}"

    for child in "${src_path}"/* "${src_path}"/.[!.]*; do
      [[ -e "${child}" ]] || continue
      name="$(basename -- "${child}")"

      if _ai_config_is_excluded "${name}"; then
        continue
      fi

      _ai_config_copy_filtered "${child}" "${dest_path}/${name}"
    done
  else
    cp "${src_path}" "${dest_path}"
  fi
}

copy_replicable_config() {
  local src="$1"
  local dest="$2"
  local entry
  local src_path

  mkdir -p "${dest}"

  for entry in "${AI_CONFIG_ALLOWLIST[@]}"; do
    src_path="${src}/${entry}"
    [[ -e "${src_path}" ]] || continue

    if _ai_config_is_excluded "${entry}"; then
      continue
    fi

    _ai_config_copy_filtered "${src_path}" "${dest}/${entry}"
  done
}

ai_config_install_all() {
  if [[ -d "${AI_CONFIG_CLAUDE_SOURCE_DIR}" ]]; then
    log_info "copiando config replicável do Claude Code para ${AI_CONFIG_CLAUDE_TARGET_DIR}"
    copy_replicable_config "${AI_CONFIG_CLAUDE_SOURCE_DIR}" "${AI_CONFIG_CLAUDE_TARGET_DIR}"
  fi

  if [[ -d "${AI_CONFIG_CODEX_SOURCE_DIR}" ]]; then
    log_info "copiando config replicável do Codex CLI para ${AI_CONFIG_CODEX_TARGET_DIR}"
    copy_replicable_config "${AI_CONFIG_CODEX_SOURCE_DIR}" "${AI_CONFIG_CODEX_TARGET_DIR}"
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  ai_config_install_all "$@"
fi
