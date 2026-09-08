#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck source=install/node.sh
source "${REPO_ROOT}/install/node.sh"

node_install_all "$@"
