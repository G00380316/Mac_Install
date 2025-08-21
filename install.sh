###### PACKAGES ######

packages=(
    "fzf" "neovim" "visual-studio-code" "gcc" "firefox"
    "kitty" "kodi" "node" "python" "git"
    "rust" "zoxide" "lsd" "rust" "fastfetch"
    "dbgate" "postman" "lazygit" "obsidian" "vesktop"
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

#----- Create Directory for Install Logs -----#
if [ ! -d Install-Logs ]; then
    mkdir Install-Logs
fi

#----- Set the name of the log file to include the current date and time -----#
LOG="Install-Logs/install-$(date +%d-%H%M%S)_install.log"

ISBREW=$(command -v brew)

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

install_package() {
  (
    stdbuf -oL $ISBREW install "$1" 2>&1
  ) >> "$LOG" 2>&1 &
  PID=$!
  show_progress $PID "$1"

  # Double check if package is installed
  if $ISBREW -Q "$1" &> /dev/null ; then
    echo -e "${OK} Package ${YELLOW}$1${RESET} has been successfully installed!"
  else
    # Something is missing, exiting to review log
    echo -e "\n${ERROR} ${YELLOW}$1${RESET} failed to install :( , please check the install.log. You may need to install manually! Sorry I have tried :("
  fi
}

###### INSTALLER/PACKAGE MANAGER SETUP ######

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile 
eval "$(/opt/homebrew/bin/brew shellenv)"

install_packages(){
for package in "${packages[@]}";do
    echo "⏳ Installing package: $package"
    if ! install_package "$package"; then
      echo "❌ FAILED: $package"
    else
      echo "✅ $package installed successfully."
    fi
  done
}

install_package
###### TERMINAL SETUP ######

# #----- Install Pokemon Color Scripts -----#
# printf "${NOTE} Installing ${SKY_BLUE}Pokemon Color Scripts${RESET}\n"
# for pok in "pokemon-colorscripts-git"; do
#   install_package "$pok" "$LOG"
# done
#
# printf "\n%.0s" {1..1}
# #----- Check if ~/.zshrc exists -----#
# if [ -f "$HOME/.zshrc" ]; then
# 	sed -i 's|^#pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|pokemon-colorscripts --no-title -s -r \| fastfetch -c \$HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -|' "$HOME/.zshrc" >> "$LOG" 2>&1
# 	sed -i "s|^fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|#fastfetch -c \$HOME/.config/fastfetch/config-compact.jsonc|" "$HOME/.zshrc" >> "$LOG" 2>&1
# else
#     echo "$HOME/.zshrc not found. Cant enable ${YELLOW}Pokemon color scripts${RESET}" >> "$LOG" 2>&1
# fi
#   
# printf "\n%.0s" {1..2}

###### DEVELOPMENT TOOL SETUPS ######

#----- Clone Neovim config -----#
echo "Cloning Neovim configuration..."
if [ -d ~/.config/nvim/.git ]; then
    echo "nvim config already cloned in ./nvim, pulling latest changes..."
    git -C ~/.config/nvim/.git pull
else
    echo "Cloning nvim config fresh..."
    rm -rf ~/.config/nvim
    git clone https://github.com/G00380316/nvim.git ~/.config/nvim/
fi
