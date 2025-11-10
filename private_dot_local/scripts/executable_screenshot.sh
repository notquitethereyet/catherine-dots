#!/usr/bin/env sh

# Function to restore the shader after taking a screenshot
restore_shader() {
	if [ -n "$shader" ]; then
		hyprshade on "$shader"
	fi
}

# Function to save the current shader state and turn off shaders
save_shader() {
	shader=$(hyprshade current)
	hyprshade off
	trap restore_shader EXIT
}

save_shader # Save the current shader state

# Define directories for saving screenshots
if [ -z "$XDG_PICTURES_DIR" ]; then
	XDG_PICTURES_DIR="$HOME/Pictures"
fi

scrDir=$(dirname "$(realpath "$0")")
save_dir="${2:-$XDG_PICTURES_DIR/Screenshots}"
save_file=$(date +'%y%m%d_%Hh%Mm%Ss_screenshot.png') 
temp_screenshot="/tmp/screenshot.png"

# Create directories if they don't exist
mkdir -p "$save_dir"

# Function to display usage if an invalid option is provided
print_error() {
	cat <<"EOF"
Usage: ./screenshot.sh <action>
    Valid actions:
        p  : Capture all screens
        s  : Partial capture (select area)
        sf : Partial capture (frozen screen)
        m  : Capture focused monitor
        w  : Capture focused window
EOF
}

# Main action logic
case $1 in
p) # Capture all monitors
	grimblast copysave screen "$temp_screenshot" && restore_shader && swappy -f "$temp_screenshot"
	;;
s) # Capture a selected area
	grimblast copysave area "$temp_screenshot" && restore_shader && swappy -f "$temp_screenshot"
	;;
sf) # Capture a selected area with a frozen screen
	grimblast --freeze copysave area "$temp_screenshot" && restore_shader && swappy -f "$temp_screenshot"
	;;
m) # Capture the focused monitor
	grimblast copysave output "$temp_screenshot" && restore_shader && swappy -f "$temp_screenshot"
	;;
w) # Capture the focused window
	grimblast copysave active "$temp_screenshot" && restore_shader && swappy -f "$temp_screenshot"
	;;
*) # Invalid option
	print_error
	exit 1
	;;
esac

# Save the screenshot file to the target directory
mv "$temp_screenshot" "${save_dir}/${save_file}"

# Send a notification with the location of the saved screenshot
if [ -f "${save_dir}/${save_file}" ]; then
	notify-send -a "Screenshot" -i "${save_dir}/${save_file}" "Screenshot saved in ${save_dir}"
fi
