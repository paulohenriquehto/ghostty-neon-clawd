# Tela de boas-vindas: fastfetch + Clawd animado ao abrir o Ghostty.
# Comandos: welcome (mostra de novo) | welcome off | welcome on
# WELCOME_PRIVATE=1 esconde Wi-Fi e IP (bom para prints)
_WELCOME_DIR=~/.config/ghostty/welcome
_WELCOME_PID=0

_welcome_stop() {
  (( _WELCOME_PID )) && kill -USR1 $_WELCOME_PID 2>/dev/null
  _WELCOME_PID=0
}

_WELCOME_LOGO_BOTTOM=21   # última linha do Clawd na tela (TOP_PAD 4 + 17 linhas)

_welcome_cursor_row() {
  # pergunta ao terminal em que linha o cursor está (resposta: ESC [ linha ; coluna R)
  local c reply tty_state=$(stty -g < /dev/tty)
  stty -echo -icanon < /dev/tty          # sem eco: a resposta não aparece na tela
  print -n $'\e[6n' > /dev/tty
  while read -rs -k1 -t 1 c < /dev/tty; do
    reply+=$c
    [[ $c == R ]] && break
  done
  stty $tty_state < /dev/tty
  [[ $reply == *R ]] || return 1
  reply=${reply#*\[}
  print -r -- ${reply%%;*}
}

_welcome_animate() {
  (( COLUMNS >= 100 )) || return
  [[ -r $_WELCOME_DIR/clawd-frames.bin ]] || return
  # só anima se o prompt ficou ABAIXO do Clawd e ainda cabe sem rolar a tela;
  # se rolar, o desenho sairia do lugar e passaria por cima do texto
  local row=$(_welcome_cursor_row)
  (( row > _WELCOME_LOGO_BOTTOM && row + 3 <= LINES )) || return
  (
    zmodload zsh/zselect
    local -a frames
    frames=("${(@ps:\x1e:)$(<$_WELCOME_DIR/clawd-frames.bin)}")
    integer i=1 n=${#frames} stop=0 ticks=0
    TRAPUSR1() { stop=1 }
    while (( ! stop && ticks < 3000 )); do      # para sozinho depois de ~5 min
      print -rn -- "${frames[i]}"
      (( i = i % n + 1, ticks++ ))
      zselect -t 9 2>/dev/null
    done
    print -rn -- $'\e[?2026l'
  ) &!
  _WELCOME_PID=$!
}

welcome() {
  case $1 in
    off) touch ~/.config/ghostty/welcome/off; echo "boas-vindas desligada"; return ;;
    on)  rm -f ~/.config/ghostty/welcome/off; echo "boas-vindas ligada"; return ;;
  esac
  _welcome_stop
  clear
  if [[ -n $WELCOME_PRIVATE ]]; then
    # modo privado (prints/lives): esconde o nome do Wi-Fi e o IP
    local cfg=${TMPDIR:-/tmp}/welcome-privado.jsonc
    sed -e 's/"{ssid} · /"rede oculta · /' -e 's/"{ipv4}"/"•••.•••.•••.•••"/' ~/.config/fastfetch/config.jsonc > $cfg
    fastfetch -c $cfg
  else
    fastfetch
  fi
  _welcome_animate
}

# o Clawd para quando você roda um comando, limpa a tela ou redimensiona a janela
autoload -Uz add-zsh-hook
add-zsh-hook preexec _welcome_stop
TRAPWINCH() { _welcome_stop }
_welcome_clear_screen() { _welcome_stop; zle .clear-screen }
zle -N clear-screen _welcome_clear_screen
# a lista do Tab pode rolar a tela: para o Clawd antes
_welcome_complete() { _welcome_stop; zle .expand-or-complete }
zle -N expand-or-complete _welcome_complete

[[ $TERM_PROGRAM == ghostty && ! -e $_WELCOME_DIR/off ]] && welcome
