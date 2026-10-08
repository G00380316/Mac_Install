# Powerlevel10k Instant Prompt (disabled if causing issues)
typeset -g POWERLEVEL9K_INSTANT_PROMPT=off

# Zinit Setup
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone --depth=1 https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "$ZINIT_HOME/zinit.zsh"

# Init completion
autoload -Uz compinit && compinit -u

# Improve completion reliability
fpath+=($HOME/.zfunc)

# Plugins with Turbo Mode
zinit ice lucid
zinit light romkatv/powerlevel10k
[[ -f $HOME/.p10k.zsh ]] && source $HOME/.p10k.zsh

#zinit ice wait lucid
#zinit light zsh-users/zsh-completions

zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

zinit ice wait lucid
zinit light Aloxaf/fzf-tab

# Zoxide with Turbo Mode
zinit ice wait lucid
zinit light ajeetdsouza/zoxide
eval "$(zoxide init zsh --cmd cd)"

# History
HISTSIZE=10000
HISTFILE=$HOME/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory sharehistory
setopt hist_ignore_all_dups hist_ignore_dups hist_ignore_space hist_save_no_dups hist_find_no_dups
setopt correct

# FZF
FZF_HOME="$HOME/.fzf"
[ ! -d "$FZF_HOME" ] && git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_HOME" && "$FZF_HOME/install" --all
[ -f $HOME/.fzf.zsh ] && source $HOME/.fzf.zsh
export FZF_COMPLETION_TRIGGER='**'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border'
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'

# Bindkeys
bindkey '^R' fzf-history-widget
bindkey '^E' fzf-file-widget
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^I' fzf-file-widget # Hit TAB twice to activate
bindkey -e

# FZF-tab Completion Styles
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Terminal Styling
# Display Pokemon-colorscripts
# Project page: https://gitlab.com/phoneybadger/pokemon-colorscripts#on-other-distros-and-macos
# pokemon-colorscripts --no-title -s -r #without fastfetch
# pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -
#

# Aliases
alias ls='lsd --color=auto'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias q='exit'
alias qa='exit'
alias e='exec zsh'
alias n='nvim'
alias ni='nvim $(fzf --preview="bat --color=always {}")'
alias lg='lazygit'
alias search='rg'
alias nosleep='caffeinate -d'
alias python='python3'
alias lg='lazygit'
alias docs="~/.config/scripts/cht.sh"

# Functions
mkcd() { mkdir -p "$1" && cd "$1"; }


setup() {
  case "$1" in
    python)    python3 -m venv .venv && source .venv/bin/activate  ;;
    pipx)   pipx ensurepath;;
    *)         echo "Unsupported Project" ;;
  esac
}


extract() {
  case "$1" in
    *.tar.bz2) tar xvjf "$1" ;;
    *.tar.gz)  tar xvzf "$1" ;;
    *.zip)     unzip "$1" ;;
    *)         echo "Unsupported file: $1" ;;
  esac
}

checkPort(){
    lsof -i :"$1"
}

# Nearest directory at or above a file that holds $2. Package-level toolchains
# -- go, swift, cargo, gradle -- have to be run from the project root, not from
# wherever the file happens to sit inside it.
_run_root() {
    local dir="${1:a:h}"
    while [[ "$dir" != "/" ]]; do
        [[ -e "$dir/$2" ]] && { echo "$dir"; return 0 }
        dir="${dir:h}"
    done
    return 1
}

_run_unknown() {
    echo "Error: I don't know how to $1 '$2' files yet."
    return 1
}

_run_missing() {
    echo "Error: $1 is not installed."
    return 127
}

run() {
    # Exit if no file is provided
    if [[ -z "$1" ]]; then
        echo "Usage: run <filename> [args...]"
        return 1
    fi

    local file="$1"
    local base="${file%.*}" # Removes the last extension
    local name="${file:t}"  # Basename, for the files that are named, not extended
    local ext="${file##*.}" # Gets the extension (e.g., c, cpp, py)
    [[ "$ext" == "$file" ]] && ext=""
    local root

    # A few things are known by their whole name and have no extension at all.
    case "$name" in
        Dockerfile|Containerfile|*.Dockerfile)
            command -v docker > /dev/null 2>&1 || return $(_run_missing docker)
            docker build -f "$file" "${@:2}" "${file:h}"
            return
            ;;
        Makefile|makefile|GNUmakefile)
            make -C "${file:h}" "${@:2}"
            return
            ;;
    esac

    case "${ext:l}" in
        tex)
            xelatex --interaction=batchmode "$file" > /dev/null 2>&1 && open "${base}.pdf"
            ;;
        typ)
            typst compile "$file" && open "${base}.pdf"
            ;;
        c)
            gcc "$file" -o "$base" && ./"$base" "${@:2}"
            ;;
        cpp|cc|cxx)
            g++ "$file" -o "$base" && ./"$base" "${@:2}"
            ;;
        m)
            clang -framework Foundation "$file" -o "$base" && ./"$base" "${@:2}"
            ;;
        mm)
            clang++ -framework Foundation "$file" -o "$base" && ./"$base" "${@:2}"
            ;;
        swift)
            # A file with a main entry point runs on its own; one that is part
            # of a package only means anything built with the package.
            if root=$(_run_root "$file" Package.swift); then
                (cd "$root" && swift run "${@:2}")
            else
                swift "$file" "${@:2}"
            fi
            ;;
        rs)
            if root=$(_run_root "$file" Cargo.toml); then
                (cd "$root" && cargo run "${@:2}")
            else
                rustc "$file" -o "$base" && ./"$base" "${@:2}"
            fi
            ;;
        py)
            python3 "$file" "${@:2}"
            ;;
        rb)
            ruby "$file" "${@:2}"
            ;;
        lua)
            if command -v lua > /dev/null 2>&1; then
                lua "$file" "${@:2}"
            elif command -v luajit > /dev/null 2>&1; then
                luajit "$file" "${@:2}"
            else
                nvim -l "$file" "${@:2}"
            fi
            ;;
        js|mjs|cjs)
            node "$file" "${@:2}"
            ;;
        ts|mts|cts|tsx|jsx)
            # node cannot take TypeScript or JSX, so whichever runtime here can.
            if command -v bun > /dev/null 2>&1; then
                bun "$file" "${@:2}"
            elif command -v tsx > /dev/null 2>&1; then
                tsx "$file" "${@:2}"
            elif command -v ts-node > /dev/null 2>&1; then
                ts-node "$file" "${@:2}"
            elif command -v deno > /dev/null 2>&1; then
                deno run --allow-all "$file" "${@:2}"
            else
                npx --yes tsx "$file" "${@:2}"
            fi
            ;;
        php)
            php "$file" "${@:2}"
            ;;
        go)
            go run "$file" "${@:2}"
            ;;
        java)
            # -cp so the class is found whether or not the file was named
            # relative to here.
            javac "$file" && java -cp "${file:h}" "${name%.*}" "${@:2}"
            ;;
        sh|bash|zsh)
            chmod +x "$file" 2>/dev/null
            ./"$file" "${@:2}"
            ;;
        sql)
            # Against the database given as the second argument, or a scratch
            # one in memory when you just want to see the statements run.
            sqlite3 "${2:-:memory:}" < "$file"
            ;;
        html|htm)
            open "$file"
            ;;
        md|markdown)
            if command -v glow > /dev/null 2>&1; then
                glow "$file" "${@:2}"
            else
                open "$file"
            fi
            ;;
        *)
            _run_unknown run ".$ext"
            ;;
    esac
}

runtest() {
    # Exit if no file is provided
    if [[ -z "$1" ]]; then
        echo "Usage: runtest <filename> [args...]"
        return 1
    fi

    local file="$1"
    local base="${file%.*}" # Removes the last extension
    local name="${file:t}"  # Basename, for the files that are named, not extended
    local ext="${file##*.}" # Gets the extension (e.g., c, cpp, py)
    [[ "$ext" == "$file" ]] && ext=""
    local root

    case "${ext:l}" in
        py)
            # A file that is named as a test is one pytest should have; anything
            # else is a module whose doctests are the tests it has.
            if [[ "$name" == test_*.py || "$name" == *_test.py ]] \
                && python3 -c "import pytest" > /dev/null 2>&1
            then
                python3 -m pytest "$file" "${@:2}"
            else
                python3 -m doctest "$file" "${@:2}"
            fi
            ;;
        js|mjs|cjs)
            node --test "$file" "${@:2}"
            ;;
        ts|mts|cts|tsx|jsx)
            if command -v bun > /dev/null 2>&1; then
                bun test "$file" "${@:2}"
            elif command -v deno > /dev/null 2>&1; then
                deno test --allow-all "$file" "${@:2}"
            else
                npx --yes tsx --test "$file" "${@:2}"
            fi
            ;;
        go)
            # Go tests belong to a package, never to one file on its own.
            go test "${file:h}" "${@:2}"
            ;;
        rs)
            if root=$(_run_root "$file" Cargo.toml); then
                (cd "$root" && cargo test "${@:2}")
            else
                rustc --test "$file" -o "${base}-test" && ./"${base}-test" "${@:2}"
            fi
            ;;
        swift)
            root=$(_run_root "$file" Package.swift) \
                || { echo "Error: no Package.swift above '$file'."; return 1 }
            (cd "$root" && swift test "${@:2}")
            ;;
        java)
            if root=$(_run_root "$file" gradlew); then
                (cd "$root" && ./gradlew test "${@:2}")
            elif root=$(_run_root "$file" pom.xml); then
                (cd "$root" && mvn test "${@:2}")
            else
                echo "Error: no Gradle or Maven project above '$file'."
                return 1
            fi
            ;;
        lua)
            command -v busted > /dev/null 2>&1 || return $(_run_missing busted)
            busted "$file" "${@:2}"
            ;;
        php)
            if command -v phpunit > /dev/null 2>&1; then
                phpunit "$file" "${@:2}"
            else
                php -l "$file"
            fi
            ;;
        sh|bash|zsh)
            if command -v bats > /dev/null 2>&1; then
                bats "$file" "${@:2}"
            else
                # No bats: the next most useful thing a shell script can be
                # asked is whether it parses at all.
                "${ext:l}" -n "$file" && echo "OK: $name parses."
            fi
            ;;
        *)
            _run_unknown test ".$ext"
            ;;
    esac
}

# Editor
export EDITOR=nvim
[[ -n $SSH_CONNECTION ]] && export EDITOR=vim

export TMPDIR=/tmp

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh


# Created by `pipx` on 2026-08-22 11:01:01
export PATH="$PATH:/Users/enoch/.local/bin"
