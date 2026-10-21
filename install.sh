#!/bin/zsh
# Neon Clawd — instala o preset completo do Ghostty no macOS.
# Uso: zsh install.sh
# Antes de mexer em qualquer coisa, faz backup dos seus arquivos atuais.
set -e
REPO=${0:A:h}
GH_CFG="$HOME/Library/Application Support/com.mitchellh.ghostty"
G=~/.config/ghostty

echo "✻ Neon Clawd — instalando"

if ! command -v brew >/dev/null; then
  echo "Precisa do Homebrew: https://brew.sh"; exit 1
fi

echo "→ Instalando dependências (starship, eza, fastfetch, plugins do zsh)..."
brew install starship eza fastfetch zsh-autosuggestions zsh-syntax-highlighting

BACKUP=~/.config/neon-clawd-backup-$(date +%Y%m%d-%H%M%S)
echo "→ Backup dos seus arquivos atuais em $BACKUP"
mkdir -p "$BACKUP"
for f in "$GH_CFG/config.ghostty" ~/.config/starship.toml ~/.config/fastfetch/config.jsonc ~/.zshrc; do
  [[ -e $f ]] && cp "$f" "$BACKUP/"
done

echo "→ Copiando configurações..."
mkdir -p "$GH_CFG" $G/themes $G/shaders $G/welcome $G/keysound/sounds ~/.config/fastfetch
cp "$REPO/ghostty/config.ghostty" "$GH_CFG/config.ghostty"
cp "$REPO"/ghostty/themes/* $G/themes/
cp "$REPO"/ghostty/shaders/*.glsl $G/shaders/
cp "$REPO/zsh/visual.zsh" $G/zsh-visual.zsh
cp "$REPO"/ghostty/welcome/{make_clawd.py,welcome.zsh} $G/welcome/
cp "$REPO"/ghostty/keysound/{keysoundd.swift,keysoundd-global.swift,make_sounds.py,ativar-som-global.sh} $G/keysound/
cp "$REPO/ghostty/keysound/keysound-prompt.zsh" $G/keysound/keysound.zsh
cp "$REPO"/ghostty/keysound/sounds-nk-cream/*.wav $G/keysound/sounds/
cp "$REPO/fastfetch/config.jsonc" ~/.config/fastfetch/config.jsonc
cp "$REPO/starship/starship.toml" ~/.config/starship.toml

echo "→ Gerando os quadros do Clawd..."
python3 $G/welcome/make_clawd.py

if command -v swiftc >/dev/null; then
  echo "→ Compilando o tocador do som de teclado..."
  swiftc -O -o $G/keysound/keysoundd $G/keysound/keysoundd.swift
else
  echo "! swiftc não encontrado: rode 'xcode-select --install' e depois este instalador de novo para ter o som."
fi

if ! grep -q ">>> neon-clawd >>>" ~/.zshrc 2>/dev/null; then
  echo "→ Adicionando o bloco Neon Clawd no fim do ~/.zshrc"
  printf '\n' >> ~/.zshrc
  cat "$REPO/zsh/zshrc-snippet.zsh" >> ~/.zshrc
fi

echo
echo "Pronto! Feche o Ghostty (Cmd+Q) e abra de novo."
echo "Som em qualquer programa (opcional): zsh ~/.config/ghostty/keysound/ativar-som-global.sh"
