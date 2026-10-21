# Visual extra do zsh: erro de comando bonito + palavras coloridas (arco-íris)

# ── "comando não encontrado" estilizado ──────────────────
command_not_found_handler() {
  local cmd=${1//\%/%%}
  print -P "%F{#ff6b6b}%K{#ff6b6b}%F{#22262f}%B  ops %b%k%F{#ff6b6b}%K{#e05d8c}%k%K{#e05d8c}%F{#ffffff} comando não encontrado %k%F{#e05d8c}%f %F{#f6d365}%B$cmd%b%f"
  print -P "  %F{#7d8590}↳ confira a digitação ou procure com%f %F{#2ec4b6}brew search $cmd%f"
  return 127
}

# ── cada palavra depois do comando ganha uma cor ─────────
# (o comando em si continua verde = existe / vermelho = não existe)
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[rainbow:0]='fg=#f39c6b'
ZSH_HIGHLIGHT_STYLES[rainbow:1]='fg=#f6d365'
ZSH_HIGHLIGHT_STYLES[rainbow:2]='fg=#a8e063'
ZSH_HIGHLIGHT_STYLES[rainbow:3]='fg=#2ec4b6'
ZSH_HIGHLIGHT_STYLES[rainbow:4]='fg=#5b9bff'
ZSH_HIGHLIGHT_STYLES[rainbow:5]='fg=#c678dd'
ZSH_HIGHLIGHT_STYLES[rainbow:6]='fg=#e05d8c'

_zsh_highlight_highlighter_rainbow_predicate() { _zsh_highlight_buffer_modified }
_zsh_highlight_highlighter_rainbow_paint() {
  local buf=$BUFFER word MATCH MBEGIN MEND
  local -a match mbegin mend
  integer pos=0 start n=0
  while [[ $buf =~ '^([[:space:]]*)([^[:space:]]+)' ]]; do
    start=$(( pos + ${#match[1]} ))
    word=$match[2]
    pos=$(( start + ${#word} ))
    buf=${buf:${#MATCH}}
    if [[ $word == ('|'|'||'|'&&'|';'|'&') ]]; then n=0; continue; fi
    (( n > 0 )) && _zsh_highlight_add_highlight $start $pos rainbow:$(( (n - 1) % 7 ))
    (( n++ ))
  done
}
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets rainbow)
