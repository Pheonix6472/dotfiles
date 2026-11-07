function ffcenter
    set -l cols (tput cols)
    set -l logo_width (command fastfetch --pipe 2>/dev/null | string replace -r "\e\[[0-9;]*m" "" | awk "{ if (length > max) max = length } END { print max+0 }")
    set -l padding (math "max(0, floor(($cols - $logo_width) / 2))")
    command fastfetch --logo-padding-left $padding $argv
end
