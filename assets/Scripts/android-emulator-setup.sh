#!/usr/bin/env bash
set -euo pipefail

AVD_BASE_NAME="Pixel_Latest"
DEVICE="pixel_7"
OLD_AVD_NAMES_TO_CLEAN=("Pixel_Latest" "Pixel_7_API_35")

BREW_PREFIX="$(brew --prefix)"
ANDROID_HOME_DEFAULT="$BREW_PREFIX/share/android-commandlinetools"

export ANDROID_HOME="${ANDROID_HOME:-$ANDROID_HOME_DEFAULT}"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH"

echo "==> Android SDK root: $ANDROID_HOME"

echo "==> Checking Homebrew..."
if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is not installed. Install Homebrew first:"
  echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  exit 1
fi

echo "==> Installing required Homebrew packages if missing..."

if ! brew list --cask android-commandlinetools >/dev/null 2>&1; then
  brew install --cask android-commandlinetools
else
  echo "android-commandlinetools already installed"
fi

if ! command -v java >/dev/null 2>&1; then
  brew install --cask temurin
else
  echo "Java already installed: $(java -version 2>&1 | head -n 1)"
fi

echo "==> Making sure shell env is in ~/.zshrc..."

ZSHRC="$HOME/.zshrc"
ANDROID_BLOCK_START="# >>> android-emulator-cli >>>"
ANDROID_BLOCK_END="# <<< android-emulator-cli <<<"

if ! grep -q "$ANDROID_BLOCK_START" "$ZSHRC" 2>/dev/null; then
  cat >> "$ZSHRC" <<EOF
$ANDROID_BLOCK_START
export ANDROID_HOME="\$(brew --prefix)/share/android-commandlinetools"
export ANDROID_SDK_ROOT="\$ANDROID_HOME"
export PATH="\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/emulator:\$ANDROID_HOME/platform-tools:\$PATH"
$ANDROID_BLOCK_END
EOF
  echo "Added Android env to ~/.zshrc"
else
  echo "Android env already exists in ~/.zshrc"
fi

echo "==> Checking sdkmanager..."
if ! command -v sdkmanager >/dev/null 2>&1; then
  echo "sdkmanager not found. Try reopening Terminal, or run:"
  echo "source ~/.zshrc"
  exit 1
fi

echo "==> Accepting Android SDK licenses..."
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses >/dev/null || true

echo "==> Updating installed SDK packages..."
sdkmanager --sdk_root="$ANDROID_HOME" --update || true

echo "==> Installing base Android SDK packages..."
sdkmanager --sdk_root="$ANDROID_HOME" \
  "cmdline-tools;latest" \
  "platform-tools" \
  "emulator"

echo "==> Finding latest ARM64 Google APIs Android image..."

LATEST_IMAGE="$(
  sdkmanager --sdk_root="$ANDROID_HOME" --list \
    | grep -E 'system-images;android-[0-9]+;google_apis;arm64-v8a' \
    | sed -E 's/^[[:space:]]*//' \
    | cut -d'|' -f1 \
    | sed -E 's/[[:space:]]*$//' \
    | sort -t';' -k2,2V \
    | tail -n 1
)"

if [ -z "$LATEST_IMAGE" ]; then
  echo "Could not find latest Google APIs ARM64 system image."
  exit 1
fi

API_LEVEL="$(echo "$LATEST_IMAGE" | sed -E 's/.*android-([0-9]+).*/\1/')"
AVD_NAME="${AVD_BASE_NAME}_API_${API_LEVEL}"

echo "Latest image: $LATEST_IMAGE"
echo "Latest API: android-$API_LEVEL"
echo "Target AVD: $AVD_NAME"

echo "==> Installing latest platform, build tools, and system image..."
sdkmanager --sdk_root="$ANDROID_HOME" \
  "platforms;android-$API_LEVEL" \
  "build-tools;35.0.0" \
  "$LATEST_IMAGE"

echo "==> Existing AVDs:"
emulator -list-avds || true

echo "==> Cleaning old managed AVDs..."

for OLD_AVD in "${OLD_AVD_NAMES_TO_CLEAN[@]}"; do
  if emulator -list-avds | grep -qx "$OLD_AVD"; then
    if [ "$OLD_AVD" != "$AVD_NAME" ]; then
      echo "Deleting old managed AVD: $OLD_AVD"
      avdmanager delete avd --name "$OLD_AVD" || true
    fi
  fi
done

# Also delete older Pixel_Latest_API_* AVDs that are not the newest one.
while IFS= read -r EXISTING_AVD; do
  if [[ "$EXISTING_AVD" == Pixel_Latest_API_* && "$EXISTING_AVD" != "$AVD_NAME" ]]; then
    echo "Deleting old Pixel_Latest AVD: $EXISTING_AVD"
    avdmanager delete avd --name "$EXISTING_AVD" || true
  fi
done < <(emulator -list-avds || true)

echo "==> Creating latest AVD if needed..."

if emulator -list-avds | grep -qx "$AVD_NAME"; then
  echo "AVD already exists: $AVD_NAME"
else
  echo "Creating AVD: $AVD_NAME"
  echo "no" | avdmanager create avd \
    --name "$AVD_NAME" \
    --package "$LATEST_IMAGE" \
    --device "$DEVICE"

  AVD_CONFIG="$HOME/.android/avd/$AVD_NAME.avd/config.ini"

  if [ -f "$AVD_CONFIG" ]; then
   if grep -q "^hw.serialPort=" "$AVD_CONFIG"; then
    /usr/bin/sed -i '' 's/^hw.serialPort=.*/hw.serialPort=no/' "$AVD_CONFIG"
   else
     echo "hw.serialPort=no" >> "$AVD_CONFIG"
   fi
  fi
fi

echo
echo "==> Done."
echo
echo "Start emulator with:"
echo "emulator -avd $AVD_NAME   -gpu host -no-boot-anim -netdelay none -netspeed full"
echo
echo "Check device with:"
echo "adb devices"
echo
echo "Run Expo with:"
echo "npx expo run:android"
