#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
backup="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

do_packages=0
do_system=0
for arg in "$@"; do
  case "$arg" in
    --packages) do_packages=1 ;;
    --system) do_system=1 ;;
    -h|--help) echo "usage: ./install.sh [--packages] [--system]"; exit 0 ;;
    *) echo "unknown option: $arg"; exit 1 ;;
  esac
done

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    return
  fi
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    mkdir -p "$backup/$(dirname "${dst#"$HOME"/}")"
    mv "$dst" "$backup/${dst#"$HOME"/}"
  fi
  ln -s "$src" "$dst"
}

if [ "$do_packages" = 1 ]; then
  mapfile -t native < <(grep -hvE "^(#|$)" "$repo/packages/native.txt")
  sudo pacman -S --needed "${native[@]}"
  if command -v yay >/dev/null; then
    mapfile -t aur < <(grep -hvE "^(#|$)" "$repo/packages/aur.txt")
    yay -S --needed "${aur[@]}"
  else
    echo "yay not found, skipping packages/aur.txt"
  fi
fi

while IFS= read -r -d "" file; do
  rel="${file#"$repo"/home/}"
  [ "$rel" = ".config/matugen/config.toml" ] && continue
  link "$file" "$HOME/$rel"
done < <(find "$repo/home" -type f -print0)

cfg="$HOME/.config/matugen/config.toml"
[ -f "$cfg" ] || { mkdir -p "$(dirname "$cfg")"; cp "$repo/home/.config/matugen/config.toml" "$cfg"; }
zen="$(find "$HOME/.config/zen" -maxdepth 1 -type d -name "*Default*" 2>/dev/null | head -n1 || true)"
if [ -n "$zen" ]; then
  sed -i "s|sp3qvr5x.Default (release)|$(basename "$zen")|g" "$cfg"
else
  sed -i -E "/^[[]templates.zen-user/,/^\$/d" "$cfg"
fi

mkdir -p "$HOME/Pictures/Wallpaper" "$HOME/Pictures/Screenshots"
systemctl --user daemon-reload || true
systemctl --user enable awww.service sysstat.service || true

if [ "$do_system" = 1 ]; then
  theme=/usr/share/sddm/themes/matugen
  sudo groupadd -f sddmtheme
  sudo usermod -aG sddmtheme "$USER"
  sudo install -d -m 2775 -o "$USER" -g sddmtheme "$theme" "$theme/Assets" "$theme/Assets/avatars" "$theme/Backgrounds"
  for f in Main.qml metadata.desktop qmldir theme.conf; do
    sudo install -m 664 -o "$USER" -g sddmtheme "$repo/system$theme/$f" "$theme/$f"
  done
  sudo install -d /etc/sddm.conf.d
  sudo install -m 644 "$repo"/system/etc/sddm.conf.d/*.conf /etc/sddm.conf.d/
  if [ ! -f "$theme/Colors.qml" ] && command -v matugen >/dev/null; then
    matugen color hex "#c9b890" -m dark || echo "could not generate Colors.qml, run wallpaper once"
  fi
  echo "log out and back in so the sddmtheme group applies"
fi

echo "done, now run: wallpaper /path/to/image"
