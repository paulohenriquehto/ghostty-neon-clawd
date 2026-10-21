# >>> neon-clawd >>>
# ── visual do terminal (Neon Clawd) ───────────────────
# ls com ícones e cores (eza)
export EZA_COLORS="da=38;2;243;156;107:uu=1;38;2;246;211;101:sn=38;2;168;224;99:sb=38;2;168;224;99"
alias ls='eza --icons --group-directories-first'
alias la='eza -la --icons --group-directories-first --grid --no-git'
alias ll='eza -l --icons --group-directories-first --git'
alias lt='eza --tree --level=2 --icons'

# histórico e autocompletar
HISTSIZE=10000; SAVEHIST=10000; HISTFILE=~/.zsh_history
setopt SHARE_HISTORY HIST_IGNORE_DUPS
autoload -Uz compinit && compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# som de teclado mecânico (só no Ghostty) — "som off" desliga
[[ $TERM_PROGRAM == ghostty ]] && source ~/.config/ghostty/keysound/keysound.zsh

# sugestões em cinza enquanto digita (→ aceita) + comandos coloridos
_NC_BREW=${HOMEBREW_PREFIX:-/opt/homebrew}
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#5c6370'
source $_NC_BREW/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $_NC_BREW/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source ~/.config/ghostty/zsh-visual.zsh  # erro bonito + palavras coloridas

# prompt powerline (Starship)
eval "$(starship init zsh)"

# tela de boas-vindas com o Clawd animado — "welcome off" desliga
source ~/.config/ghostty/welcome/welcome.zsh
# <<< neon-clawd <<<
