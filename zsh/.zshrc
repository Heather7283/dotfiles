# ========== General options ==========
# vi keybinds
bindkey -v
KEYTIMEOUT=10
# match files beginning with a . without explicitly specifying the dot
setopt globdots
# history size
HISTSIZE=100
# don't load unnecessary eye candy
_load_bloat=0
# I fucking hate lf bro
[ -n "$OLDTERM" ] && export TERM="$OLDTERM"
# autoload functions path
fpath+=(~/.config/zsh/functions/)
# ========== General options ==========


# ========== Prompt ==========
# Prompt
case "$HOST" in
  "FA506IH")
    _load_bloat=1
    export PS1="%B %1~ %0(?.:З.>:З)%b ";;
  "QboxBlue")
    export PS1="%F{blue}%B%n@%m%b%f %1~ %B%(#.#.$)%b ";;
  "archlinux") # default hostname for archlinux VMs
    export PS1="%B[VM] %n@%m%b %1~ %B%(#.#.$)%b ";;
  *)  # generic prompt
    export PS1="%B%n@%m%b %1~ %B%(#.#.$)%b ";;
esac

if [ -n "$TERMUX_VERSION" ]; then
  export PS1="%F{green}%B%n@%m%b%f %1~ %B%(#.#.$)%b "
fi
# ========== Prompt ==========


# ========== Plugins ==========
_is_bloated() { [ ! "$_load_bloat" -eq 0 ]; }

# Directory where plugins will be cloned
if [ -n "$XDG_DATA_HOME" ]; then
  _zsh_plugins_dir="$XDG_DATA_HOME/zsh/plugins/"
else
  _zsh_plugins_dir="$HOME/.local/share/zsh/plugins/"
fi

if [ -d "$_zsh_plugins_dir/zsh-completions/src" ]; then
  fpath=("$_zsh_plugins_dir/zsh-completions/src" $fpath)
fi

if [ -d "$_zsh_plugins_dir/gentoo-zsh-completions/src" ]; then
  fpath=("$_zsh_plugins_dir/gentoo-zsh-completions/src" $fpath)
fi

# Additional completions
fpath=(~/.config/zsh/completions/ $fpath)
# Load completions
if [ ! -d ~/.cache/zsh/ ]; then mkdir -p ~/.cache/zsh/; fi
autoload -Uz compinit && compinit -d ~/.cache/zsh/zcompdump
zstyle ':completion:*' menu select

if command -v fzf >/dev/null 2>&1 && \
[ -f "$_zsh_plugins_dir/fzf-tab/fzf-tab.plugin.zsh" ]; then
  source "$_zsh_plugins_dir/fzf-tab/fzf-tab.plugin.zsh"
  zstyle ':fzf-tab:*' default-color ''
  zstyle ':fzf-tab:*' use-fzf-default-opts yes
fi

if _is_bloated && \
[ -f "$_zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]; then
  source "$_zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
  fast-theme ~/.config/zsh/fsh-theme-overlay.ini >/dev/null
  # Prevents visual artifacts when pasting
  zle_highlight+=('paste:none')
fi

if _is_bloated && \
[ -f "$_zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
  source "$_zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

zsh-plugins-install() {
  command -v git 1>/dev/null 2>&1 || { echo "Install git first" && return 1 }

  # create plugins dir if doesn't exist
  if [ ! -d "$_zsh_plugins_dir" ]; then
    mkdir -pv "$_zsh_plugins_dir"
  fi

  if [ ! -d "$_zsh_plugins_dir/fzf-tab/" ]; then
    git clone --depth 1 \
      'https://github.com/Aloxaf/fzf-tab' \
      "$_zsh_plugins_dir/fzf-tab"
    (
        cd "$_zsh_plugins_dir/fzf-tab"
        git apply <~/.config/zsh/patches/fzf-tab-remove-custom-colors.patch
    )
  fi
  if [ ! -d "$_zsh_plugins_dir/zsh-autosuggestions/" ]; then
    git clone --depth 1 \
      'https://github.com/zsh-users/zsh-autosuggestions' \
      "$_zsh_plugins_dir/zsh-autosuggestions"
  fi
  if [ ! -d "$_zsh_plugins_dir/fast-syntax-highlighting/" ]; then
    git clone --depth 1 \
      'https://github.com/zdharma-continuum/fast-syntax-highlighting' \
      "$_zsh_plugins_dir/fast-syntax-highlighting"
  fi
  if [ ! -d "$_zsh_plugins_dir/zsh-completions/" ]; then
    git clone --depth 1 \
      'https://github.com/zsh-users/zsh-completions.git' \
      "$_zsh_plugins_dir/zsh-completions"
  fi
  if [ ! -d "$_zsh_plugins_dir/gentoo-zsh-completions/" ]; then
    git clone --depth 1 \
      'https://github.com/gentoo/gentoo-zsh-completions.git' \
      "$_zsh_plugins_dir/gentoo-zsh-completions"
  fi
}

zsh-plugins-clean() {
  echo -n "Remove $_zsh_plugins_dir? [y/N] "
  read -q confirm
  if [ "$confirm" = "y" ]; then
    rm -rfv "$_zsh_plugins_dir"
  else
    echo "Abort"
  fi
  unset confirm
}

zsh-plugins-update() {
  if [ -z "$(ls -A "$_zsh_plugins_dir")" ]; then
    echo "no plugins in $_zsh_plugins_dir"
    return
  fi

  for _plugin_dir in "$_zsh_plugins_dir/"*; do
    echo "Updating $_plugin_dir"
    git -C "$_plugin_dir" stash
    git -C "$_plugin_dir" pull
    git -C "$_plugin_dir" stash pop
  done
  unset _plugin_dir
}
# ========== Plugins ==========


# ========== ZLE ==========
# change cursor shape depending on mode
set-cursor-shape() {
  case "$1" in
    block) echo -ne '\e[2 q';;
    beam) echo -ne '\e[6 q';;
  esac
}
zle-keymap-select() {
  case $KEYMAP in
    vicmd) set-cursor-shape block;;
    viins|main) set-cursor-shape beam;;
  esac
}
zle -N zle-keymap-select
zle-line-init() {
  zle -K viins
  set-cursor-shape beam
  _ln_help_displayed=0
}
zle -N zle-line-init
# start shell with beam cursor
set-cursor-shape beam

# search history with fzf on C-r
fzf-history-search() {
  item="$(fc -rl 0 -1 | fzf --with-nth 2.. --scheme=history)"
  [ -n "$item" ] && zle vi-fetch-history -n "$item"
}
zle -N fzf-history-search
bindkey -M viins '\C-r' fzf-history-search
bindkey -M vicmd '\C-r' fzf-history-search

# paste selected file path into command line
fzf-file-search() {
  LBUFFER="${LBUFFER}$(find . -depth -maxdepth 6 2>/dev/null | fzf --height=~50% --layout=reverse)"
  zle reset-prompt
}
zle -N fzf-file-search
bindkey -M viins '\C-f' fzf-file-search
bindkey -M vicmd '\C-f' fzf-file-search

# remind about ln syntax :xdd:
_ln_help_displayed=0
zle-line-pre-redraw() {
  if [ "$BUFFER" = "ln" ] && [ "$_ln_help_displayed" = 0 ]; then
    echo
    echo "ln [OPTION]... [-T] TARGET LINK_NAME"
    echo "ln [OPTION]... TARGET"
    echo "ln [OPTION]... TARGET... DIRECTORY"
    echo "ln [OPTION]... -t DIRECTORY TARGET..."
    zle reset-prompt
    _ln_help_displayed=1
  fi
}
zle -N zle-line-pre-redraw

# move cursor in insert mode with Ctrl+hjkl
bindkey -M viins '\C-h' vi-backward-char
bindkey -M viins '\C-l' vi-forward-char
bindkey -M viins '\C-j' vi-down-line-or-history
bindkey -M viins '\C-k' vi-up-line-or-history

# fixes weird backspace behaviour
bindkey -M viins '^?' backward-delete-char
# ========== ZLE ==========


# ========== Aliases ==========
if command -v eza 1>/dev/null 2>&1; then
  alias ll='eza \
      --color=always \
      --icons=always \
      --long \
      --no-quotes \
      --group-directories-first \
      --hyperlink'
  alias tree='ll --tree'
else
  alias ll='ls -lhF --color=always'
  alias tree='ll -R'
fi
command -v doas 1>/dev/null 2>&1 && alias sudo='doas'
command -v bsdtar 1>/dev/null 2>&1 && alias tar='bsdtar'
alias grep='grep --color=auto'
alias neofetch='fastfetch'
alias hyprrun='hyprctl dispatch exec -- '
alias cal='cal --year --monday'
alias nyx='nyx --config ~/.config/nyxrc'
alias e='exec'
alias gdb='gdb -q'
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'
alias ffplay='ffplay -hide_banner'
alias torrent='transmission-cli'

alias ULTRAKILL='kill -KILL'
alias ULTRAPKILL='pkill -KILL'
alias ULTRAKILLALL='killall -KILL'

alias apt='apt --no-install-recommends'
alias fzfdiff='git status -s | \
  fzf -m --preview "git diff --color=always -- {2..}" | \
  sed "s/^.\{3\}//"'
alias fzfgrep='FZF_DEFAULT_COMMAND=true fzf \
  --bind '\''change:reload(rg --files-with-matches --smart-case -e {q} || true)'\'' \
  --preview '\''rg \
    --pretty \
    --context "$((FZF_PREVIEW_LINES / 4))" \
    --smart-case \
    -e {q} {} 2>/dev/null'\'' \
  --disabled'
# ========== Aliases ==========


# ========== Envvars ==========
command -v nvim 1>/dev/null 2>&1 && export MANPAGER='nvim -c ":set signcolumn=no" -c "Man!"'
export LESS='--use-color --RAW-CONTROL-CHARS --chop-long-lines'
export BASH_ENV=~/.config/bash/non-interactive.sh
export HOST="$HOST"
export USER="$USER"
export HOME="$HOME"

typeset -U path
path=(~/bin $path)
# ========== Envvars ==========


# ========== Functions ==========
# python venv management
mkvenv() {
  if [ ! -d ./venv ]; then
    python -m venv venv || return
    source venv/bin/activate || return
    if [ -f requirements.txt ]; then
      pip install -r requirements.txt
    fi
  else
    echo -n "./venv exists, recreate? [y/N] "
    if read -q; then rm -rf ./venv && mkvenv; fi
  fi
}
alias venv='source venv/bin/activate'
alias unvenv='deactivate'

# run ls after every cd
ls_after_cd() { ll | awk "BEGIN { extra = 0 } NR < int($LINES / 2) - 1 { print } NR >= int($LINES / 2) - 1 { extra += 1 } END { if (extra > 0) { print extra \" more items...\" } }" }
chpwd_functions+=(ls_after_cd)

# Wrapper for lf that allows to cd into last selected directory
lf() {
  export lf_cd_file="/tmp/lfcd.$$"

  lf_path="$(which -p lf)"
  "$lf_path" "$@"

  __dir="$(cat "$lf_cd_file" 2>/dev/null)"
  if [ -n "$__dir" ]; then cd "$__dir"; fi

  unset __dir
  rm "$lf_cd_file" 2>/dev/null
  unset lf_cd_file
}

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
  export RPROMPT="[tor proxy]"
}

tor_deactivate() {
  unset all_proxy
  unset RPROMPT
}

zapret_activate() {
  export all_proxy="socks5://127.0.0.1:8081"
  export RPROMPT="[zapret proxy]"
}

zapret_deactivate() {
  unset all_proxy
  unset RPROMPT
}

cppath() {
  realpath "$1" | wl-copy
}

spek() {
    ffmpeg -i "$1" -lavfi showspectrumpic=s=960x540 -f image2pipe -vcodec png - 2>/dev/null | chafa -f sixel
}

running_in_tmux() {
    [ -n "$TMUX_PANE" ] && return 0 || return 1
}

tmux_pane_visible() {
    tmux list-windows -f '#{window_active}' -F '#{window_visible_layout}' | \
        grep -qPe "(\d+x\d+),(\d+),(\d+),${TMUX_PANE#%}"
}

running_in_hyprland() {
    [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && return 0 || return 1
}

foot_active_window() {
    hyprctl activewindow | grep -qe 'initialClass: foot$'
}
# ========== Functions ==========


# ========== Hooks ==========
declare -aU precmd_functions
declare -aU preexec_functions

emit_prompt_control_sequence() {
    printf "\033]133;A\033\\"
}
precmd_functions+=(emit_prompt_control_sequence)

# set beam cursor for each new prompt
reset_cursor() {
    set-cursor-shape beam
}
preexec_functions+=(reset_cursor)

save_job_start_time() {
    JOB_START_SECONDS="$SECONDS"
}
preexec_functions+=(save_job_start_time)

save_job_exit_status() {
    LAST_JOB_EXIT_STATUS="$?"
}
precmd_functions=(save_job_exit_status $precmd_functions)

autoload -U notify_job_finish
precmd_functions+=(notify_job_finish)
# ========== Hooks ==========

# FUCK YOU VAXRY
if [ -z "$WAYLAND_DISPLAY" ] && [[ "$TTY" = /dev/tty* ]] && pgrep Hyprland 2>&1 1>/dev/null; then
    printf '\033[1m!!!!!!!!!! WARNING !!!!!!!!!!\033[0m\n'
    printf '\033[1mDONT SWITCH BACK TO HYPRLAND, THIS WILL FREEZE WHOLE SYSTEM\033[0m\n'
    printf '\033[1mEXECUTE \033[0mpkill Hyprland\033[1m AFTER YOU ARE DONE HERE\033[0m\n'
    printf '\033[1m!!!!!!!!!! WARNING !!!!!!!!!!\033[0m\n'
fi

