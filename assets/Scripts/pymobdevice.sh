#!/bin/bash
set -e

echo -n "Install Xcode through the App Store. Once done, type 'done': "
read -r DONE

if [[ "${DONE,,}" == "done" ]]; then
	/Applications/Xcode.app/Contents/Developer/usr/bin/python3 -m pip install -U pymobiledevice3
else
	echo "Wrong input, try again."
fi

# /Applications/Xcode.app/Contents/Developer/usr/bin/python3 -m pip install pymobiledevice3==2.30.0 construct==2.10.69
