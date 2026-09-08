#!/usr/bin/env bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." &>/dev/null && pwd)"
FIXTURES_DIR="${SCRIPT_DIR}/tests/fixtures"
PATH="${FIXTURES_DIR}:${PATH}"

# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

run_step() {
  fake_command_exit1
  echo "SHOULD_NOT_RUN"
}

run_step
echo "SHOULD_NOT_RUN_EITHER"
