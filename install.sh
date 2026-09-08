#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=install/node.sh
source "${REPO_ROOT}/install/node.sh"
# shellcheck source=install/docker.sh
source "${REPO_ROOT}/install/docker.sh"
# shellcheck source=install/claude-code.sh
source "${REPO_ROOT}/install/claude-code.sh"
# shellcheck source=install/codex.sh
source "${REPO_ROOT}/install/codex.sh"

node_install_all "$@"
docker_install_all "$@"
claude_code_install_all "$@"
codex_install_all "$@"
