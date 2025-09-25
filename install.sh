###### PACKAGES ######
packages=(
    "fzf" "neovim" "visual-studio-code" "gcc" "firefox"
    "kitty" "kodi" "node" "python" "git"
    "rust" "zoxide" "lsd" "fastfetch"
    "dbgate" "postman" "lazygit" "obsidian" "vesktop"
    "temurin@8" "temurin@21" "ripgrep" "libplist"
    "font-jetbrains-mono" "watchman" "ngrok"
)

###### GLOBAL FUNCTIONS ######
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

#----- Create Directory for Install -----#
if [ ! -d .config ]; then
    mkdir .config || { echo "Failed to create log directory"; exit 1; }
fi

if [ ! -d Install-Logs ]; then
    mkdir Install-Logs || { echo "Failed to create log directory"; exit 1; }
fi

#----- Set the name of the log file to include the current date and time -----#
LOG="Install-Logs/install-$(date +%d-%H%M%S)_install.log"

ISBREW=$(command -v brew)

if [ -z "$ISBREW" ]; then
    echo "${ERROR} Homebrew is not installed. Exiting..."
    exit 1
fi

#----- Moving configs to Computers .config -----#

show_progress() {
    local pid=$1
    local package_name=$2
    local spin_chars=("●○○○○○○○○○" "○●○○○○○○○○" "○○●○○○○○○○" "○○○●○○○○○○" "○○○○●○○○○" \
                      "○○○○○●○○○○" "○○○○○○●○○○" "○○○○○○○●○○" "○○○○○○○○●○" "○○○○○○○○○●") 
    local i=0

    tput civis
    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ..." "$package_name"

    while ps -p $pid &> /dev/null; do
        printf "\r${NOTE} Installing ${YELLOW}%s${RESET} %s" "$package_name" "${spin_chars[i]}"
        i=$(( (i + 1) % 10 ))
        sleep 0.3
    done

    printf "\r${NOTE} Installing ${YELLOW}%s${RESET} ... Done!%-20s \n" "$package_name" ""
    tput cnorm
}

# Function to check if a package is already installed
is_installed() {
  if $ISBREW list "$1" &> /dev/null; then
    return 0  # Package is installed
  else
    return 1  # Package is not installed
  fi
}

# Improved package installation with error handling
install_package() {
  # Check if the package is already installed
  if is_installed "$1"; then
    echo "${INFO} ${YELLOW}$1${RESET} is already installed, skipping..."
    return 0
  fi

  # Capture the installation output and the exit code
  local install_output
  install_output=$(stdbuf -oL $ISBREW install "$1" 2>&1)
  echo "$install_output" >> "$LOG"
  local exit_code=$?

  # Check for installation failure in the output
  if [[ "$install_output" =~ "Error" || "$exit_code" -ne 0 ]]; then
    echo "${ERROR} ${YELLOW}$1${RESET} failed to install :( , please check the install.log. You may need to install manually!"
    return 1
  else
    echo "${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
    return 0
  fi
}

###### INSTALLER/PACKAGE MANAGER SETUP ######

# Setting Computer and Hostname
sudo scutil --set HostName "Enochs-MacBook"
sudo scutil --set LocalHostName "Enochs-MacBook"
sudo scutil --set ComputerName "Enochs-MacBook"

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"

brew install core
sudo softwareupdate --install-rosetta

# Function to install all packages
install_packages(){
  for package in "${packages[@]}"; do
    echo "⏳ Installing package: $package"
    if ! install_package "$package"; then
      echo "❌ FAILED: $package"
    else
      echo "✅ $package installed successfully."
    fi
  done
}

install_packages

#----- Clone Neovim config -----#
echo "Cloning Neovim configuration..."
if [ -d ~/.config/nvim ]; then
    echo "nvim config already cloned in ~/.config/nvim, pulling latest changes..."
    git -C ~/.config/nvim pull
else
    echo "Cloning nvim config fresh..."
    rm -rf ~/.config/nvim
    git clone https://github.com/G00380316/nvim.git ~/.config/nvim/
    cd ~/.config/nvim/
    git checkout mac
    cd ~/Mac_Install
fi

