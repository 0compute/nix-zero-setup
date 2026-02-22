#!/usr/bin/env bash
set -euo pipefail

common_setup() {
  : "${BATS_TEST_TMPDIR:?}"
  : "${BATS_TEST_DIRNAME:?}"

  LOG_DIR="${BATS_TEST_TMPDIR}/logs"

  mkdir --parents "$LOG_DIR"

  export LOG_DIR

  BASH_BIN=$(command -v bash)
  export BASH_BIN

  PROJECT_ROOT=$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)
  export PROJECT_ROOT
}

write_curl_stub() {
  curl() {
    log_file="${LOG_DIR}/curl.log"
    count_file="${LOG_DIR}/curl.count"

    count=0
    if [[ -f "$count_file" ]]; then
      count=$(< "$count_file")
    fi

    count=$((count + 1))
    printf '%s' $count > "$count_file"
    printf '%s\n' "$*" >> "$log_file"

    if [[ " $* " == *" --data @- "* ]]; then
      input=$(</dev/stdin)
      printf '%s' "$input" > "${LOG_DIR}/curl.stdin.${count}"
    fi

    if [[ "${CURL_FAIL_METHOD-}" == "PUT" ]]; then
      if [[ " $* " == *" --request PUT "* ]]; then
        return 1
      fi
    fi
  }
  export -f curl
}

assert_status() {
  local expected=$1
  if [[ $status -ne $expected ]]; then
    printf 'expected status %s, got %s\n' $expected $status >&2
    return 1
  fi
}

assert_output_contains() {
  local needle=$1
  if [[ "$output" != *"$needle"* ]]; then
    printf 'expected output to contain %s\n' "$needle" >&2
    return 1
  fi
}

assert_file_contains() {
  local path=$1
  local needle=$2
  if ! grep --fixed-strings --quiet -- "$needle" "$path"; then
    printf 'expected %s to contain %s\n' "$path" "$needle" >&2
    return 1
  fi
}

file_line_count() {
  local path=$1
  local count=0
  while IFS= read -r _; do
    count=$((count + 1))
  done < "$path"
  printf '%s\n' $count
}
