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
