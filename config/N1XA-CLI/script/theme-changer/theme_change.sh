#!/bin/bash

THEME_DIR="$HOME/.local/share/themes/"

CHOICE=$(ls "$THEME_DIR" | rofi -dmenu)

# Stop if nothing selected
[ -z "$CHOICE" ] && exit

# Set wallpaper using swww
notify-send "Theme changed to $CHOICE" 

gsettings set org.gnome.desktop.interface gtk-theme "$CHOICE"
