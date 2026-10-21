# Som de teclado mecânico ao digitar no Ghostty.
# Comandos: som on | som off | som vol 0.3
KS_DIR=~/.config/ghostty/keysound
KS_FIFO=$KS_DIR/.fifo
zmodload zsh/system

_ks_start() {
  [[ -p $KS_FIFO ]] || mkfifo $KS_FIFO
  pgrep -qx keysoundd || (nohup $KS_DIR/keysoundd $KS_DIR/sounds $KS_FIFO $(cat $KS_DIR/volume 2>/dev/null || echo 0.5) >/dev/null 2>&1 &!)
}

_ks() {
  [[ -e $KS_DIR/off ]] && return
  if (( ! KS_FD )); then
    sysopen -w -o nonblock -u KS_FD $KS_FIFO 2>/dev/null || { KS_FD=0; return }
  fi
  { print -nu $KS_FD -- $1 } 2>/dev/null
}

# se o tocador fechar, solta o FIFO em vez de derrubar o shell
TRAPPIPE() { (( KS_FD )) && exec {KS_FD}>&-; KS_FD=0; return 0 }

_ks_self_insert() { [[ $KEYS == ' ' ]] && _ks s || _ks k; zle .self-insert }
_ks_backspace()   { _ks b; zle .backward-delete-char }
_ks_accept()      { _ks e; zle .accept-line }
zle -N self-insert _ks_self_insert
zle -N backward-delete-char _ks_backspace
zle -N accept-line _ks_accept

som() {
  case $1 in
    off) touch $KS_DIR/off; echo "som de teclado desligado" ;;
    on)  rm -f $KS_DIR/off; _ks_start; echo "som de teclado ligado" ;;
    vol) echo ${2:-0.5} > $KS_DIR/volume; pkill -x keysoundd; (( KS_FD )) && exec {KS_FD}>&-; KS_FD=0
         _ks_start; echo "volume: ${2:-0.5}" ;;
    *)   echo "uso: som on | som off | som vol 0.3" ;;
  esac
}

[[ -e $KS_DIR/off ]] || _ks_start
