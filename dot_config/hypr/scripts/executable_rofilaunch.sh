#!/usr/bin/env sh

# Set variables
HOME = "~"
scrDir="${HOME}/.config/hypr/scripts/"
confDir="${HOME}/.config/"  # Assuming config files are one level up from scripts
roconf="${confDir}/rofi/config/launcher.rasi"  # Default fallback style

# Set rofi scale default if it's not a valid number
[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10

# If specified style file doesn't exist, fallback to first available style
if [ ! -f "${roconf}" ]; then
    roconf="$(find "${confDir}/rofi/styles" -type f -name "style_*.rasi" | sort -t '_' -k 2 -n | head -1)"
fi

# Determine rofi mode based on input argument
case "${1}" in
    d|--drun) r_mode="drun" ;; 
    w|--window) r_mode="window" ;;
    f|--filebrowser) r_mode="filebrowser" ;;
    h|--help)
        echo -e "$(basename "${0}") [action]"
        echo "d :  drun mode"
        echo "w :  window mode"
        echo "f :  filebrowser mode"
        exit 0 ;;
    *) r_mode="drun" ;;
esac

# Set styling overrides for rofi
wind_border=15  # Arbitrary default border
elem_border=10
r_override="window {border: 3px; border-radius: ${wind_border}px;} element {border-radius: ${elem_border}px;}"
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
i_override="configuration {icon-theme: \"default\";}"

# Launch rofi with selected mode and styling
rofi -show "${r_mode}" -theme-str "${r_scale}" -theme-str "${r_override}" -theme-str "${i_override}" -config "${roconf}"
