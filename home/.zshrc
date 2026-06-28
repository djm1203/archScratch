# Run fastfetch on terminal open
fastfetch

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# oh-my-zsh: prefer the packaged copy (/usr/share, no curl|bash) with a writable
# cache/custom; fall back to a user install at ~/.oh-my-zsh.
if [[ -d /usr/share/oh-my-zsh ]]; then
  export ZSH=/usr/share/oh-my-zsh
  export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh"
  export ZSH_CUSTOM="$HOME/.config/oh-my-zsh-custom"
  [[ -d $ZSH_CACHE_DIR/completions ]] || mkdir -p "$ZSH_CACHE_DIR/completions"
else
  export ZSH="$HOME/.oh-my-zsh"
fi

# Theme + autosuggestions/syntax-highlighting are loaded from the pacman packages
# below (more robust than git clones), so leave ZSH_THEME empty and keep only the
# oh-my-zsh git plugin here.
ZSH_THEME=""
plugins=(git)

# Guarded so a missing oh-my-zsh never breaks the shell (p10k + plugins below
# still load from /usr/share regardless).
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# ─── Powerlevel10k theme (pacman package, with git-clone fallback) ────────────
if [[ -f /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme
elif [[ -f ${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme ]]; then
  source ${ZSH_CUSTOM:-$ZSH/custom}/themes/powerlevel10k/powerlevel10k.zsh-theme
fi

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

# ─── zsh-autosuggestions (pacman package, with git-clone fallback) ───────────
for _f in /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
          ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  [[ -f $_f ]] && { source "$_f"; break; }
done

# ─── zsh-syntax-highlighting (MUST be sourced last) ──────────────────────────
for _f in /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
          ${ZSH_CUSTOM:-$ZSH/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  [[ -f $_f ]] && { source "$_f"; break; }
done
unset _f
