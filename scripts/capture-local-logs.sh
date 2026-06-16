#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

MINUTES="${KEROSENE_CAPTURE_MINUTES:-20}"
RAW=0
TAIL="${KEROSENE_CAPTURE_TAIL:-20000}"
OUTPUT=""
START_ARGS=()

usage() {
  cat <<'EOF'
Usage: scripts/capture-local-logs.sh [options] [-- start-local-args...]

Stops the local Kerosene cluster, starts it again, and captures logs from
scripts/logs-local.sh into a timestamped .txt file for startup diagnostics.

Options:
  --minutes N      Capture duration in minutes. Must be between 10 and 30.
                   Defaults to KEROSENE_CAPTURE_MINUTES or 20.
  --output FILE    Destination .txt file. Defaults to logs/local-capture/<timestamp>.txt.
  --raw            Pass --raw to scripts/logs-local.sh.
  --tail N         Initial docker log tail passed to scripts/logs-local.sh.
                   Defaults to KEROSENE_CAPTURE_TAIL or 20000.
  -h, --help       Show this help.

Examples:
  scripts/capture-local-logs.sh --minutes 10 -- --no-build
  scripts/capture-local-logs.sh --minutes 30 --raw --output /tmp/kerosene-startup.txt
EOF
}

fail() {
  echo "[capture][error] $*" >&2
  exit 1
}

info() {
  echo "[capture] $*" >&2
}

is_number() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --minutes)
      shift
      [[ $# -gt 0 ]] || fail "--minutes requires a number."
      MINUTES="$1"
      ;;
    --output)
      shift
      [[ $# -gt 0 ]] || fail "--output requires a file path."
      OUTPUT="$1"
      ;;
    --raw)
      RAW=1
      ;;
    --tail)
      shift
      [[ $# -gt 0 ]] || fail "--tail requires a number."
      TAIL="$1"
      ;;
    --)
      shift
      START_ARGS+=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown option: $1"
      ;;
  esac
  shift
done

is_number "$MINUTES" || fail "--minutes must be numeric."
is_number "$TAIL" || fail "--tail must be numeric."
if (( MINUTES < 10 || MINUTES > 30 )); then
  fail "--minutes must be between 10 and 30."
fi

if [[ -z "$OUTPUT" ]]; then
  OUTPUT="$REPO_ROOT/logs/local-capture/kerosene-local-$(date +%Y%m%d-%H%M%S).txt"
fi

mkdir -p "$(dirname "$OUTPUT")"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/kerosene-capture.XXXXXX")"
STOP_LOG="$TMP_DIR/01-stop.log"
START_LOG="$TMP_DIR/02-start.log"
DOCKER_LOG="$TMP_DIR/03-docker.log"
POSTMORTEM_LOG="$TMP_DIR/04-postmortem.log"
META_LOG="$TMP_DIR/00-meta.log"

cleanup() {
  local status=$?
  trap - EXIT INT TERM
  assemble_output "$status" || true
  rm -rf "$TMP_DIR"
  exit "$status"
}

append_section() {
  local title="$1"
  local file="$2"
  {
    printf '\n===== %s =====\n' "$title"
    if [[ -s "$file" ]]; then
      cat "$file"
    else
      printf '(empty)\n'
    fi
  } >> "$OUTPUT"
}

assemble_output() {
  local status="${1:-0}"
  {
    printf 'Kerosene local log capture\n'
    printf 'Generated at: %s\n' "$(date -Is)"
    printf 'Repository: %s\n' "$REPO_ROOT"
    printf 'Duration requested: %s minutes\n' "$MINUTES"
    printf 'logs-local mode: %s\n' "$([[ "$RAW" -eq 1 ]] && printf raw || printf filtered)"
    printf 'logs-local tail: %s\n' "$TAIL"
    printf 'start-local args:'
    if [[ "${#START_ARGS[@]}" -eq 0 ]]; then
      printf ' (none)'
    else
      printf ' %q' "${START_ARGS[@]}"
    fi
    printf '\n'
    printf 'Script exit status: %s\n' "$status"
  } > "$OUTPUT"

  append_section "capture metadata" "$META_LOG"
  append_section "stop-local output" "$STOP_LOG"
  append_section "start-local output" "$START_LOG"
  append_section "logs-local output" "$DOCKER_LOG"
  append_section "postmortem raw logs" "$POSTMORTEM_LOG"
}

trap cleanup EXIT INT TERM

CAPTURE_SECONDS=$((MINUTES * 60))
CAPTURE_END=$(( $(date +%s) + CAPTURE_SECONDS ))
LOG_ARGS=(--tail "$TAIL")
if [[ "$RAW" -eq 1 ]]; then
  LOG_ARGS=(--raw "${LOG_ARGS[@]}")
fi

{
  printf '[capture] hostname: %s\n' "$(hostname 2>/dev/null || printf unknown)"
  printf '[capture] user: %s\n' "$(id 2>/dev/null || printf unknown)"
  printf '[capture] git HEAD: %s\n' "$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || printf unknown)"
  printf '[capture] docker client:\n'
  docker version --format '{{.Client.Version}}' 2>/dev/null || true
} >> "$META_LOG" 2>&1

info "Writing final capture to $OUTPUT"
info "Stopping current local cluster..."
if ! "$SCRIPT_DIR/stop-local.sh" > "$STOP_LOG" 2>&1; then
  fail "stop-local.sh failed. See $STOP_LOG"
fi

capture_logs() {
  local remaining status started_at elapsed
  while true; do
    remaining=$((CAPTURE_END - $(date +%s)))
    if (( remaining <= 0 )); then
      return 0
    fi

    printf '\n[capture] starting logs-local for up to %ss at %s\n' "$remaining" "$(date -Is)" >> "$DOCKER_LOG"
    started_at="$(date +%s)"
    set +e
    timeout --preserve-status "${remaining}s" "$SCRIPT_DIR/logs-local.sh" "${LOG_ARGS[@]}" >> "$DOCKER_LOG" 2>&1
    status=$?
    set -e
    elapsed=$(( $(date +%s) - started_at ))

    case "$status" in
      124|130|143)
        return 0
        ;;
      0)
        printf '[capture] logs-local exited after %ss while capture window is still open; retrying.\n' "$elapsed" >> "$DOCKER_LOG"
        sleep 2
        ;;
      *)
        printf '[capture] logs-local exited with status %s; retrying while startup continues.\n' "$status" >> "$DOCKER_LOG"
        sleep 2
        ;;
    esac
  done
}

info "Starting logs-local capture and local cluster..."
capture_logs &
LOG_PID=$!

set +e
"$SCRIPT_DIR/start-local.sh" "${START_ARGS[@]}" > "$START_LOG" 2>&1
START_STATUS=$?
set -e

if [[ "$START_STATUS" -ne 0 ]]; then
  printf '[capture] start-local.sh exited with status %s at %s\n' "$START_STATUS" "$(date -Is)" >> "$META_LOG"
  {
    printf '[capture] start-local failed; collecting raw no-follow logs at %s\n' "$(date -Is)"
    "$SCRIPT_DIR/logs-local.sh" --raw --no-follow --tail "$TAIL" || true
  } >> "$POSTMORTEM_LOG" 2>&1
else
  printf '[capture] start-local.sh completed successfully at %s\n' "$(date -Is)" >> "$META_LOG"
fi

info "Waiting for remaining log capture window (${MINUTES} minutes total)..."
wait "$LOG_PID" || true

if [[ "$START_STATUS" -ne 0 ]]; then
  fail "start-local.sh failed with status $START_STATUS. Capture written to $OUTPUT"
fi

info "Capture completed: $OUTPUT"
