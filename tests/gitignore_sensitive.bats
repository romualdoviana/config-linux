#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd -- "${BATS_TEST_DIRNAME}/.." &>/dev/null && pwd)"

  REPO_COPY="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${REPO_COPY}"
  cp "${REPO_ROOT}/.gitignore" "${REPO_COPY}/.gitignore"

  git -C "${REPO_COPY}" init -q
}

@test "*.credentials.json é ignorado" {
  touch "${REPO_COPY}/foo.credentials.json"
  run git -C "${REPO_COPY}" check-ignore -q foo.credentials.json
  [ "$status" -eq 0 ]
}

@test "auth.json é ignorado" {
  touch "${REPO_COPY}/auth.json"
  run git -C "${REPO_COPY}" check-ignore -q auth.json
  [ "$status" -eq 0 ]
}

@test "history.jsonl é ignorado" {
  touch "${REPO_COPY}/history.jsonl"
  run git -C "${REPO_COPY}" check-ignore -q history.jsonl
  [ "$status" -eq 0 ]
}

@test "sessions/ é ignorado" {
  mkdir -p "${REPO_COPY}/sessions"
  touch "${REPO_COPY}/sessions/abc.json"
  run git -C "${REPO_COPY}" check-ignore -q sessions/abc.json
  [ "$status" -eq 0 ]
}

@test "session-env/ é ignorado" {
  mkdir -p "${REPO_COPY}/session-env"
  touch "${REPO_COPY}/session-env/abc"
  run git -C "${REPO_COPY}" check-ignore -q session-env/abc
  [ "$status" -eq 0 ]
}

@test "cache/ é ignorado" {
  mkdir -p "${REPO_COPY}/cache"
  touch "${REPO_COPY}/cache/blob"
  run git -C "${REPO_COPY}" check-ignore -q cache/blob
  [ "$status" -eq 0 ]
}

@test "*.sqlite* é ignorado" {
  touch "${REPO_COPY}/state.sqlite3"
  run git -C "${REPO_COPY}" check-ignore -q state.sqlite3
  [ "$status" -eq 0 ]
}

@test "logs/ é ignorado" {
  mkdir -p "${REPO_COPY}/logs"
  touch "${REPO_COPY}/logs/app.log"
  run git -C "${REPO_COPY}" check-ignore -q logs/app.log
  [ "$status" -eq 0 ]
}

@test "settings.json não é ignorado" {
  touch "${REPO_COPY}/settings.json"
  run git -C "${REPO_COPY}" check-ignore -q settings.json
  [ "$status" -eq 1 ]
}

@test "CLAUDE.md não é ignorado" {
  touch "${REPO_COPY}/CLAUDE.md"
  run git -C "${REPO_COPY}" check-ignore -q CLAUDE.md
  [ "$status" -eq 1 ]
}
