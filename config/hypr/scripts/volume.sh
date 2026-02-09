#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Scripts for volume controls for audio and mic 

iDIR="$HOME/.config/swaync/icons"
sDIR="$HOME/.config/hypr/scripts"

# Get Volume
get_volume() {
    volume=$(pamixer --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}

# Get icons
get_icon() {
    current=$(get_volume)
    if [[ "$current" == "Muted" ]]; then
        echo "$iDIR/volume-mute.png"
    elif [[ "${current%\%}" -le 30 ]]; then
        echo "$iDIR/volume-low.png"
    elif [[ "${current%\%}" -le 60 ]]; then
        echo "$iDIR/volume-mid.png"
    else
        echo "$iDIR/volume-high.png"
    fi
}

# Notify
notify_user() {
    if [[ "$(get_volume)" == "Muted" ]]; then
        notify-send -e -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume:" " Muted"
    else
        notify-send -e -h int:value:"$(get_volume | sed 's/%//')" -h string:x-canonical-private-synchronous:volume_notif -u low -i "$(get_icon)" " Volume Level:" " $(get_volume)" &&
        "$sDIR/Sounds.sh" --volume
    fi
}

# Increase Volume
inc_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -i 5 --allow-boost --set-limit 150 && notify_user
    fi
}

# Decrease Volume
dec_volume() {
    if [ "$(pamixer --get-mute)" == "true" ]; then
        toggle_mute
    else
        pamixer -d 5 && notify_user
    fi
}

# Toggle Mute
toggle_mute() {
	if [ "$(pamixer --get-mute)" == "false" ]; then
		pamixer -m && notify-send -e -u low -i "$iDIR/volume-mute.png" " Mute"
	elif [ "$(pamixer --get-mute)" == "true" ]; then
		pamixer -u && notify-send -e -u low -i "$(get_icon)" " Volume:" " Switched ON"
	fi
}

# Toggle Mic
toggle_mic() {
	if [ "$(pamixer --default-source --get-mute)" == "false" ]; then
		pamixer --default-source -m && notify-send -e -u low -i "$iDIR/microphone-mute.png" " Microphone:" " Switched OFF"
	elif [ "$(pamixer --default-source --get-mute)" == "true" ]; then
		pamixer -u --default-source u && notify-send -e -u low -i "$iDIR/microphone.png" " Microphone:" " Switched ON"
	fi
}
# Get Mic Icon
get_mic_icon() {
    current=$(pamixer --default-source --get-volume)
    if [[ "$current" -eq "0" ]]; then
        echo "$iDIR/microphone-mute.png"
    else
        echo "$iDIR/microphone.png"
    fi
}

# Get Microphone Volume
get_mic_volume() {
    volume=$(pamixer --default-source --get-volume)
    if [[ "$volume" -eq "0" ]]; then
        echo "Muted"
    else
        echo "$volume %"
    fi
}

# Notify for Microphone
notify_mic_user() {
    volume=$(get_mic_volume)
    icon=$(get_mic_icon)
    notify-send -e -h int:value:"$volume" -h "string:x-canonical-private-synchronous:volume_notif" -u low -i "$icon"  " Mic Level:" " $volume"
}

# Increase MIC Volume
inc_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle_mic
    else
        pamixer --default-source -i 5 && notify_mic_user
    fi
}

# Decrease MIC Volume
dec_mic_volume() {
    if [ "$(pamixer --default-source --get-mute)" == "true" ]; then
        toggle-mic
    else
        pamixer --default-source -d 5 && notify_mic_user
    fi
}

# ──────────────────────────────────────────────
# MEDIA CONTROLS WITH COVER + SOURCE
# ──────────────────────────────────────────────

COVER_DIR="/tmp/playerctl-covers"
mkdir -p "$COVER_DIR"

# Check if any player exists
player_exists() {
    playerctl status &>/dev/null
}

# Get active player name (source)
get_player_source() {
    playerctl metadata --format '{{playerName}}' 2>/dev/null
}

# Get track info
get_track_info() {
    playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null
}

# Get album art URL
get_cover_url() {
    playerctl metadata mpris:artUrl 2>/dev/null
}

# Download album cover if needed
get_cover_image() {
    local url cover_file hash

    url=$(get_cover_url)

    if [[ -z "$url" ]]; then
        echo ""
        return
    fi

    hash=$(echo -n "$url" | md5sum | awk '{print $1}')
    cover_file="$COVER_DIR/$hash.png"

    if [[ ! -f "$cover_file" ]]; then
        if [[ "$url" == file://* ]]; then
            cp "${url#file://}" "$cover_file" 2>/dev/null
        else
            curl -sL "$url" -o "$cover_file"
        fi
    fi

    echo "$cover_file"
}


# Media notification
notify_media() {
    local action="$1"
    local fallback_icon="$2"

    local track source cover icon

    track=$(get_track_info)
    source=$(get_player_source)
    cover=$(get_cover_image)

    [[ -z "$track" ]] && track="No media playing"
    [[ -z "$source" ]] && source="Unknown player"

    if [[ -n "$cover" && -f "$cover" ]]; then
        icon="$cover"
    else
        icon="$fallback_icon"
    fi

    notify-send -e \
        -h string:x-canonical-private-synchronous:media_notif \
        -u low \
        -i "$icon" \
        " $action 󰎈 $source" \
        " $track"
}

# Play / Pause
media_toggle() {
    if ! player_exists; then
        return
    fi

    current_state=$(playerctl status)

    playerctl play-pause
    sleep 0.15

    if [[ "$current_state" == "Paused" ]]; then
        # Was paused → now playing
        icon="$iDIR/play.png"
        notify_media "Playing" "$icon"
    else
        # Was playing → now paused
        icon="$iDIR/pause.png"
        notify_media "Paused" "$icon"
    fi
}


# Next track
media_next() {
    if player_exists; then
        playerctl next
        sleep 0.3
        notify_media "Next" "$iDIR/play.png"
    fi
}

# Previous track
media_prev() {
    if player_exists; then
        playerctl previous
        sleep 0.3
        notify_media "Previous" "$iDIR/volume-low.png"
    fi
}


# Execute accordingly
if [[ "$1" == "--get" ]]; then
	get_volume
elif [[ "$1" == "--inc" ]]; then
	inc_volume
elif [[ "$1" == "--dec" ]]; then
	dec_volume
elif [[ "$1" == "--toggle" ]]; then
	toggle_mute
elif [[ "$1" == "--toggle-mic" ]]; then
	toggle_mic
elif [[ "$1" == "--get-icon" ]]; then
	get_icon
elif [[ "$1" == "--get-mic-icon" ]]; then
	get_mic_icon
elif [[ "$1" == "--mic-inc" ]]; then
	inc_mic_volume
elif [[ "$1" == "--mic-dec" ]]; then
	dec_mic_volume
elif [[ "$1" == "--play-pause" ]]; then
    media_toggle
elif [[ "$1" == "--next" ]]; then
    media_next
elif [[ "$1" == "--prev" ]]; then
    media_prev
else
	get_volume
fi