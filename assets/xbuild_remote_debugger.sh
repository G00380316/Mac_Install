DEST="$HOME/Library/xcodebuild.nvim"
SOURCE="$HOME/.local/share/nvim/site/pack/core/opt/xcodebuild.nvim/tools/remote_debugger"
ME="$(whoami)"

sudo install -d -m 755 -o root "$DEST" && \
sudo install -m 755 -o root "$SOURCE" "$DEST/remote_debugger" && \
echo "$ME ALL = (ALL) NOPASSWD: $DEST/remote_debugger" | sudo tee -a /etc/sudoers
