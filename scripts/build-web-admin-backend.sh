#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/backend-common.sh
source "$SCRIPT_DIR/backend-common.sh"

BUILD_JAR=1
FRONTEND_DIR="$REPO_ROOT/frontend"
FRONTEND_BUILD_DIR="$FRONTEND_DIR/build/web"
BACKEND_WEB_ADMIN_BUILD_DIR="$BACKEND_DIR/web-admin-build"
FRONTEND_LOG_DIR="$FRONTEND_DIR/logs"
FRONTEND_BUILD_LOG_FILE="$FRONTEND_LOG_DIR/backend-embedded-web-build.log"

usage() {
  cat <<'EOF'
Usage: scripts/build-web-admin-backend.sh [options]

Builds the Flutter web admin for same-origin Tor deployment, copies it into
backend/kerosene/web-admin-build, and optionally packages the Spring Boot jar.

Options:
  --no-jar    Only build/copy the Flutter bundle; do not run Gradle bootJar.
  -h, --help  Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-jar) BUILD_JAR=0 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "Unknown option: $1" ;;
  esac
  shift
done

[[ -f "$FRONTEND_DIR/pubspec.yaml" ]] || fail "Frontend pubspec not found at $FRONTEND_DIR/pubspec.yaml"
command -v flutter >/dev/null 2>&1 || fail "Flutter CLI not found."

mkdir -p "$FRONTEND_LOG_DIR" "$BACKEND_WEB_ADMIN_BUILD_DIR"

info "Building Flutter web admin for backend-served same-origin onion access."
(
  cd "$FRONTEND_DIR"
  flutter build web --release --csp --no-web-resources-cdn
) > "$FRONTEND_BUILD_LOG_FILE" 2>&1 || {
  tail -n 100 "$FRONTEND_BUILD_LOG_FILE" >&2 || true
  fail "Flutter web build failed. See $FRONTEND_BUILD_LOG_FILE"
}

[[ -f "$FRONTEND_BUILD_DIR/index.html" ]] || fail "Flutter build did not produce $FRONTEND_BUILD_DIR/index.html"

if [[ -e "$BACKEND_WEB_ADMIN_BUILD_DIR" ]]; then
  stale_dir="$BACKEND_DIR/web-admin-build.stale-$(date +%s)"
  mv "$BACKEND_WEB_ADMIN_BUILD_DIR" "$stale_dir"
fi
mkdir -p "$BACKEND_WEB_ADMIN_BUILD_DIR"
cp -R "$FRONTEND_BUILD_DIR"/. "$BACKEND_WEB_ADMIN_BUILD_DIR"/
: > "$BACKEND_WEB_ADMIN_BUILD_DIR/.gitkeep"
if [[ "${EUID:-$(id -u)}" -eq 0 && -n "${SUDO_UID:-}" && -n "${SUDO_GID:-}" && "${SUDO_UID}" != "0" ]]; then
  chown -R "$SUDO_UID:$SUDO_GID" "$FRONTEND_BUILD_DIR" "$BACKEND_WEB_ADMIN_BUILD_DIR" 2>/dev/null || true
fi
info "Copied web admin bundle to $BACKEND_WEB_ADMIN_BUILD_DIR"

if [[ "$BUILD_JAR" -eq 1 ]]; then
  if [[ -n "${KEROSENE_JAVA_HOME:-}" ]]; then
    export JAVA_HOME="$KEROSENE_JAVA_HOME"
  elif [[ -d /usr/lib/jvm/java-21-openjdk ]]; then
    export JAVA_HOME=/usr/lib/jvm/java-21-openjdk
  fi

  info "Packaging backend jar with embedded web admin."
  (
    cd "$BACKEND_DIR"
    ./gradlew bootJar -x test
  )
fi
