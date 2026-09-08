#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  # shellcheck source=install/dotfiles.sh
  source "${REPO_ROOT}/install/dotfiles.sh"
}

@test "chamar ensure_bashrc_sources_aliases 2x seguidas não duplica a linha" {
  local bashrc="${BATS_TEST_TMPDIR}/bashrc"
  : >"${bashrc}"

  ensure_bashrc_sources_aliases "${bashrc}"
  ensure_bashrc_sources_aliases "${bashrc}"

  run grep -c '^source ~/.bashrc_aliases$' "${bashrc}"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}

@test "bashrc que já tem a linha não duplica" {
  local bashrc="${BATS_TEST_TMPDIR}/bashrc"
  printf 'source ~/.bashrc_aliases\n' >"${bashrc}"

  ensure_bashrc_sources_aliases "${bashrc}"

  run grep -c '^source ~/.bashrc_aliases$' "${bashrc}"
  [ "$status" -eq 0 ]
  [ "$output" -eq 1 ]
}
