#!/usr/bin/env bash
set -e

# --- CONFIGURATION & ARGUMENT PARSING ---

# Initialize Dry Run flag
DRY_RUN=false

# Process command-line arguments for dry run flag
for arg in "$@"; do
    case $arg in
        --dry=true)
        DRY_RUN=true
        shift
        ;;
    esac
done

# Package list includes all entries from your final block.
packages=(
    "coreutils" "fzf" "neovim" "visual-studio-code" "gcc" "firefox"
    "kitty" "kodi" "node" "python" "git"
    "rust" "zoxide" "lsd" "fastfetch"
    "dbgate" "postman" "lazygit" "obsidian" "discord"
    "temurin@8" "temurin@21" "ripgrep" "libplist" "ipatool"
    "font-jetbrains-mono" "font-caskaydia-cove-nerd-font" "watchman" "ngrok"
    "db-browser-for-sqlite" "fd" "bat" "github" "tldr"
)

# Colors and labels for script output
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
YELLOW="$(tput setaf 3)"
RESET="$(tput sgr0)"

# Announce Dry Run Mode if active
if $DRY_RUN; then
    echo "${WARN} --- DRY RUN MODE IS ACTIVE ---"
    echo "${WARN} No actual installation, configuration, or file changes will occur."
fi

# Initial Setup
mkdir -p ~/.config
mkdir -p Install-Logs

LOG="Install-Logs/install-$(date +%d-%H%M%S)_install.log"

# --- HOMEBREW SETUP ---

echo "${CAT} Checking for Homebrew installation..."
if ! command -v brew &>/dev/null; then
    echo "${ERROR} Homebrew not found. Installing..."
    if $DRY_RUN; then
        echo "${INFO} (DRY RUN): Would install Xcode Command Line Tools and Homebrew."
    else
        xcode-select --install || true
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo "${OK} Homebrew already installed. Updating environment."
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "${INFO} Font casks are now part of the main Homebrew repo — no separate tap needed."

# --- SYSTEM SETUP ---

echo "${CAT} Setting system host and computer names to Enochs-MacBook..."
if $DRY_RUN; then
    echo "${INFO} (DRY RUN): Would run 'sudo scutil --set HostName Enochs-MacBook' (and LocalHostName/ComputerName)."
else
    sudo scutil --set HostName "Enochs-MacBook"
    sudo scutil --set LocalHostName "Enochs-MacBook"
    sudo scutil --set ComputerName "Enochs-MacBook"
fi

echo "${CAT} Installing Rosetta 2 (for Apple Silicon Macs)..."
if $DRY_RUN; then
    echo "${INFO} (DRY RUN): Would run 'sudo softwareupdate --install-rosetta --agree-to-license'."
else
    sudo softwareupdate --install-rosetta --agree-to-license || true
fi

# --- FUNCTIONS ---

# Progress indicator function (simplified) - only used in actual install
show_progress() {
    local pid=$1
    local pkg=$2
    local spin_chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    tput civis
    while ps -p "$pid" &>/dev/null; do
        printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$pkg" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))
        sleep 0.1
    done
    printf "\r${OK} ${YELLOW}%s${RESET} installed successfully!%-20s\n" "$pkg" ""
    tput cnorm
}

# Check if a package or cask is installed
is_installed() {
    brew list --formula "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

# Install all packages from the list
install_packages() {
    local installed=0
    local skipped=0
    local failed=0

    for pkg in "${packages[@]}"; do
        if is_installed "$pkg"; then
            echo "${INFO} ${YELLOW}$pkg${RESET} already installed — skipping..."
            echo "[SKIPPED] $pkg already installed" >> "$LOG"
            ((skipped++))
            continue
        fi

        echo "${NOTE} Installing ${YELLOW}$pkg${RESET}..."

        if $DRY_RUN; then
            local install_type="formula"
            if brew info "$pkg" | grep -q "Cask"; then
                install_type="cask"
            fi
            echo "${INFO} (DRY RUN): Would run 'brew install --$install_type $pkg'"
            echo "[DRY RUN] Would install $pkg" >> "$LOG"
            printf "\r${OK} ${YELLOW}%s${RESET} (DRY RUN) Action logged!%-20s\n" "$pkg" ""
            ((installed++)) # Increment installed count for summary clarity in dry run
            continue
        fi

        # --- Actual Installation Block ---
        if (brew info "$pkg" | grep -q "Cask"); then
            (brew install --cask "$pkg" >>"$LOG" 2>&1) &
        else
            (brew install "$pkg" >>"$LOG" 2>&1) &
        fi
        
        pid=$!
        show_progress $pid "$pkg"
        
        if wait $pid; then
            ((installed++))
        else
            echo "${ERROR} ${YELLOW}$pkg${RESET} failed to install. Check ${LOG}"
            echo "[ERROR] $pkg installation failed" >> "$LOG"
            ((failed++))
        fi
    done

    echo
    echo "${OK} Installation Summary:"
    echo "  ✅ Installed: ${installed}"
    echo "  ⚙️  Skipped: ${skipped}"
    echo "  ❌ Failed: ${failed}"
    echo
    echo "Full logs saved to ${LOG}"
}

# Function to move config and asset files
move_assets() {
    echo "${CAT} Moving asset files to config directory..."
    
    if $DRY_RUN; then
        echo "${INFO} (DRY RUN): Would create directories and copy configuration files to ~/.config and ~/"
        return
    fi
    
    # --- Actual File Operations ---
    mkdir -p ~/.config/fastfetch
    mkdir -p ~/.config/kitty
    mkdir -p ~/.config/scripts/
    
    cp -r assets/config-compact.jsonc ~/.config/fastfetch/
    cp -r assets/.zshrc ~/
    cp -r assets/.zshenv ~/
    cp -r assets/pm.sh ~/.config/scripts/
    cp -r assets/cht.sh ~/.config/scripts/
    cp -r assets/.p10k.zsh ~/
    cp -r assets/kitty.conf ~/.config/kitty/
    
    sudo mkdir -p /usr/local/bin || true
    sudo chown -R "$USER" ~/.config
    chmod -R u=rwX,go=rX,go-w ~/.config
    chmod +x ~/.config/scripts/*
    
    echo "${OK} Asset files moved."
}

# --- MAIN INSTALL LOOP ---

echo "${CAT} Starting Homebrew package installation..."
install_packages

echo "${CAT} Configuring assets and scripts..."
move_assets

# Install Pokemon Colorscripts
if [ -f assets/pokemon-colorscripts/install.sh ]; then
    if $DRY_RUN; then
        echo "${INFO} (DRY RUN): Would run 'sudo ./assets/pokemon-colorscripts/install.sh'"
    else
        sudo ./assets/pokemon-colorscripts/install.sh
    fi
else
    echo "${WARN} Could not find assets/pokemon-colorscripts/install.sh - skipping." >> "$LOG"
fi

echo "${NOTE} Setting up Neovim config..."
if [ -d ~/.config/nvim ]; then
    echo "${INFO} Updating existing nvim config..."
    if $DRY_RUN; then
        echo "${INFO} (DRY RUN): Would run 'git -C ~/.config/nvim pull'"
    else
        git -C ~/.config/nvim pull
    fi
else
    echo "${INFO} Cloning nvim config..."
    if $DRY_RUN; then
        echo "${INFO} (DRY RUN): Would run 'git clone https://github.com/G00380316/nvim.git ~/.config/nvim'."
    else
        git clone https://github.com/G00380316/nvim.git ~/.config/nvim
    fi
fi

echo
echo "${OK} All package installations and configurations complete. Logs saved to ${LOG}"
