# ========== General options ==========
# vi keybinds
bindkey -v
# Load completions
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
# Additional completions
fpath=("$HOME/.config/zsh/completions/" $fpath)
# ========== General options ==========


# ========== Prompt ==========
# Prompt
case "$HOST" in
  "FA506IH")
    export PS1="%B %1~ %0(?.:3.>:З)%b ";;
  "QboxBlue")
    export PS1="%F{blue}%B%n@%m%b%f %1~%B%(#.#.$)%b ";;
esac

if [ -n "$TERMUX_VERSION" ]; then
  export PS1="%F{green}%B%n@%m%b%f %1~%B%(#.#.$)%b "
fi
# ========== Prompt ==========


# ========== Plugins ==========
# Directory where plugins will be cloned
if [ -n "$XDG_DATA_HOME" ]; then
  _zsh_plugins_dir="$XDG_DATA_HOME/zsh/plugins/"
else
  _zsh_plugins_dir="$HOME/.local/share/zsh/plugins/"
fi

which fzf > /dev/null && if [ -f "$_zsh_plugins_dir/fzf-tab/fzf-tab.plugin.zsh" ]; then
  source "$_zsh_plugins_dir/fzf-tab/fzf-tab.plugin.zsh"
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
  zstyle ':fzf-tab:*' default-color ''
  if [ -f ~/.config/themes/apps/fzf-tab/current ]; then
    zstyle ":fzf-tab:*" fzf-flags $(tr '\n' ' ' <~/.config/themes/apps/fzf-tab/current)
  fi
fi
if [ -f "$_zsh_plugins_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
  source "$_zsh_plugins_dir/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
if [ -f "$_zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$_zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if [ -d "$_zsh_plugins_dir/zsh-completions/src" ]; then
  fpath=("$_zsh_plugins_dir/zsh-completions/src" $fpath) 
fi

zsh-plugins-install() {
  which git > /dev/null || { echo "Install git first" && return 1 }
  
  # create plugins dir if doesn't exist
  if [ ! -d "$_zsh_plugins_dir" ]; then
    mkdir -pv "$_zsh_plugins_dir"
  fi

  if [ ! -d "$_zsh_plugins_dir/fzf-tab/" ]; then
    git clone 'https://github.com/Aloxaf/fzf-tab' "$_zsh_plugins_dir/fzf-tab"
  fi
  if [ ! -d "$_zsh_plugins_dir/zsh-autosuggestions/" ]; then
    git clone 'https://github.com/zsh-users/zsh-autosuggestions' "$_zsh_plugins_dir/zsh-autosuggestions"
  fi
  if [ ! -d "$_zsh_plugins_dir/zsh-syntax-highlighting/" ]; then
    git clone 'https://github.com/zsh-users/zsh-syntax-highlighting/' "$_zsh_plugins_dir/zsh-syntax-highlighting"
  fi
  if [ ! -d "$_zsh_plugins_dir/zsh-completions/" ]; then
    git clone 'https://github.com/zsh-users/zsh-completions.git' "$_zsh_plugins_dir/zsh-completions"
  fi
}

zsh-plugins-clean() {
  echo -n "Remove $_zsh_plugins_dir? [y/N] "
  read confirm
  if [ "$confirm" = "y" ]; then
    rm -rfv "$_zsh_plugins_dir"
  else
    echo "Abort"
  fi
  unset confirm
}

zsh-plugins-update() {
  _old_pwd="$PWD"
  for _plugin_dir in "$_zsh_plugins_dir/"*; do
    echo "Updating $_plugin_dir"
    cd "$_plugin_dir"
    git pull
  done
  cd "$_old_pwd"
  unset _old_pwd _plugin_dir
}
# ========== Plugins ==========


# ========== Aliases ==========
which eza >/dev/null && alias ll='eza --color=auto --icons=auto --long' || alias ll='ls -lhF --color=auto'
which doas >/dev/null && alias sudo='doas'
alias grep='grep --color=auto'
alias neofetch='fastfetch'
alias hyprrun='hyprctl dispatch exec -- '
alias cal='cal --year --monday'
alias e='exec'

alias mkvenv='python3 -m venv venv'
alias venv='source venv/bin/activate'
alias unvenv='deactivate'

alias apt='apt --no-install-recommends'
# ========== Aliases ==========


# ========== Envvars ==========
which nvim >/dev/null && export MANPAGER='nvim +Man!'
export LESS='--use-color --RAW-CONTROL-CHARS'

typeset -U path
path=(. $path)
# ========== Envvars ==========


# ========== Functions ==========
# Create a directory and cd into it
mkcd() {
	mkdir --verbose --parents "$1"
	cd "$1"
}

# Extract zip archive into a subdirectory
unzipd() {
	mkdir "${1%.*}"
	unzip -d "${1%.*}" "$1"
}

# Create a directory and all parents if they don't exist
mkdirs() {
  mkdir --verbose --parents "$1"
}

tor_activate() {
  export all_proxy="socks5://127.0.0.1:9050"
  export RPROMPT="[proxy]"
}

tor_deactivate() {
  unset all_proxy
  unset RPROMPT
}

cppath() {
  realpath "$1" | wl-copy
}
# ========== Functions ==========

