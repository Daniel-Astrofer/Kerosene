#!/bin/bash
# ==============================================================================
# KEROSENE - PROTOCOLO DE MORTE EFÊMERA (PANIC.SH)
# ==============================================================================
# Executado exclusivamente pelo SuicideService Java sob capacidades SYS_BOOT.
# Sobrescreve dados residuais e afunda o Kernel em milissegundos.
# ==============================================================================

echo "[CRITICAL] Kerosene Ephemeral Death Protocol Triggered."

# 1. Mata todos os processos do Java e Sidecars imediatamente (SIGKILL)
kill -9 $(pgrep java) || true
kill -9 $(pgrep mpc_enclave) || true

# 2. Desmonta volumes criptografados abruptamente se houver, ou quebra RAM disks se montados em /tmp
umount -f /mnt/mpc-shards || true

# 3. Dá trigger instantâneo no SysRq para desligamento duro (equivalente a puxar o fio da tomada)
# Echo "1" ativa o SysRq e o "o" faz o Poweroff instantâneo sem sincronizar I/O (impedindo logs em disco).
echo 1 > /proc/sys/kernel/sysrq
echo o > /proc/sysrq-trigger

# Fallback se o sysrq não estiver ativo
poweroff -f
