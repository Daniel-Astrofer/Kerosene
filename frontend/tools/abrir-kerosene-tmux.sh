#!/bin/bash

# Este script usa a sua lógica original de login, mas adiciona o tmux para eu poder controlar.
WORKSPACE="/home/omega/Kerosene"
SHARED_HOME="/home/omega"
SESSION="kerosene"

# Mata a sessão anterior para evitar conflitos
tmux kill-session -t "$SESSION" 2>/dev/null

# Cria a sessão com o codex1 no primeiro painel da janela "agents"
tmux new-session -d -s "$SESSION" -n "agents" "sudo -iu codex1 bash -lc 'cd $WORKSPACE && codex --cd $WORKSPACE --add-dir $SHARED_HOME --sandbox danger-full-access --ask-for-approval never; exec bash'"

# Função para adicionar um novo painel para outro codex
add_codex_pane() {
  local user="$1"
  tmux split-window -t "$SESSION:agents" "sudo -iu $user bash -lc 'cd $WORKSPACE && codex --cd $WORKSPACE --add-dir $SHARED_HOME --sandbox danger-full-access --ask-for-approval never; exec bash'"
}

# Adiciona painéis para os codex 2, 3 e 4
add_codex_pane codex2
add_codex_pane codex3
add_codex_pane codex4

# Organiza os 4 painéis em um grid 2x2 equilibrado
tmux select-layout -t "$SESSION:agents" tiled

# Detecta o terminal emulator gráfico e abre anexado ao tmux
if command -v konsole >/dev/null 2>&1; then
  konsole --title "Kerosene Orchestrator" -e tmux attach-session -t "$SESSION" &
elif command -v gnome-terminal >/dev/null 2>&1; then
  gnome-terminal --title="Kerosene Orchestrator" -- tmux attach-session -t "$SESSION" &
elif command -v xterm >/dev/null 2>&1; then
  xterm -title "Kerosene Orchestrator" -e tmux attach-session -t "$SESSION" &
else
  echo "Aviso: Nenhum emulador de terminal gráfico encontrado. Conecte-se manualmente via:"
  echo "tmux attach-session -t $SESSION"
fi

echo "Sessão tmux '$SESSION' iniciada usando seus usuários logados em formato grid."
