#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
cd "${REPO_ROOT}"

mapfile -t scripts < <(git ls-files '*.sh')

if [[ ${#scripts[@]} -eq 0 ]]; then
  echo "Nenhum script .sh versionado encontrado."
  exit 0
fi

shellcheck "${scripts[@]}"
