#!/usr/bin/env bash
WALLPAPER_DIR="$HOME/Pictures/Wallpaper"
CACHE_DIR="$HOME/.cache/rofi-wallpaper"
THEME="$HOME/.config/rofi/wallpaper.rasi"
THUMB="360x200"

mkdir -p "$CACHE_DIR"
[ -d "$WALLPAPER_DIR" ] || {
  notify-send -u critical "Wallpaper" "Folder missing: $WALLPAPER_DIR" 2>/dev/null
  exit 1
}

IM=$(command -v magick || command -v convert)

mapfile -t walls < <(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.bmp" \) | sort)
[ ${#walls[@]} -eq 0 ] && {
  notify-send "Wallpaper" "No images in $WALLPAPER_DIR" 2>/dev/null
  exit 1
}

thumb_of() {
  local b
  b=$(basename "$1")
  echo "$CACHE_DIR/${b%.*}_thumb.jpg"
}

for w in "${walls[@]}"; do
  t=$(thumb_of "$w")
  if [ ! -f "$t" ] && [ -n "$IM" ]; then
    "$IM" "$w" -resize "$THUMB^" -gravity center -extent "$THUMB" -quality 85 "$t" 2>/dev/null
  fi
done

set_wallpaper() {
  local img="$1"
  wallpaper "$img"
  notify-send "Wallpaper" "$(basename "$img")" --icon="$img" 2>/dev/null || true
}

idx=$(
  for w in "${walls[@]}"; do
    b=$(basename "$w")
    printf "%s\0icon\x1f%s\n" "${b%.*}" "$(thumb_of "$w")"
  done | rofi -dmenu -i -theme "$THEME" -show-icons -format i -p "$(printf "\uf03e")" -theme-str "entry { placeholder: \"Choose wallpaper\"; }"
) || exit 0

[ -n "$idx" ] && set_wallpaper "${walls[$idx]}"
