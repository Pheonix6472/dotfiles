show_audio_devices() {
  local input output back act selected=0

  input=$(ico f130)
  output=$(ico f025)
  back=$(ico f08b)

  while true; do
    act=$(printf "%s\n" "$input" "$output" "$back" |
      rofi -dmenu -i -theme "$THEME" \
        -p "$I_VOLUME" \
        -theme-str "entry { placeholder: \"Audio devices\"; }" \
        -selected-row "$selected") || return

    case "$act" in
    "$input")
      select_audio_device sources "Input"
      selected=0
      ;;
    "$output")
      select_audio_device sinks "Output"
      selected=1
      ;;
    "$back")
      return
      ;;
    esac
  done
}

select_audio_device() {
  local kind=$1 label=$2 filter=true data default active idx line name desc id

  [ "$kind" = sources ] && filter=".monitor_of_sink == null"

  data=$(pactl -f json list "$kind" | jq -r ".[] | select($filter) | [.name, .description] | @tsv")
  if [ -z "$data" ]; then
    notify-send "Audio" "No $label devices found"
    return
  fi

  default=$(pactl "get-default-${kind%s}")
  active=$(printf "%s\n" "$data" | awk -F "\t" -v d="$default" "\$1 == d { print NR - 1 }" | head -n1)

  idx=$(printf "%s\n" "$data" | cut -f2 |
    rofi -dmenu -i -format i -theme "$THEME" \
      -p "$label" \
      -theme-str "entry { placeholder: \"$label\"; }" \
      -selected-row "${active:-0}") || return

  line=$(printf "%s\n" "$data" | sed -n "$((idx + 1))p")
  name=$(printf "%s\n" "$line" | cut -f1)
  desc=$(printf "%s\n" "$line" | cut -f2)

  pactl "set-default-${kind%s}" "$name"

  if [ "$kind" = sinks ]; then
    for id in $(pactl list short sink-inputs | cut -f1); do
      pactl move-sink-input "$id" "$name"
    done
  else
    for id in $(pactl list short source-outputs | cut -f1); do
      pactl move-source-output "$id" "$name"
    done
  fi

  notify-send "Audio" "$label: $desc"
}
