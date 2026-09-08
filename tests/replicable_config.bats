#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"
  # shellcheck source=install/ai-config.sh
  source "${REPO_ROOT}/install/ai-config.sh"

  SRC="${BATS_TEST_TMPDIR}/src"
  DEST="${BATS_TEST_TMPDIR}/dest"

  mkdir -p "${SRC}/skills" "${SRC}/sessions" "${SRC}/cache" "${SRC}/logs"
  echo '{"theme":"dark"}' >"${SRC}/settings.json"
  echo '# skill foo' >"${SRC}/skills/foo.md"
  echo 'secret-token' >"${SRC}/.credentials.json"
  echo '{"line":1}' >"${SRC}/history.jsonl"
  echo 'session-data' >"${SRC}/sessions/abc.json"
  echo 'cached-stuff' >"${SRC}/cache/blob"
  echo 'log line' >"${SRC}/logs/app.log"

  copy_replicable_config "${SRC}" "${DEST}"
}

@test "arquivos do allow-list são copiados pro destino" {
  [ -f "${DEST}/settings.json" ]
  [ -f "${DEST}/skills/foo.md" ]
}

@test "arquivos e pastas do exclude-list nunca aparecem no destino" {
  [ ! -e "${DEST}/.credentials.json" ]
  [ ! -e "${DEST}/history.jsonl" ]
  [ ! -e "${DEST}/sessions" ]
  [ ! -e "${DEST}/cache" ]
  [ ! -e "${DEST}/logs" ]
}
