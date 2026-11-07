if status is-interactive
end
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim

abbr --add manco 'nvim ~/.config/mango/config.conf'

fish_add_path $HOME/.spicetify

starship init fish | source

fish_add_path $HOME/.local/bin
