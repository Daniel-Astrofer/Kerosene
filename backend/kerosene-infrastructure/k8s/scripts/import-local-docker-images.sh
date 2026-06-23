#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: backend/kerosene-infrastructure/k8s/scripts/import-local-docker-images.sh [--skip-web-admin-build]

Copies local Docker/Compose-built Kerosene images into the Kubernetes containerd
namespace used by kubelet. This is needed when Kubernetes uses containerd and the
local development stack was built with Docker Compose.

Expected targets:
  kerosene/kerosene-app:local
  kerosene/mpc-sidecar:local
  kerosene/web-admin:local

Options:
  --skip-web-admin-build  Do not build kerosene/web-admin:local from frontend/build/web.
USAGE
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
BACKEND_COMMON="$REPO_ROOT/scripts/backend-common.sh"
SKIP_WEB_ADMIN_BUILD=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-web-admin-build) SKIP_WEB_ADMIN_BUILD=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unsupported option: $1" >&2; usage; exit 2 ;;
  esac
  shift
done

# shellcheck source=scripts/backend-common.sh
source "$BACKEND_COMMON"

require_docker

if ! command -v sudo >/dev/null 2>&1; then
  fail "sudo is required to import images into containerd namespace k8s.io."
fi
if ! command -v ctr >/dev/null 2>&1; then
  fail "ctr not found. Install containerd tools first."
fi

ensure_tag_from_compose_service() {
  local target="$1"
  shift
  local services=("$@")

  if docker image inspect "$target" >/dev/null 2>&1; then
    info "Docker image already exists: $target"
    return 0
  fi

  local service image_id
  for service in "${services[@]}"; do
    image_id="$(compose images -q "$service" 2>/dev/null | head -n 1 || true)"
    if [[ -n "$image_id" ]]; then
      info "Tagging Compose image for $service as $target"
      docker tag "$image_id" "$target"
      return 0
    fi
  done

  fail "Could not find Docker image for $target. Run scripts/start-local.sh once so Compose builds the services."
}

build_web_admin_image() {
  local target="kerosene/web-admin:local"
  local web_build="$REPO_ROOT/frontend/build/web"
  local nginx_conf="$REPO_ROOT/backend/kerosene-infrastructure/web/nginx.conf"
  local tmp_dockerfile

  if [[ "$SKIP_WEB_ADMIN_BUILD" -eq 1 ]]; then
    info "Skipping web-admin image build by request."
    return 0
  fi

  if docker image inspect "$target" >/dev/null 2>&1; then
    info "Docker image already exists: $target"
    return 0
  fi

  if [[ ! -f "$web_build/index.html" ]]; then
    fail "frontend/build/web/index.html not found. Run scripts/start-local.sh or scripts/build-web-admin-backend.sh first."
  fi
  if [[ ! -f "$nginx_conf" ]]; then
    fail "nginx config not found: $nginx_conf"
  fi

  tmp_dockerfile="$(mktemp "${TMPDIR:-/tmp}/kerosene-web-admin.Dockerfile.XXXXXX")"
  cat > "$tmp_dockerfile" <<'EOF'
FROM nginx:1.27-alpine
COPY frontend/build/web /usr/share/nginx/html
COPY backend/kerosene-infrastructure/web/nginx.conf /etc/nginx/conf.d/default.conf
RUN mkdir -p /release && printf '{"version":"local"}\n' > /release/release-manifest.json
EXPOSE 8080
EOF

  info "Building $target from frontend/build/web"
  docker build -t "$target" -f "$tmp_dockerfile" "$REPO_ROOT"
  rm -f "$tmp_dockerfile"
}

import_to_k8s_containerd() {
  local image="$1"
  info "Importing $image into containerd namespace k8s.io"
  docker save "$image" | sudo ctr -n k8s.io images import - >/dev/null
}

ensure_tag_from_compose_service \
  "kerosene/kerosene-app:local" \
  kerosene-app-is kerosene-app-ch kerosene-app-sg

ensure_tag_from_compose_service \
  "kerosene/mpc-sidecar:local" \
  mpc-sidecar-is mpc-sidecar-ch mpc-sidecar-sg

build_web_admin_image

import_to_k8s_containerd "kerosene/kerosene-app:local"
import_to_k8s_containerd "kerosene/mpc-sidecar:local"
if docker image inspect "kerosene/web-admin:local" >/dev/null 2>&1; then
  import_to_k8s_containerd "kerosene/web-admin:local"
fi

info "Imported images visible to Kubernetes:"
sudo ctr -n k8s.io images ls | grep -E 'kerosene/(kerosene-app|mpc-sidecar|web-admin)' || true

info "Done. You can now run: backend/kerosene-infrastructure/k8s/scripts/deploy.sh local"
