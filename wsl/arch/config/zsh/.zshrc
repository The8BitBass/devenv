export ZSH="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_THEME=""
plugins=(git)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

if [ -f /etc/profile.d/devenv-xdg.sh ]; then
    . /etc/profile.d/devenv-xdg.sh
fi

PROMPT='%# %F{13}%n %/%f $ '
