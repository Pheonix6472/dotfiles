#!/usr/bin/env bash
source "$HOME/.config/rofi/audio-devices.sh"
# System Menu - Port of binoymanoj/dotfiles, design after adi1090x
TERMINAL="kitty"
S="$HOME/.config/rofi/scripts"
THEME="$HOME/.config/rofi/menu.rasi"

ico() { printf "\u$1"; }
I_MENU=$(ico f0c9)
I_APPS=$(ico f009)
I_TUI=$(ico f120)
I_INSTALL=$(ico f019)
I_UPDATE=$(ico f021)
I_REMOVE=$(ico f1f8)
I_PERF=$(ico f0e4)
I_WIFI=$(ico f1eb)
I_BT=$(ico f293)
I_TOOLS=$(ico f0ad)
I_SEARCH=$(ico f002)
I_SVC=$(ico f013)
I_SCRIPT=$(ico f121)
I_TASK=$(ico f080)
I_ABOUT=$(ico f05a)
I_POWER=$(ico f011)
I_VOLUME=$(ico f028)

item() { printf "%s   %s\n" "$1" "$2"; }
rofi_menu() { rofi -dmenu -i -theme "$THEME" -p "$1" -theme-str "entry { placeholder: \"$2\"; }"; }
notify() { notify-send "$@" 2>/dev/null || true; }
term_hold() { $TERMINAL -e bash -c "$1; read -rp \"Press Enter to close \""; }

show_main_menu() {
  item "$I_APPS" "Apps"
  item "$I_SCRIPT" "Scripts"
  item "$I_TOOLS" "Tools"
  item "$I_TUI" "TUI Apps"
  item "$I_INSTALL" "Install"
  item "$I_UPDATE" "Update"
  item "$I_REMOVE" "Remove"
  item "$I_VOLUME" "Volume"
  item "$I_PERF" "Performance"
  item "$I_WIFI" "WiFi"
  item "$I_BT" "Bluetooth"
  item "$I_SEARCH" "Search"
  item "$I_SVC" "Services"
  item "$I_TASK" "Task Manager"
  item "$I_ABOUT" "About"
  item "$I_POWER" "System"
}

show_apps() {
  exec rofi -show drun -show-icons -theme "$THEME" -drun-display-format "{name}" \
    -display-drun "$I_APPS" -theme-str "entry { placeholder: \"Search apps\"; }"
}

show_tools() {
  local sel f
  sel=$(printf "%s\n" "Screenshot Area" "Screenshot Full" "Color Picker" "Clipboard" "Wallpaper" "Emoji" |
    rofi_menu "$I_TOOLS" "Tools") || return
  f="$HOME/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png"
  mkdir -p "$(dirname "$f")"
  case "$sel" in
  "Screenshot Area") shot area "$f" ;;
  "Screenshot Full") shot full "$f" ;;
  "Color Picker") hyprpicker -a ;;
  "Clipboard") cliphist list | rofi_menu "$I_TOOLS" "Clipboard" | cliphist decode | wl-copy ;;
  "Wallpaper") "$S/wallpaper-selector.sh" ;;
  "Emoji") rofi -modi emoji -show emoji -theme "$THEME" ;;
  esac
}

show_tui() {
  local candidates=(btop htop yazi lazygit lazydocker ncdu glances nmon ranger gotop s-tui nethogs iftop iotop)
  local avail=() a sel
  for a in "${candidates[@]}"; do command -v "$a" >/dev/null 2>&1 && avail+=("$a"); done
  [ ${#avail[@]} -eq 0 ] && {
    notify "TUI Apps" "No TUI apps found"
    return
  }
  sel=$(printf "%s\n" "${avail[@]}" | rofi_menu "$I_TUI" "TUI Apps") || return
  [ -z "$sel" ] && return
  case "$sel" in
  nethogs | iftop | iotop) term_hold "sudo $sel" ;;
  *) setsid -f $TERMINAL -e "$sel" ;;
  esac
}

show_install() {
  local mgr pkg
  mgr=$(printf "%s\n" "Pacman" "Yay (AUR)" | rofi_menu "$I_INSTALL" "Install with") || return
  case "$mgr" in
  Pacman)
    pkg=$(pacman -Slq | rofi_menu "$I_INSTALL" "Search package") || return
    [ -n "$pkg" ] && term_hold "sudo pacman -S $pkg"
    ;;
  Yay*)
    pkg=$(yay -Slq | rofi_menu "$I_INSTALL" "Search package") || return
    [ -n "$pkg" ] && term_hold "yay -S $pkg"
    ;;
  esac
}

show_update() {
  local mgr
  mgr=$(printf "%s\n" "Pacman" "Yay (Pacman + AUR)" | rofi_menu "$I_UPDATE" "Update with") || return
  case "$mgr" in
  Pacman) term_hold "sudo pacman -Syu" ;;
  Yay*) term_hold "yay -Syu" ;;
  esac
}

show_remove() {
  local pkg
  pkg=$(pacman -Qq | rofi_menu "$I_REMOVE" "Remove package") || return
  [ -n "$pkg" ] && term_hold "sudo pacman -R $pkg"
}

show_performance() {
  command -v powerprofilesctl >/dev/null || {
    notify "Power Profile" "power-profiles-daemon missing"
    return
  }
  local cur sel p
  cur=$(powerprofilesctl get)
  sel=$(for p in performance balanced power-saver; do
    if [ "$p" = "$cur" ]; then echo "$p (active)"; else echo "$p"; fi
  done | rofi_menu "$I_PERF" "Power Profile") || return
  sel=${sel%% *}
  [ -n "$sel" ] && powerprofilesctl set "$sel" && notify "Power Profile" "Switched to $sel"
}

show_wifi() {
  local act ssid pw
  act=$(printf "%s\n" "Connect / Disconnect" "Turn On" "Turn Off" "Restart" | rofi_menu "$I_WIFI" "WiFi") || return
  case "$act" in
  "Connect / Disconnect")
    ssid=$(nmcli -t -f SSID dev wifi list | sort -u | grep -v "^$" | rofi_menu "$I_WIFI" "Choose network") || return
    [ -z "$ssid" ] && return
    if nmcli -t -f NAME connection show --active | grep -Fxq "$ssid"; then
      nmcli connection down id "$ssid" >/dev/null && notify "WiFi" "Disconnected from $ssid"
    elif nmcli dev wifi connect "$ssid" >/dev/null 2>&1; then
      notify "WiFi" "Connected to $ssid"
    else
      pw=$(rofi -dmenu -password -theme "$THEME" -p "$I_WIFI" -theme-str "entry { placeholder: \"Password for $ssid\"; }" </dev/null) || return
      [ -z "$pw" ] && return
      if nmcli dev wifi connect "$ssid" password "$pw" >/dev/null 2>&1; then
        notify "WiFi" "Connected to $ssid"
      else
        notify "WiFi" "Connection to $ssid failed"
      fi
    fi
    ;;
  "Turn On") nmcli radio wifi on ;;
  "Turn Off") nmcli radio wifi off ;;
  "Restart") nmcli radio wifi off && sleep 2 && nmcli radio wifi on ;;
  esac
}

show_bluetooth() {
  local act dev mac
  act=$(printf "%s\n" "Connect / Disconnect" "Turn On" "Turn Off" "Restart" | rofi_menu "$I_BT" "Bluetooth") || return
  case "$act" in
  "Connect / Disconnect")
    dev=$(bluetoothctl devices | while read -r _ m n; do
      if bluetoothctl info "$m" | grep -q "Connected: yes"; then echo "$m $n (connected)"; else echo "$m $n"; fi
    done | rofi_menu "$I_BT" "Choose device") || return
    [ -z "$dev" ] && return
    mac=${dev%% *}
    if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
      bluetoothctl disconnect "$mac" >/dev/null && notify "Bluetooth" "Disconnected"
    else
      bluetoothctl connect "$mac" >/dev/null && notify "Bluetooth" "Connected"
    fi
    ;;
  "Turn On") bluetoothctl power on >/dev/null ;;
  "Turn Off") bluetoothctl power off >/dev/null ;;
  "Restart") bluetoothctl power off >/dev/null && sleep 2 && bluetoothctl power on >/dev/null ;;
  esac
}

show_search() {
  local in engine q
  in=$(printf "" | rofi_menu "$I_SEARCH" "Search or URL  (!g Google, !y YouTube)") || return
  [ -z "$in" ] && return
  case "$in" in
  http://* | https://*)
    setsid -f xdg-open "$in" >/dev/null 2>&1
    return
    ;;
  esac
  engine="https://duckduckgo.com/?q="
  case "$in" in
  "!g "*)
    engine="https://www.google.com/search?q="
    in=${in#"!g "}
    ;;
  "!y "*)
    engine="https://www.youtube.com/results?search_query="
    in=${in#"!y "}
    ;;
  esac
  q=$(jq -rn --arg s "$in" "\$s|@uri")
  setsid -f xdg-open "$engine$q" >/dev/null 2>&1
}

show_services() {
  local candidates=(docker ufw sshd tailscaled NetworkManager bluetooth kanata cups)
  local list=() s svc act
  for s in "${candidates[@]}"; do
    systemctl list-unit-files "$s.service" 2>/dev/null | grep -q "^$s.service" && list+=("$s")
  done
  [ ${#list[@]} -eq 0 ] && {
    notify "Services" "No services found"
    return
  }
  svc=$(printf "%s\n" "${list[@]}" | rofi_menu "$I_SVC" "Services") || return
  [ -z "$svc" ] && return
  if systemctl is-active --quiet "$svc"; then
    act=$(printf "%s\n" "Stop" "Restart" "Status" | rofi_menu "$I_SVC" "$svc (active)") || return
  else
    act=$(printf "%s\n" "Start" "Status" | rofi_menu "$I_SVC" "$svc (inactive)") || return
  fi
  case "$act" in
  Start) term_hold "sudo systemctl start $svc" ;;
  Stop) if [ "$svc" = docker ]; then term_hold "sudo systemctl stop docker docker.socket"; else term_hold "sudo systemctl stop $svc"; fi ;;
  Restart) term_hold "sudo systemctl restart $svc" ;;
  Status) term_hold "systemctl status $svc --no-pager" ;;
  esac
}

show_scripts() {
  local act
  act=$(printf "%s\n" "Toggle VPN" "Update all packages" "Clear cache" "Change wallpaper" "Restart network" |
    rofi_menu "$I_SCRIPT" "Scripts") || return
  case "$act" in
  "Toggle VPN")
    output=$(nordvpn-toggle 2>&1)
    notify "VPN" "$(printf '%s\n' "$output" | grep -E 'You are connected|You are disconnected|Connecting to ')"
    ;;
  "Update all packages") term_hold "yay -Syu" ;;
  "Clear cache") term_hold "yay -Sc --noconfirm; sudo pacman -Sc --noconfirm" ;;
  "Change wallpaper") "$S/wallpaper-selector.sh" ;;
  "Restart network") term_hold "sudo systemctl restart NetworkManager" ;;
  esac
}

show_volume() {
  local devices act volume mute low high back selected=0 notification_id=0

  mute=$(ico f026)
  low=$(ico f027)
  high=$(ico f028)
  devices=$(ico f025)
  back=$(ico f08b)
  while true; do
    act=$(printf '%s\n' "$mute" "$low" "$high" "$devices" "$back" |
      rofi -dmenu -i -theme "$THEME" \
        -p "$I_VOLUME" \
        -theme-str "entry { placeholder: \"Volume\"; }" \
        -selected-row "$selected") || return

    case "$act" in
    "$mute")
      if [ "$(pamixer --get-mute)" = "false" ]; then
        pamixer -m
        notification_id=$(notify-send \
          -r "$notification_id" \
          -h int:value:0 \
          -p "Volume" "Mute")
      else
        pamixer -u
        volume=$(pamixer --get-volume)
        notification_id=$(notify-send \
          -r "$notification_id" \
          -h "int:value:$volume" \
          -p "Volume" "$volume%")
      fi
      selected=0
      ;;

    "$low")
      pamixer --allow-boost -d 5
      volume=$(pamixer --get-volume)
      notification_id=$(notify-send \
        -r "$notification_id" \
        -h "int:value:$volume" \
        -p "Volume" "$volume%")
      selected=1
      ;;

    "$high")
      pamixer --allow-boost -i 5
      volume=$(pamixer --get-volume)
      notification_id=$(notify-send \
        -r "$notification_id" \
        -h "int:value:$volume" \
        -p "Volume" "$volume%")
      selected=2
      ;;

    "$devices")
      show_audio_devices
      selected=3
      ;;
    "$back")
      return
      ;;
    esac
  done
}

CHOICE=$(show_main_menu | rofi_menu "$I_MENU" "System Menu") || exit 0
case "$CHOICE" in
*"Volume") show_volume ;;
*"TUI Apps") show_tui ;;
*"Apps") show_apps ;;
*"Tools") show_tools ;;
*"Scripts") show_scripts ;;
*"Install") show_install ;;
*"Update") show_update ;;
*"Remove") show_remove ;;
*"Performance") show_performance ;;
*"WiFi") show_wifi ;;
*"Bluetooth") show_bluetooth ;;
*"Search") show_search ;;
*"Services") show_services ;;
*"Task Manager") setsid -f $TERMINAL -e btop ;;
*"About") term_hold "fastfetch" ;;
*"System") exec "$S/power-menu.sh" ;;
esac
