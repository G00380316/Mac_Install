#!/usr/bin/env bash
set -e

###### PACKAGE LIST ######
packages=(
  "coreutils" "fzf" "neovim" "visual-studio-code" "gcc" "firefox"
  "kitty" "kodi" "node" "python" "git"
  "rust" "zoxide" "lsd" "fastfetch"
  "dbgate" "postman" "lazygit" "obsidian" "discord" #"vesktop"
  "temurin@8" "temurin@21" "ripgrep" "libplist" "ipatool"
  "font-jetbrains-mono" "font-caskaydia-cove-nerd-font" "watchman" "ngrok"
  "db-browser-for-sqlite" "fd" "bat" "github"
)

###### COLORS & LABELS ######
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
RESET="$(tput sgr0)"

###### INITIAL SETUP ######
mkdir -p ~/.config
mkdir -p Install-Logs

LOG="Install-Logs/install-$(date +%d-%H%M%S)_install.log"

###### HOMEBREW SETUP ######
if ! command -v brew &>/dev/null; then
  echo "${ERROR} Homebrew not found. Installing..."
  xcode-select --install || true
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "${OK} Homebrew already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "${INFO} Font casks are now part of the main Homebrew repo — no separate tap needed."

###### SYSTEM SETUP ######
sudo scutil --set HostName "Enochs-MacBook"
sudo scutil --set LocalHostName "Enochs-MacBook"
sudo scutil --set ComputerName "Enochs-MacBook"

sudo softwareupdate --install-rosetta --agree-to-license || true

###### FUNCTIONS ######

show_progress() {
  local pid=$1
  local pkg=$2
  local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○○" \
                    "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●")
  local i=0
  tput civis
  while ps -p "$pid" &>/dev/null; do
    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$pkg" "${spin_chars[i]}"
    i=$(( (i + 1) % 10 ))
    sleep 0.2
  done
  printf "\r${OK} ${YELLOW}%s${RESET} installed successfully!%-20s\n" "$pkg" ""
  tput cnorm
}

# Check if a package or cask is installed
is_installed() {
  brew list --formula "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

# Install or skip a package
install_package() {
  local pkg="$1"

  if is_installed "$pkg"; then
    echo "${INFO} ${YELLOW}$pkg${RESET} is already installed — skipping..."
    echo "[SKIPPED] $pkg already installed" >> "$LOG"
    return 0
  fi

  echo "${NOTE} Installing ${YELLOW}$pkg${RESET}..."
  (
    # Check if it's a cask (app or font)
    if brew info "$pkg" | grep -q "Cask"; then
      brew install --cask "$pkg"
    else
      brew install "$pkg"
    fi
  ) >>"$LOG" 2>&1 &
  pid=$!
  show_progress $pid "$pkg"
  wait $pid || {
    echo "${ERROR} ${YELLOW}$pkg${RESET} failed to install. Check ${LOG}"
    echo "[ERROR] $pkg installation failed" >> "$LOG"
    return 1
  }
}

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

###### MAIN INSTALL LOOP ######
echo "${CAT} Starting package installation..."
install_packages

###### OPTIONAL: Neovim config ######
echo "${NOTE} Setting up Neovim config..."
if [ -d ~/.config/nvim ]; then
  echo "${INFO} Updating existing nvim config..."
  git -C ~/.config/nvim pull
else
  echo "${INFO} Cloning nvim config..."
  git clone https://github.com/G00380316/nvim.git ~/.config/nvim
  cd ~/.config/nvim && git checkout mac && cd -
fi

echo
echo "${OK} All package installations complete. Logs saved to ${LOG}"
#!/usr/bin/env bash
set -e

###### PACKAGE LIST ######
packages=(
  "coreutils" "fzf" "neovim" "visual-studio-code" "gcc" "firefox"
  "kitty" "kodi" "node" "python" "git"
  "rust" "zoxide" "lsd" "fastfetch"
  "dbgate" "postman" "lazygit" "obsidian" "discord" #"vesktop"
  "temurin@8" "temurin@21" "ripgrep" "libplist"
  "font-jetbrains-mono" "font-caskaydia-cove-nerd-font" "watchman" "ngrok"
)

###### COLORS & LABELS ######
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
RESET="$(tput sgr0)"

###### INITIAL SETUP ######
mkdir -p ~/.config
mkdir -p Install-Logs

LOG="Install-Logs/install-$(date +%d-%H%M%S)_install.log"

###### HOMEBREW SETUP ######
if ! command -v brew &>/dev/null; then
  echo "${ERROR} Homebrew not found. Installing..."
  xcode-select --install || true
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "${OK} Homebrew already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "${INFO} Font casks are now part of the main Homebrew repo — no separate tap needed."

###### SYSTEM SETUP ######
sudo scutil --set HostName "Enochs-MacBook"
sudo scutil --set LocalHostName "Enochs-MacBook"
sudo scutil --set ComputerName "Enochs-MacBook"

sudo softwareupdate --install-rosetta --agree-to-license || true

###### FUNCTIONS ######

show_progress() {
  local pid=$1
  local pkg=$2
  local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○○" \
                    "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●")
  local i=0
  tput civis
  while ps -p "$pid" &>/dev/null; do
    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$pkg" "${spin_chars[i]}"
    i=$(( (i + 1) % 10 ))
    sleep 0.2
  done
  printf "\r${OK} ${YELLOW}%s${RESET} installed successfully!%-20s\n" "$pkg" ""
  tput cnorm
}

# Check if a package or cask is installed
is_installed() {
  brew list --formula "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

# Install or skip a package
install_package() {
  local pkg="$1"

  if is_installed "$pkg"; then
    echo "${INFO} ${YELLOW}$pkg${RESET} is already installed — skipping..."
    echo "[SKIPPED] $pkg already installed" >> "$LOG"
    return 0
  fi

  echo "${NOTE} Installing ${YELLOW}$pkg${RESET}..."
  (
    # Check if it's a cask (app or font)
    if brew info "$pkg" | grep -q "Cask"; then
      brew install --cask "$pkg"
    else
      brew install "$pkg"
    fi
  ) >>"$LOG" 2>&1 &
  pid=$!
  show_progress $pid "$pkg"
  wait $pid || {
    echo "${ERROR} ${YELLOW}$pkg${RESET} failed to install. Check ${LOG}"
    echo "[ERROR] $pkg installation failed" >> "$LOG"
    return 1
  }
}

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

###### MAIN INSTALL LOOP ######
echo "${CAT} Starting package installation..."
install_packages

###### OPTIONAL: Neovim config ######
echo "${NOTE} Setting up Neovim config..."
if [ -d ~/.config/nvim ]; then
  echo "${INFO} Updating existing nvim config..."
  git -C ~/.config/nvim pull
else
  echo "${INFO} Cloning nvim config..."
  git clone https://github.com/G00380316/nvim.git ~/.config/nvim
  cd ~/.config/nvim && git checkout mac && cd -
fi

echo
echo "${OK} All package installations complete. Logs saved to ${LOG}"
#!/usr/bin/env bash
set -e

###### PACKAGE LIST ######
packages=(
  "coreutils" "fzf" "neovim" "visual-studio-code" "gcc" "firefox"
  "kitty" "kodi" "node" "python" "git"
  "rust" "zoxide" "lsd" "fastfetch"
  "dbgate" "postman" "lazygit" "obsidian" "discord" #"vesktop"
  "temurin@8" "temurin@21" "ripgrep" "libplist"
  "font-jetbrains-mono" "font-caskaydia-cove-nerd-font" "watchman" "ngrok"
)

###### COLORS & LABELS ######
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
RESET="$(tput sgr0)"

###### INITIAL SETUP ######
mkdir -p ~/.config
mkdir -p Install-Logs

LOG="Install-Logs/install-$(date +%d-%H%M%S)_install.log"

###### HOMEBREW SETUP ######
if ! command -v brew &>/dev/null; then
  echo "${ERROR} Homebrew not found. Installing..."
  xcode-select --install || true
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "${OK} Homebrew already installed."
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

echo "${INFO} Font casks are now part of the main Homebrew repo — no separate tap needed."

###### SYSTEM SETUP ######
sudo scutil --set HostName "Enochs-MacBook"
sudo scutil --set LocalHostName "Enochs-MacBook"
sudo scutil --set ComputerName "Enochs-MacBook"

sudo softwareupdate --install-rosetta --agree-to-license || true

###### FUNCTIONS ######

show_progress() {
  local pid=$1
  local pkg=$2
  local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○○" \
                    "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●")
  local i=0
  tput civis
  while ps -p "$pid" &>/dev/null; do
    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$pkg" "${spin_chars[i]}"
    i=$(( (i + 1) % 10 ))
    sleep 0.2
  done
  printf "\r${OK} ${YELLOW}%s${RESET} installed successfully!%-20s\n" "$pkg" ""
  tput cnorm
}

# Check if a package or cask is installed
is_installed() {
  brew list --formula "$1" &>/dev/null || brew list --cask "$1" &>/dev/null
}

# Install or skip a package
install_package() {
  local pkg="$1"

  if is_installed "$pkg"; then
    echo "${INFO} ${YELLOW}$pkg${RESET} is already installed — skipping..."
    echo "[SKIPPED] $pkg already installed" >> "$LOG"
    return 0
  fi

  echo "${NOTE} Installing ${YELLOW}$pkg${RESET}..."
  (
    # Check if it's a cask (app or font)
    if brew info "$pkg" | grep -q "Cask"; then
      brew install --cask "$pkg"
    else
      brew install "$pkg"
    fi
  ) >>"$LOG" 2>&1 &
  pid=$!
  show_progress $pid "$pkg"
  wait $pid || {
    echo "${ERROR} ${YELLOW}$pkg${RESET} failed to install. Check ${LOG}"
    echo "[ERROR] $pkg installation failed" >> "$LOG"
    return 1
  }
}

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

move_assets() {
  echo "${CAT} Moving asset files to config directory..."
  cp -r assets/config-compact.jsonc ~/.config/fastfetch
  cp -r assets/.zshrc ~/
  cp -r assets/.zshenv ~/
  mkdir ~/.config/scripts/
  cp -r assets/pm.sh ~/.config/scripts/
  cp -r assets/.p10k.zsh ~/
  cp -r assets/kitty.conf ~/.config/kitty/
  sudo mkdir -p /usr/local/bin
  sudo chown -R $USER ~/.config
  chmod -R u=rwX,go=rX,go-w ~/.config
  echo "${OK} Asset files moved."
}

###### MAIN INSTALL LOOP ######
echo "${CAT} Starting package installation..."
install_packages
move_assets
sudo ./assets/pokemon-colorscripts/install.sh

###### OPTIONAL: Neovim config ######
echo "${NOTE} Setting up Neovim config..."
if [ -d ~/.config/nvim ]; then
  echo "${INFO} Updating existing nvim config..."
  git -C ~/.config/nvim pull
else
  echo "${INFO} Cloning nvim config..."
  git clone https://github.com/G00380316/nvim.git ~/.config/nvim
  cd ~/.config/nvim && git checkout mac && cd -
fi

echo
echo "${OK} All package installations complete. Logs saved to ${LOG}"
