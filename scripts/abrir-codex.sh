#!/bin/bash

set -euo pipefail

WORKSPACE="/home/omega/Kerosene"
SHARED_HOME="/home/omega"
SHARED_GROUP="codexagents"

prepare_workspace_permissions() {
  if ! getent group "$SHARED_GROUP" >/dev/null 2>&1; then
    echo "Grupo $SHARED_GROUP nao encontrado."
    exit 1
  fi

  sudo chgrp "$SHARED_GROUP" "$SHARED_HOME" "$WORKSPACE" >/dev/null 2>&1 || true
  sudo chmod g+rwx "$SHARED_HOME" "$WORKSPACE" >/dev/null 2>&1 || true
  sudo chmod g+s "$SHARED_HOME" "$WORKSPACE" >/dev/null 2>&1 || true

  sudo chgrp -R "$SHARED_GROUP" "$WORKSPACE" >/dev/null 2>&1 || true
  sudo chmod -R g+rwX "$WORKSPACE" >/dev/null 2>&1 || true
  sudo find "$WORKSPACE" -type d -exec chmod g+s {} + >/dev/null 2>&1 || true

  if command -v setfacl >/dev/null 2>&1; then
    sudo setfacl -m "g:$SHARED_GROUP:rwx,d:g:$SHARED_GROUP:rwx" \
      "$SHARED_HOME" "$WORKSPACE" >/dev/null 2>&1 || true
    sudo setfacl -R -m "g:$SHARED_GROUP:rwx,d:g:$SHARED_GROUP:rwx" \
      "$WORKSPACE" >/dev/null 2>&1 || true
  fi
}

open_codex() {
  local user="$1"
  local title="$2"

  gnome-terminal --title="$title" -- bash -lc \
    "sudo -iu $user bash -lc 'umask 002; git config --global --add safe.directory $WORKSPACE >/dev/null 2>&1 || true; cd $WORKSPACE && git status --short --branch && codex --cd $WORKSPACE --add-dir $SHARED_HOME --sandbox danger-full-access --ask-for-approval never; exec bash'" &
}

prepare_workspace_permissions

open_codex codex1 "Codex 1"
open_codex codex2 "Codex 2"
open_codex codex3 "Codex 3"
open_codex codex4 "Codex 4"
