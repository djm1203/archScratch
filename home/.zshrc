# Run fastfetch on terminal open
fastfetch

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

export EDITOR='nvim'
export VISUAL='nvim'

# ─── PATH ──────────────────────────────────────────────────────────────────
# User scripts (archScratch local-bin) + cargo + ruby user gems.
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
if command -v ruby >/dev/null 2>&1; then
  export PATH="$(ruby -e 'print Gem.user_dir' 2>/dev/null)/bin:$PATH"
fi

# ─── Aliases ───────────────────────────────────────────────────────────────
# Editor
alias vi='nvim'
alias vim='nvim'
# Modern CLI replacements (installed via pkg_pacman.lst)
command -v eza >/dev/null 2>&1 && alias ls='eza --icons --group-directories-first' \
  && alias ll='eza -lah --icons --group-directories-first' \
  && alias tree='eza --tree --icons'
command -v bat >/dev/null 2>&1 && alias cat='bat --paging=never'

# ─── fzf (fuzzy finder) ────────────────────────────────────────────────────
[[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
[[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

