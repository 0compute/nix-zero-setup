#!/usr/bin/env bash
set -euo pipefail

load "${BATS_TEST_DIRNAME}/helpers.bash"

setup() {
  common_setup
  SCRIPT="${PROJECT_ROOT}/bin/verify"
}

write_jq_stub() {
  jq() {
    if [[ "$#" -lt 2 ]]; then
      return 1
    fi
    if [[ "$1" == "--raw-output" ]] || [[ "$1" == "-r" ]]; then
      shift
    fi
    shift
    for file in "$@"; do
      content=$(< "$file")
      value=${content#*\"containerDigest\":\"}
      value=${value%%\"*}
      printf '%s\n' "$value"
    done
  }
  export -f jq
}

write_oras_stub() {
  oras() {
    log_file="${LOG_DIR}/oras.log"
    printf '%s\n' "$*" >> "$log_file"
  }
  export -f oras
}

write_skopeo_stub() {
  skopeo() {
    log_file="${LOG_DIR}/skopeo.log"
    printf '%s\n' "$*" >> "$log_file"
  }
  export -f skopeo
}

write_uname_stub() {
  uname() {
    case "${1-}" in
      -m)
        printf '%s\n' "x86_64"
        ;;
      -s)
        printf '%s\n' "Linux"
        ;;
      *)
        printf '%s\n' "Linux"
        ;;
    esac
  }
  export -f uname
}

write_tr_stub() {
  tr() {
    input=$(</dev/stdin)
    printf '%s\n' "$input"
  }
  export -f tr
}

write_attestation() {
  local path=$1
  local digest=$2
  printf '%s\n' "{\"containerDigest\":\"${digest}\"}" > "$path"
}

make_attestations() {
  local dir=$1
  shift
  local index=1
  mkdir --parents "$dir"
  for digest in "$@"; do
    write_attestation "${dir}/attest-${index}.json" "$digest"
    index=$((index + 1))
  done
}

@test "verify shows usage with no args" {
  run "$BASH_BIN" "$SCRIPT"
  assert_status 1
  assert_output_contains "Usage:"
}

@test "verify rejects unknown option" {
  run "$BASH_BIN" "$SCRIPT" "image" "--nope"
  assert_status 1
  assert_output_contains "Usage:"
}

@test "verify fails without jq" {
  write_uname_stub
  write_tr_stub
  PATH=/nope run "$BASH_BIN" "$SCRIPT" "image"
  assert_status 1
}

@test "verify fails without oras" {
  write_uname_stub
  write_tr_stub
  jq() {
    return 0
  }
  export -f jq
  PATH=/nope run "$BASH_BIN" "$SCRIPT" "image"
  assert_status 1
}

@test "verify requires skopeo for annotate" {
  write_uname_stub
  write_tr_stub
  write_jq_stub
  write_oras_stub
  PATH=/nope run "$BASH_BIN" "$SCRIPT" "image" "-a"
  assert_status 1
}

@test "verify fails when attestation dir missing" {
  write_jq_stub
  write_oras_stub
  run "$BASH_BIN" "$SCRIPT" "image" "-d" "${BATS_TEST_TMPDIR}/nope"
  assert_status 1
  assert_output_contains "attestations dir missing"
}

@test "verify fails with insufficient attestations" {
  write_jq_stub
  write_oras_stub
  dir="${BATS_TEST_TMPDIR}/attestations"
  make_attestations "$dir" "sha256:one"
  run "$BASH_BIN" "$SCRIPT" "image" "-d" "$dir"
  assert_status 1
  assert_output_contains "insufficient attestations"
}

@test "verify fails with digest mismatch" {
  write_jq_stub
  write_oras_stub
  dir="${BATS_TEST_TMPDIR}/attestations"
  make_attestations "$dir" "sha256:one" "sha256:two"
  run "$BASH_BIN" "$SCRIPT" "image" "-d" "$dir"
  assert_status 1
  assert_output_contains "digest mismatch"
}

@test "verify skips attach by default" {
  write_jq_stub
  write_oras_stub
  dir="${BATS_TEST_TMPDIR}/attestations"
  make_attestations "$dir" "sha256:same" "sha256:same"
  run "$BASH_BIN" "$SCRIPT" "image" "-d" "$dir"
  assert_status 0
  assert_output_contains "verified"
  assert_output_contains "attach skipped"
  if [[ -f "${LOG_DIR}/oras.log" ]]; then
    printf '%s\n' "unexpected oras call" >&2
    return 1
  fi
}

@test "verify attaches when requested" {
  write_jq_stub
  write_oras_stub
  dir="${BATS_TEST_TMPDIR}/attestations"
  make_attestations "$dir" "sha256:same" "sha256:same"
  run "$BASH_BIN" "$SCRIPT" "image" "-d" "$dir" "-A"
  assert_status 0
  if [[ "$output" == *"attach skipped"* ]]; then
    printf '%s\n' "unexpected attach skipped" >&2
    return 1
  fi
  count=$(file_line_count "${LOG_DIR}/oras.log")
  if [[ $count -ne 2 ]]; then
    printf '%s\n' "expected 2 oras calls, got ${count}" >&2
    return 1
  fi
}

@test "verify skips attach on dry run" {
  write_jq_stub
  write_oras_stub
  dir="${BATS_TEST_TMPDIR}/attestations"
  make_attestations "$dir" "sha256:same" "sha256:same"
  run "$BASH_BIN" "$SCRIPT" "image" "-d" "$dir" "-A" "--dry-run"
  assert_status 0
  assert_output_contains "attach skipped"
  if [[ -f "${LOG_DIR}/oras.log" ]]; then
    printf '%s\n' "unexpected oras call" >&2
    return 1
  fi
}

@test "verify annotates with overrides" {
  write_jq_stub
  write_oras_stub
  write_skopeo_stub
  dir="${BATS_TEST_TMPDIR}/attestations"
  make_attestations "$dir" "sha256:same" "sha256:same"
  run "$BASH_BIN" "$SCRIPT" "image" "-d" "$dir" "-a" \
    "--arch" "amd64" "--os" "linux"
  assert_status 0
  count=$(file_line_count "${LOG_DIR}/oras.log")
  if [[ $count -ne 2 ]]; then
    printf '%s\n' "expected 2 oras calls, got ${count}" >&2
    return 1
  fi
  assert_file_contains "${LOG_DIR}/skopeo.log" "--override-arch amd64"
  assert_file_contains "${LOG_DIR}/skopeo.log" "--override-os linux"
  assert_file_contains "${LOG_DIR}/skopeo.log" "docker://image"
}
