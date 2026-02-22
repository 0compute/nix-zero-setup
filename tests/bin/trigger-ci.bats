#!/usr/bin/env bash
set -euo pipefail

load "${BATS_TEST_DIRNAME}/helpers.bash"

setup() {
  common_setup
  write_curl_stub
  SCRIPT="${PROJECT_ROOT}/bin/trigger-ci"
}

@test "trigger-ci shows usage for help" {
  run "$BASH_BIN" "$SCRIPT" "--help"
  assert_status 0
  assert_output_contains "Usage:"
}

@test "trigger-ci rejects unknown argument" {
  run "$BASH_BIN" "$SCRIPT" "--nope"
  assert_status 1
  assert_output_contains "Unknown argument"
}

@test "trigger-ci requires core args" {
  run "$BASH_BIN" "$SCRIPT" "--provider" "gitlab"
  assert_status 1
  assert_output_contains "Usage:"
}

@test "trigger-ci gitlab requires token and project id" {
  run "$BASH_BIN" "$SCRIPT" "--provider" "gitlab" "--repo" "org/repo" \
    "--ref" "main" "--sha" "deadbeef"
  assert_status 1
  assert_output_contains "gitlab requires GITLAB_TRIGGER_TOKEN"
}

@test "trigger-ci gitlab triggers curl" {
  GITLAB_TRIGGER_TOKEN="token" run "$BASH_BIN" "$SCRIPT" \
    "--provider" "gitlab" \
    "--repo" "org/repo" \
    "--ref" "main" \
    "--sha" "deadbeef" \
    "--gitlab-project-id" "123"
  assert_status 0
  assert_file_contains "${LOG_DIR}/curl.log" \
    "https://gitlab.com/api/v4/projects/123/trigger/pipeline"
  assert_file_contains "${LOG_DIR}/curl.log" "--form token=token"
  assert_file_contains "${LOG_DIR}/curl.log" "--form ref=main"
  assert_file_contains "${LOG_DIR}/curl.log" "--form variables[SHA]=deadbeef"
  assert_file_contains "${LOG_DIR}/curl.log" "--form variables[REPO]=org/repo"
}

@test "trigger-ci circleci requires token" {
  run "$BASH_BIN" "$SCRIPT" "--provider" "circleci" "--repo" "org/repo" \
    "--ref" "main" "--sha" "deadbeef"
  assert_status 1
  assert_output_contains "circleci requires CIRCLECI_TOKEN"
}

@test "trigger-ci circleci triggers curl" {
  CIRCLECI_TOKEN="token" run "$BASH_BIN" "$SCRIPT" \
    "--provider" "circleci" \
    "--repo" "org/repo" \
    "--ref" "main" \
    "--sha" "deadbeef"
  assert_status 0
  assert_file_contains "${LOG_DIR}/curl.log" \
    "https://circleci.com/api/v2/project/gh/org/repo/pipeline"
  assert_file_contains "${LOG_DIR}/curl.log" "Circle-Token: token"
  assert_file_contains "${LOG_DIR}/curl.stdin.1" "\"branch\":\"main\""
  assert_file_contains "${LOG_DIR}/curl.stdin.1" "\"sha\":\"deadbeef\""
}

@test "trigger-ci appveyor requires token account slug" {
  run "$BASH_BIN" "$SCRIPT" "--provider" "appveyor" "--repo" "org/repo" \
    "--ref" "main" "--sha" "deadbeef"
  assert_status 1
  assert_output_contains "appveyor requires APPVEYOR_TOKEN"
}

@test "trigger-ci appveyor triggers curl" {
  APPVEYOR_TOKEN="token" run "$BASH_BIN" "$SCRIPT" \
    "--provider" "appveyor" \
    "--repo" "org/repo" \
    "--ref" "main" \
    "--sha" "deadbeef" \
    "--appveyor-account" "org" \
    "--appveyor-slug" "repo"
  assert_status 0
  assert_file_contains "${LOG_DIR}/curl.log" \
    "https://ci.appveyor.com/api/builds"
  assert_file_contains "${LOG_DIR}/curl.log" "Authorization: Bearer token"
  assert_file_contains "${LOG_DIR}/curl.stdin.1" "\"accountName\":\"org\""
  assert_file_contains "${LOG_DIR}/curl.stdin.1" "\"projectSlug\":\"repo\""
  assert_file_contains "${LOG_DIR}/curl.stdin.1" "\"commitId\":\"deadbeef\""
}

@test "trigger-ci rejects unsupported provider" {
  run "$BASH_BIN" "$SCRIPT" "--provider" "nope" "--repo" "org/repo" \
    "--ref" "main" "--sha" "deadbeef"
  assert_status 1
  assert_output_contains "Unsupported provider: nope"
}
