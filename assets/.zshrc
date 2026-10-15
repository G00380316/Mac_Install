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
            command -v docker > /dev/null 2>&1 || { _run_missing docker; return 127 }
            docker build -f "$file" "${@:2}" "${file:h}"
            return
            ;;
        Makefile|makefile|GNUmakefile)
            make -C "${file:h}" "${@:2}"
            return
            ;;
        requirements.txt)
            # Into the venv you are in; otherwise into a .venv beside the file,
            # made if there is none (a bare pip install is refused on this Python).
            if [[ -n "$VIRTUAL_ENV" ]]; then
                python3 -m pip install -r "$file" "${@:2}"
            else
                [[ -d "${file:h}/.venv" ]] || python3 -m venv "${file:h}/.venv" || return
                "${file:h}/.venv/bin/python" -m pip install -r "$file" "${@:2}" \
                    && echo "Installed into ${file:h}/.venv -- activate: source ${file:h}/.venv/bin/activate"
            fi
            return
            ;;
        package.json)
            command -v npm > /dev/null 2>&1 || { _run_missing npm; return 127 }
            (cd "${file:h}" && npm install "${@:2}")
            return
            ;;
        docker-compose.yml|docker-compose.yaml|compose.yml|compose.yaml)
            command -v docker > /dev/null 2>&1 || { _run_missing docker; return 127 }
            docker compose -f "$file" up "${@:2}"
            return
            ;;
        Cargo.toml)
            command -v cargo > /dev/null 2>&1 || { _run_missing cargo; return 127 }
            (cd "${file:h}" && cargo run "${@:2}")
            return
            ;;
        go.mod)
            command -v go > /dev/null 2>&1 || { _run_missing go; return 127 }
            (cd "${file:h}" && go run . "${@:2}")
            return
            ;;
        Package.swift)
            (cd "${file:h}" && swift run "${@:2}")
            return
            ;;
        Brewfile)
            command -v brew > /dev/null 2>&1 || { _run_missing brew; return 127 }
            brew bundle --file "$file" "${@:2}"
            return
            ;;
        CMakeLists.txt)
            command -v cmake > /dev/null 2>&1 || { _run_missing cmake; return 127 }
            cmake -S "${file:h}" -B "${file:h}/build" && cmake --build "${file:h}/build" "${@:2}"
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
        tar|tgz|tbz2|txz)
            # Unpacked into a folder named after it, beside it.
            local dest="${file%.*}"
            mkdir -p "$dest" && tar -xf "$file" -C "$dest" && echo "Extracted to $dest/"
            ;;
        gz|bz2|xz)
            if [[ "${name:l}" == *.tar.* ]]; then
                # .tar.gz, .tar.bz2, .tar.xz: the archive inside is unpacked too.
                local dest="${file%.tar.*}"
                mkdir -p "$dest" && tar -xf "$file" -C "$dest" && echo "Extracted to $dest/"
            else
                # A single compressed file: unpacked beside it, the original kept.
                case "${ext:l}" in
                    gz)  gunzip -k "$file" ;;
                    bz2) bunzip2 -k "$file" ;;
                    xz)  unxz -k "$file" ;;
                esac && echo "Unpacked to $base"
            fi
            ;;
        json)
            if command -v jq > /dev/null 2>&1; then
                jq . "$file"
            else
                python3 -m json.tool "$file"
            fi
            ;;
        csv)
            # Aligned into columns; csvlook (csvkit) if there is one.
            if command -v csvlook > /dev/null 2>&1; then
                csvlook "$file"
            else
                column -s, -t < "$file"
            fi
            ;;
        7z)
            local sz
            sz=$(command -v 7zz || command -v 7z) || { _run_missing 7zip; return 127 }
            mkdir -p "$base" && "$sz" x -y "$file" -o"$base" && echo "Extracted to $base/"
            ;;
        rar)
            mkdir -p "$base"
            if command -v unrar > /dev/null 2>&1; then
                unrar x -o+ "$file" "$base/" && echo "Extracted to $base/"
            elif command -v rar > /dev/null 2>&1; then
                rar x -o+ "$file" "$base/" && echo "Extracted to $base/"
            else
                { _run_missing unrar; return 127 }
            fi
            ;;
        dmg)
            # Mounted, and the volume opened in Finder.
            local mount
            mount=$(hdiutil attach "$file" | awk -F'\t' '/\/Volumes\// {print $NF}' | tail -1)
            [[ -n "$mount" ]] && echo "Mounted at $mount" && open "$mount"
            ;;
        yaml|yml)
            if command -v yq > /dev/null 2>&1; then
                yq . "$file"
            elif python3 -c "import yaml" > /dev/null 2>&1; then
                python3 -c 'import sys,yaml,json; print(json.dumps(yaml.safe_load(open(sys.argv[1])), indent=2, default=str))' "$file"
            else
                cat "$file"
            fi
            ;;
        toml)
            python3 -c 'import sys,tomllib,json; print(json.dumps(tomllib.load(open(sys.argv[1],"rb")), indent=2, default=str))' "$file"
            ;;
        xml)
            command -v xmllint > /dev/null 2>&1 || { _run_missing xmllint; return 127 }
            xmllint --format "$file"
            ;;
        plist)
            plutil -p "$file"
            ;;
        db|sqlite|sqlite3)
            # The tables, and how many rows each holds.
            command -v sqlite3 > /dev/null 2>&1 || { _run_missing sqlite3; return 127 }
            local table
            for table in $(sqlite3 "$file" "select name from sqlite_master where type='table' order by name"); do
                printf '%-30s %s rows\n' "$table" "$(sqlite3 "$file" "select count(*) from \"$table\"")"
            done
            ;;
        kt)
            command -v kotlinc > /dev/null 2>&1 || { _run_missing kotlinc; return 127 }
            kotlinc "$file" -include-runtime -d "$base.jar" && java -jar "$base.jar" "${@:2}"
            ;;
        kts)
            command -v kotlin > /dev/null 2>&1 || { _run_missing kotlin; return 127 }
            kotlin "$file" "${@:2}"
            ;;
        pl)
            perl "$file" "${@:2}"
            ;;
        r)
            command -v Rscript > /dev/null 2>&1 || { _run_missing Rscript; return 127 }
            Rscript "$file" "${@:2}"
            ;;
        jl)
            command -v julia > /dev/null 2>&1 || { _run_missing julia; return 127 }
            julia "$file" "${@:2}"
            ;;
        zig)
            command -v zig > /dev/null 2>&1 || { _run_missing zig; return 127 }
            zig run "$file" -- "${@:2}"
            ;;
        hs)
            command -v runghc > /dev/null 2>&1 || { _run_missing runghc; return 127 }
            runghc "$file" "${@:2}"
            ;;
        dart)
            command -v dart > /dev/null 2>&1 || { _run_missing dart; return 127 }
            dart run "$file" "${@:2}"
            ;;
        docx)
            # To Markdown beside it, with its pictures in a folder of their own.
            command -v pandoc > /dev/null 2>&1 || { _run_missing pandoc; return 127 }
            pandoc "$file" -t markdown -o "$base.md" --extract-media="${base}_media" && echo "Wrote $base.md"
            ;;
        pdf)
            # The text, laid out as on the page, in a .txt beside it.
            command -v pdftotext > /dev/null 2>&1 || { _run_missing pdftotext; return 127 }
            pdftotext -layout "$file" "$base.txt" && echo "Wrote $base.txt"
            ;;
        zip)
            # Unpacked into a folder named after it, beside it.
            command -v unzip > /dev/null 2>&1 || { _run_missing unzip; return 127 }
            unzip -o "$file" -d "$base" && echo "Extracted to $base/"
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
            command -v busted > /dev/null 2>&1 || { _run_missing busted; return 127 }
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
        rb)
            if [[ "$name" == *_spec.rb ]] && command -v rspec > /dev/null 2>&1; then
                rspec "$file" "${@:2}"
            else
                ruby -Itest "$file" "${@:2}"
            fi
            ;;
        dart)
            command -v dart > /dev/null 2>&1 || { _run_missing dart; return 127 }
            dart test "$file" "${@:2}"
            ;;
        kt)
            root=$(_run_root "$file" gradlew) \
                || { echo "Error: no Gradle project above '$file'."; return 1 }
            (cd "$root" && ./gradlew test "${@:2}")
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
