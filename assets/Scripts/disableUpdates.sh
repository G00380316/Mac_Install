#!/bin/bash

sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate Automati
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticD
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate Automatica
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate Automatica
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUp
sudo killall -HUP cfprefsd
