#!/bin/bash
set -e

echo -n "Install Xcode through the App Store. Once done, type 'done': "
read -r DONE

if [[ "${DONE,,}" == "done" ]]; then
	sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
else
	echo "Wrong input, try again."
fi
