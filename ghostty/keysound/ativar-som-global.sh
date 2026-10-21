#!/bin/zsh
# Ativa o som de teclado em QUALQUER programa dentro do Ghostty (claude, vim, prompt...).
# Desfazer: zsh ~/.config/ghostty/keysound/ativar-som-global.sh desfazer
set -e
K=~/.config/ghostty/keysound

if [[ $1 == desfazer ]]; then
  pkill -x keysound-ghost 2>/dev/null || true
  [[ -f $K/keysound.zsh.antes-global ]] && mv $K/keysound.zsh.antes-global $K/keysound.zsh
  echo "Voltou para o som só no prompt. Abra uma aba nova no Ghostty."
  exit 0
fi

echo "→ Compilando o tocador..."
swiftc -O -o $K/keysound-ghost $K/keysoundd-global.swift

echo "→ Trocando o gancho do zsh (backup em keysound.zsh.antes-global)..."
[[ -f $K/keysound.zsh.antes-global ]] || cp $K/keysound.zsh $K/keysound.zsh.antes-global
cat > $K/keysound.zsh <<'EOF'
# Som de teclado mecânico em qualquer programa do Ghostty.
# O keysound-ghost só lê as teclas enquanto o Ghostty está na frente e só toca som.
# Comandos: som on | som off | som vol 0.3
_ks_start() {
  pgrep -qx keysound-ghost || (nohup ~/.config/ghostty/keysound/keysound-ghost ~/.config/ghostty/keysound >/dev/null 2>&1 &!)
}
som() {
  local d=~/.config/ghostty/keysound
  case $1 in
    off) touch $d/off; echo "som de teclado desligado" ;;
    on)  rm -f $d/off; _ks_start; echo "som de teclado ligado" ;;
    vol) echo ${2:-0.5} > $d/volume; echo "volume: ${2:-0.5}" ;;
    *)   echo "uso: som on | som off | som vol 0.3" ;;
  esac
}
[[ $TERM_PROGRAM == ghostty ]] && _ks_start
EOF

pkill -x keysoundd 2>/dev/null || true
pkill -x keysound-ghost 2>/dev/null || true
rm -f $K/.fifo

echo
echo "Pronto! Agora:"
echo "  1. Feche o Ghostty (Cmd+Q) e abra de novo."
echo "  2. O macOS vai pedir 'Monitoramento de Entrada' para o Ghostty."
echo "     Libere em: Ajustes do Sistema → Privacidade e Segurança → Monitoramento de Entrada."
echo "  3. Feche e abra o Ghostty mais uma vez. O som passa a tocar em toda tecla."
