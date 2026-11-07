#!/usr/bin/env bash
THEME="$HOME/.config/rofi/power.rasi"

ico() { printf "\u$1"; }
lock=$(ico f023); suspend=$(ico f186); logout=$(ico f08b)
reboot=$(ico f021); shutdown=$(ico f011)
yes=$(ico f00c); no=$(ico f00d)

up=$(uptime -p | sed "s/^up //")

choice=$(printf "%s\n" "$lock" "$suspend" "$logout" "$reboot" "$shutdown" \
    | rofi -dmenu -theme "$THEME" -p "$USER@$HOSTNAME" -mesg "Uptime: $up") || exit 0

case "$choice" in
    "$lock")    exec "$HOME/.local/bin/lock" ;;
    "$suspend") exec systemctl suspend ;;
esac

ok=$(printf "%s\n" "$yes" "$no" \
    | rofi -dmenu -theme "$THEME" -theme-str "listview { columns: 2; } window { width: 420px; }" \
        -p "Confirm?" -mesg "Confirm or cancel the action") || exit 0
[ "$ok" = "$yes" ] || exit 0

case "$choice" in
    "$logout")   loginctl terminate-session "$XDG_SESSION_ID" ;;
    "$reboot")   systemctl reboot ;;
    "$shutdown") systemctl poweroff ;;
esac
