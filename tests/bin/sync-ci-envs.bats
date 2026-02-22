#!/usr/bin/env bash
set -euo pipefail

load "${BATS_TEST_DIRNAME}/helpers.bash"

setup() {
  common_setup
  write_curl_stub
  SCRIPT="${PROJECT_ROOT}/bin/sync-ci-envs"
}

@test "sync-ci-envs shows usage for help" {
  run "$BASH_BIN" "$SCRIPT" "--help"
  assert_status 0
  assert_output_contains "Usage:"
}

@test "sync-ci-envs rejects unknown argument" {
  run "$BASH_BIN" "$SCRIPT" "--nope"
  assert_status 1
  assert_output_contains "Unknown argument"
}

@test "sync-ci-envs requires core args" {
  run "$BASH_BIN" "$SCRIPT" "--provider" "gitlab"
  assert_status 1
  assert_output_contains "Usage:"
}

@test "sync-ci-envs fails when env var missing" {
  CIRCLECI_TOKEN="token" run "$BASH_BIN" "$SCRIPT" \
    "--provider" "circleci" \
    "--repo" "org/repo" \
    "--var" "MISSING"
  assert_status 1
  assert_output_contains "Missing value for MISSING in environment"
}

@test "sync-ci-envs gitlab requires token and project id" {
  run "$BASH_BIN" "$SCRIPT" \
    "--provider" "gitlab" \
    "--repo" "org/repo" \
    "--var" "FOO"
  assert_status 1
  assert_output_contains "gitlab requires GITLAB_API_TOKEN"
}

@test "sync-ci-envs gitlab syncs with put" {
  GITLAB_API_TOKEN="token" FOO="bar" run "$BASH_BIN" "$SCRIPT" \
    "--provider" "gitlab" \
    "--repo" "org/repo" \
    "--var" "FOO" \
    "--gitlab-project-id" "123"
  assert_status 0
  assert_output_contains "synced gitlab:FOO"
  assert_file_contains "${LOG_DIR}/curl.log" "--request PUT"
  assert_file_contains "${LOG_DIR}/curl.log" "/variables/FOO"
}

@test "sync-ci-envs gitlab falls back to post" {
  CURL_FAIL_METHOD="PUT" GITLAB_API_TOKEN="token" FOO="bar" \
    run "$BASH_BIN" "$SCRIPT" \
    "--provider" "gitlab" \
    "--repo" "org/repo" \
    "--var" "FOO" \
    "--gitlab-project-id" "123"
  assert_status 0
  assert_output_contains "synced gitlab:FOO"
  assert_file_contains "${LOG_DIR}/curl.log" "--request PUT"
  assert_file_contains "${LOG_DIR}/curl.log" "--request POST"
}

@test "sync-ci-envs circleci requires token" {
  run "$BASH_BIN" "$SCRIPT" \
    "--provider" "circleci" \
    "--repo" "org/repo" \
    "--var" "FOO"
  assert_status 1
  assert_output_contains "circleci requires CIRCLECI_TOKEN"
}

@test "sync-ci-envs circleci syncs env vars" {
  CIRCLECI_TOKEN="token" FOO="bar" run "$BASH_BIN" "$SCRIPT" \
    "--provider" "circleci" \
    "--repo" "org/repo" \
    "--var" "FOO"
  assert_status 0
  assert_output_contains "synced circleci:FOO"
  assert_file_contains "${LOG_DIR}/curl.log" "Circle-Token: token"
  assert_file_contains "${LOG_DIR}/curl.log" "\"name\":\"FOO\""
  assert_file_contains "${LOG_DIR}/curl.log" "\"value\":\"bar\""
}

@test "sync-ci-envs appveyor requires token account slug" {
  run "$BASH_BIN" "$SCRIPT" \
    "--provider" "appveyor" \
    "--repo" "org/repo" \
    "--var" "FOO"
  assert_status 1
  assert_output_contains "appveyor requires APPVEYOR_TOKEN"
}

@test "sync-ci-envs appveyor syncs env vars" {
  APPVEYOR_TOKEN="token" FOO="bar" run "$BASH_BIN" "$SCRIPT" \
    "--provider" "appveyor" \
    "--repo" "org/repo" \
    "--var" "FOO" \
    "--appveyor-account" "org" \
    "--appveyor-slug" "repo"
  assert_status 0
  assert_output_contains "synced appveyor:FOO"
  assert_file_contains "${LOG_DIR}/curl.log" \
    "https://ci.appveyor.com/api/projects/org/repo"
  assert_file_contains "${LOG_DIR}/curl.log" \
    "settings/environment-variables"
  assert_file_contains "${LOG_DIR}/curl.stdin.1" "\"name\":\"FOO\""
  assert_file_contains "${LOG_DIR}/curl.stdin.1" "\"isSecured\":false"
}

@test "sync-ci-envs rejects unsupported provider" {
  run "$BASH_BIN" "$SCRIPT" \
    "--provider" "nope" \
    "--repo" "org/repo" \
    "--var" "FOO"
  assert_status 1
  assert_output_contains "Unsupported provider: nope"
}
