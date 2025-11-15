# Rofi Theming and Layout Configuration Guide

A comprehensive guide to implementing dynamic rofi theming and layout configuration based on HyDE's architecture.

## Table of Contents

1. [Overview](#overview)
2. [Color System](#color-system)
3. [Theme File Structure](#theme-file-structure)
4. [Dynamic Layout Configuration](#dynamic-layout-configuration)
5. [Runtime Overrides](#runtime-overrides)
6. [Configuration Options](#configuration-options)
7. [Implementation Examples](#implementation-examples)
8. [Complete Implementation Guide](#complete-implementation-guide)

---

## Overview

HyDE's rofi theming system uses a multi-layered approach:

1. **Template-based color system** (`.dcol` files) - Dynamic color generation from wallpapers
2. **Static theme files** (`.rasi` files) - Layout and structure definitions
3. **Dynamic runtime overrides** - Script-based layout calculations and theme string overrides
4. **Configuration management** - TOML-based configuration for style selection

### Architecture Flow

```
Wallpaper → Color Extraction → dcol Template → theme.rasi → Rofi Style Files → Runtime Overrides → Rofi Instance
```

---

## Color System

### Dcol Template Format

Dcol (dynamic color) templates use placeholders that get replaced with actual color values.

#### Template Structure

```bash
# Line 1: Target file path (required)
$HOME/.config/rofi/theme.rasi

# Line 2+: Template content with placeholders
* {
    main-bg:            #<wallbash_pry1>B3;
    main-fg:            #<wallbash_1xa9>E6;
    main-br:            #<wallbash_pry3>E6;
    main-ex:            #<wallbash_pry2>E6;
    select-bg:          #<wallbash_4xa8>80;
    select-fg:          #<wallbash_4xa1>E6;
}
```

#### Color Placeholders

**Primary Colors:**
- `<wallbash_pry1>` through `<wallbash_pry4>` - Primary colors 1-4
- `<wallbash_txt1>` through `<wallbash_txt4>` - Text colors (inverted primaries) 1-4

**Accent Colors:**
- `<wallbash_1xa1>` through `<wallbash_1xa9>` - Accent colors for primary 1 (9 shades)
- `<wallbash_2xa1>` through `<wallbash_2xa9>` - Accent colors for primary 2
- `<wallbash_3xa1>` through `<wallbash_3xa9>` - Accent colors for primary 3
- `<wallbash_4xa1>` through `<wallbash_4xa9>` - Accent colors for primary 4

**RGBA Format:**
- `<wallbash_pry1_rgba>` - Primary color 1 in RGBA format
- `<wallbash_1xa1_rgba>` - Accent color in RGBA format

**RGB Format:**
- `<wallbash_pry1_rgb>` - Primary color 1 in RGB format (comma-separated)

**Special:**
- `<wallbash_mode>` - Color mode (dark/light)
- `<<HOME>>` - Home directory path

#### Color Alpha Suffixes

You can append alpha values directly to hex colors:
- `#<wallbash_pry1>B3` - Primary 1 with B3 (179/255) alpha
- `#<wallbash_pry1>E6` - Primary 1 with E6 (230/255) alpha
- `#<wallbash_pry1>80` - Primary 1 with 80 (128/255) alpha

### Color Replacement Implementation

```bash
#!/usr/bin/env bash

# Function to create wallbash substitutions
create_wallbash_substitutions() {
    local use_inverted=$1
    local sed_script
    
    # Mode substitution
    sed_script="s|<wallbash_mode>|$(${use_inverted} && printf "%s" "${dcol_invt:-light}" || printf "%s" "${dcol_mode:-dark}")|g;"
    
    # Primary and text colors (1-4)
    for i in {1..4}; do
        if ${use_inverted}; then
            rev_i=$((5 - i))
            src_i=$rev_i
        else
            src_i=$i
        fi
        
        local pry_var="dcol_pry${src_i}"
        local txt_var="dcol_txt${src_i}"
        local pry_rgba_var="dcol_pry${src_i}_rgba"
        local txt_rgba_var="dcol_txt${src_i}_rgba"
        local pry_rgb_var="dcol_pry${src_i}_rgb"
        local txt_rgb_var="dcol_txt${src_i}_rgb"
        
        # Create RGB from RGBA if needed
        if [[ -n "${!pry_rgba_var:-}" && -z "${!pry_rgb_var:-}" ]]; then
            declare -g "${pry_rgb_var}=$(sed -E 's/rgba\(([0-9]+,[0-9]+,[0-9]+),.*/\1/' <<<"${!pry_rgba_var}")"
            export "${pry_rgb_var?}"
        fi
        
        if [[ -n "${!txt_rgba_var:-}" && -z "${!txt_rgb_var:-}" ]]; then
            declare -g "${txt_rgb_var}=$(sed -E 's/rgba\(([0-9]+,[0-9]+,[0-9]+),.*/\1/' <<<"${!txt_rgba_var}")"
            export "${txt_rgb_var?}"
        fi
        
        # Add substitutions
        [ -n "${!pry_var:-}" ] && sed_script+="s|<wallbash_pry${i}>|${!pry_var}|g;"
        [ -n "${!txt_var:-}" ] && sed_script+="s|<wallbash_txt${i}>|${!txt_var}|g;"
        [ -n "${!pry_rgba_var:-}" ] && sed_script+="s|<wallbash_pry${i}_rgba(\([^)]*\))>|${!pry_rgba_var}|g;"
        [ -n "${!txt_rgba_var:-}" ] && sed_script+="s|<wallbash_txt${i}_rgba(\([^)]*\))>|${!txt_rgba_var}|g;"
        [ -n "${!pry_rgb_var:-}" ] && sed_script+="s|<wallbash_pry${i}_rgb>|${!pry_rgb_var}|g;"
        [ -n "${!txt_rgb_var:-}" ] && sed_script+="s|<wallbash_txt${i}_rgb>|${!txt_rgb_var}|g;"
        
        # Accent colors (1-9 for each primary)
        for j in {1..9}; do
            local xa_var="dcol_${src_i}xa${j}"
            local xa_rgba_var="dcol_${src_i}xa${j}_rgba"
            local xa_rgb_var="dcol_${src_i}xa${j}_rgb"
            
            if [[ -n "${!xa_rgba_var:-}" && -z "${!xa_rgb_var:-}" ]]; then
                declare -g "${xa_rgb_var}=$(sed -E 's/rgba\(([0-9]+,[0-9]+,[0-9]+),.*/\1/' <<<"${!xa_rgba_var}")"
                export "${xa_rgb_var?}"
            fi
            
            [ -n "${!xa_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}>|${!xa_var}|g;"
            [ -n "${!xa_rgba_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}_rgba(\([^)]*\))>|${!xa_rgba_var}|g;"
            [ -n "${!xa_rgb_var:-}" ] && sed_script+="s|<wallbash_${i}xa${j}_rgb>|${!xa_rgb_var}|g;"
        done
    done
    
    # Home directory substitution
    sed_script+="s|<<HOME>>|${HOME}|g"
    
    printf "%s" "$sed_script"
}

# Process template
fn_wallbash() {
    local template="${1}"
    local target_file
    local temp_target_file
    
    # Get target file from first line
    eval target_file="$(head -1 "${template}" | awk -F '|' '{print $1}')"
    
    # Create temp file (skip first line)
    temp_target_file="$(mktemp)"
    sed '1d' "${template}" >"${temp_target_file}"
    
    # Apply substitutions
    local sed_script=$(create_wallbash_substitutions false)
    sed -i "${sed_script}" "${temp_target_file}"
    
    # Move to target
    if [ -s "${temp_target_file}" ]; then
        mkdir -p "$(dirname "${target_file}")"
        mv "${temp_target_file}" "${target_file}"
    fi
}
```

---

## Theme File Structure

### Basic Rasi File Structure

```rasi
/**
 * ROFI Layout 
 *
 * Style Name: Description
 * Attribute: rofilaunch,launcher
 * User: Your Name
 * Copyright: Your Copyright
 */

// Config //
configuration {
    modi:                        "drun,filebrowser,window,run";
    show-icons:                  true;
    display-drun:                "  ";
    display-run:                 "  ";
    display-filebrowser:         "  ";
    display-window:              "  ";
    drun-display-format:         "{name}";
    window-format:               "{w}{t}";
    font:                        "JetBrainsMono Nerd Font 10";
    icon-theme:                  "Tela-circle-dracula";
}

// Import color theme
@theme "~/.config/rofi/theme.rasi"

// Main Window //
window {
    height:                      33em;
    width:                       63em;
    transparency:                "real";
    fullscreen:                  false;
    enabled:                     true;
    cursor:                      "default";
    spacing:                     0em;
    padding:                     0em;
    border:                      2px;
    border-radius:               10px;
    border-color:                @main-br;
    background-color:            @main-bg;
}

// Main Container //
mainbox {
    enabled:                     true;
    spacing:                     0em;
    padding:                     0em;
    orientation:                 horizontal;  // or vertical
    children:                    [ "dummywall", "listbox" ];
    background-color:            transparent;
}

// List Container //
listbox {
    spacing:                     0em;
    padding:                     2em;
    orientation:                 horizontal;  // or vertical
    children:                    [ "listview" ];
    background-color:            transparent;
}

// List View //
listview {
    enabled:                     true;
    spacing:                     0em;
    padding:                     0em;
    columns:                     1;           // Number of columns
    lines:                       8;           // Number of lines
    cycle:                       true;        // Cycle through items
    dynamic:                     true;        // Dynamic sizing
    scrollbar:                   false;       // Show scrollbar
    layout:                      vertical;    // or horizontal
    reverse:                     false;       // Reverse order
    expand:                      false;       // Expand to fill space
    fixed-height:                true;        // Fixed height
    fixed-columns:               true;        // Fixed column count
    cursor:                      "default";
    background-color:            transparent;
    text-color:                  @main-fg;
}

// List Elements //
element {
    enabled:                     true;
    spacing:                     0.8em;
    padding:                     0.4em 0.4em 0.4em 1.5em;
    cursor:                      pointer;
    background-color:            transparent;
    text-color:                  @main-fg;
}

element selected.normal {
    background-color:            @select-bg;
    text-color:                  @select-fg;
}

element-icon {
    size:                        2.8em;
    cursor:                      inherit;
    background-color:            transparent;
    text-color:                  inherit;
}

element-text {
    vertical-align:              0.5;
    horizontal-align:            0.0;
    cursor:                      inherit;
    background-color:            transparent;
    text-color:                  inherit;
}
```

### Color Variables Reference

The `@theme` directive imports color variables from `theme.rasi`:

```rasi
* {
    main-bg:            #11111be6;    // Main background
    main-fg:            #cdd6f4ff;    // Main foreground/text
    main-br:            #cba6f7ff;    // Main border/accent
    main-ex:            #f5e0dcff;    // Extra color
    select-bg:          #b4befeff;    // Selected background
    select-fg:          #11111bff;    // Selected foreground
    separatorcolor:     transparent;  // Separator color
    border-color:       transparent;  // Border color
}
```

### Common Layout Patterns

#### Pattern 1: Sidebar with List (Style 1)

```rasi
mainbox {
    orientation:                 horizontal;
    children:                    [ "dummywall", "listbox" ];
}

dummywall {
    width:                       37em;
    orientation:                 horizontal;
    children:                    [ "mode-switcher", "inputbar" ];
    background-image:            url("~/.cache/wall.thmb", height);
}

listview {
    columns:                     1;
    lines:                       8;
    layout:                      vertical;
}
```

#### Pattern 2: Grid Layout (Selector)

```rasi
mainbox {
    orientation:                 horizontal;
    children:                    [ "dummy", "frame", "dummy" ];
}

listview {
    columns:                     10;
    lines:                       1;
    layout:                      vertical;
    fixed-columns:               true;
}
```

#### Pattern 3: Two-Panel Layout (Style 2)

```rasi
mainbox {
    orientation:                 vertical;
    children:                    [ "inputbar", "listbox" ];
}

listbox {
    orientation:                 horizontal;
    children:                    [ "listview", "mode-switcher" ];
}

listview {
    columns:                     2;
    lines:                       3;
    layout:                      vertical;
}
```

---

## Dynamic Layout Configuration

### Monitor Resolution Detection

```bash
#!/usr/bin/env bash

# Get monitor data
mon_data=$(hyprctl -j monitors)

# Get horizontal resolution (accounting for rotation)
mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")

# Get scale factor
mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")

# Calculate actual resolution (accounting for scale)
mon_x_res=$((mon_x_res * 100 / mon_scale))

# Fallback values
mon_x_res=${mon_x_res:-1920}
mon_scale=${mon_scale:-1}
```

### Dynamic Column Calculation

```bash
#!/usr/bin/env bash

# Font scale (from config or default)
font_scale=${ROFI_SCALE:-10}

# Calculate element width
# Formula: (icon_size + padding + spacing) * font_scale * multiplier
elm_width=$(((23 + 12 + 1) * font_scale * 2))

# Calculate available space (accounting for padding)
max_avail=$((mon_x_res - (4 * font_scale)))

# Calculate column count
col_count=$((max_avail / elm_width))

# Apply limits
[[ "${col_count}" -gt 5 ]] && col_count=5
[[ "${col_count}" -lt 1 ]] && col_count=1
```

### Border Radius Calculation

```bash
#!/usr/bin/env bash

# Get hyprland border radius
hypr_border=${hypr_border:-"$(hyprctl -j getoption decoration:rounding | jq '.int')"}
hypr_border=${hypr_border:-10}

# Calculate element border (proportional to hyprland border)
elem_border=$((hypr_border * 5))
icon_border=$((elem_border - 5))
wind_border=$((hypr_border * 3))

# Handle zero border case
[ "${hypr_border}" -eq 0 ] && elem_border="10"
```

### Complete Dynamic Layout Example

```bash
#!/usr/bin/env bash

# Get monitor resolution
mon_data=$(hyprctl -j monitors)
mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")
mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
mon_x_res=$((mon_x_res * 100 / mon_scale))

# Get border settings
hypr_border=${hypr_border:-10}
hypr_width=${hypr_width:-2}
wind_border=$((hypr_border * 3))
elem_border=$((hypr_border * 5))
icon_border=$((elem_border - 5))

# Font settings
font_scale=${ROFI_SCALE:-10}
font_name=${ROFI_FONT:-"JetBrainsMono Nerd Font"}

# Calculate layout
elm_width=$(((23 + 12 + 1) * font_scale * 2))
max_avail=$((mon_x_res - (4 * font_scale)))
col_count=$((max_avail / elm_width))
[[ "${col_count}" -gt 5 ]] && col_count=5

# Build override string
r_override="window{
    width:100%;
    border:${hypr_width}px;
    border-radius:${wind_border}px;
} 
listview{
    columns:${col_count};
} 
element{
    border-radius:${elem_border}px;
    padding:0.5em;
} 
element-icon{
    size:23em;
    border-radius:${icon_border}px;
}"

font_override="* {font: \"${font_name} ${font_scale}\";}"
```

---

## Runtime Overrides

### Theme String Overrides

Rofi supports `-theme-str` flag to override theme properties at runtime:

```bash
rofi -dmenu \
    -theme-str "${font_override}" \
    -theme-str "${r_override}" \
    -theme "style_1"
```

### Override String Format

```bash
# Single property
r_override="window{border:2px;}"

# Multiple properties (same widget)
r_override="window{border:2px;border-radius:10px;}"

# Multiple widgets
r_override="window{border:2px;} listview{columns:5;} element{padding:1em;}"

# With color variables
r_override="window{background-color:@main-bg;} element{background-color:@select-bg;}"
```

### Common Override Patterns

#### Font Override

```bash
font_name="JetBrainsMono Nerd Font"
font_scale=10
font_override="* {font: \"${font_name} ${font_scale}\";}"
```

#### Icon Theme Override

```bash
icon_theme="Tela-circle-dracula"
i_override="configuration {icon-theme: \"${icon_theme}\";}"
```

#### Window Override

```bash
r_override="window{
    width:100%;
    height:50%;
    border:${hypr_width}px;
    border-radius:${wind_border}px;
    background-color:@main-bg;
}"
```

#### Listview Override

```bash
r_override="listview{
    columns:${col_count};
    lines:${line_count};
    spacing:1em;
    padding:2em;
    layout:vertical;
}"
```

#### Element Override

```bash
r_override="element{
    border-radius:${elem_border}px;
    padding:0.5em;
    orientation:vertical;
} 
element-icon{
    size:20em;
    border-radius:${icon_border}px;
} 
element-text{
    enabled:false;
}"
```

---

## Configuration Options

### TOML Configuration Structure

```toml
# Global rofi configuration
[rofi]
scale = 10  # Default font scale

# Rofi launcher configuration
[rofi.launch]
scale = 5
drun_style = "style_1"
window_style = "style_1"
run_style = "style_1"
filebrowser_style = "style_1"
drun_args = []
run_args = []
window_args = []
filebrowser_args = []

# Theme selector configuration
[rofi.theme]
scale = 10
style = "selector"  # Style for theme selector menu

# Style selector configuration
[rofi.select]
scale = 10
style = "selector"
```

### Environment Variables

```bash
# Global
ROFI_SCALE=10
ROFI_FONT="JetBrainsMono Nerd Font"

# Launcher
ROFI_LAUNCH_STYLE="style_1"
ROFI_LAUNCH_SCALE=5
ROFI_LAUNCH_FONT="JetBrainsMono Nerd Font"
ROFI_LAUNCH_DRUN_STYLE="style_1"
ROFI_LAUNCH_WINDOW_STYLE="style_1"
ROFI_LAUNCH_RUN_STYLE="style_1"
ROFI_LAUNCH_FILEBROWSER_STYLE="style_1"
ROFI_LAUNCH_DRUN_ARGS=()
ROFI_LAUNCH_WINDOW_ARGS=()
ROFI_LAUNCH_RUN_ARGS=()
ROFI_LAUNCH_FILEBROWSER_ARGS=()

# Theme selector
ROFI_THEME_STYLE="selector"
ROFI_THEME_SCALE=10
ROFI_THEME_FONT="JetBrainsMono Nerd Font"

# Style selector
ROFI_SELECT_STYLE="selector"
ROFI_SELECT_SCALE=10
ROFI_SELECT_FONT="JetBrainsMono Nerd Font"
```

---

## Implementation Examples

### Example 1: Basic Rofi Launcher

```bash
#!/usr/bin/env bash

# Load configuration
source ~/.config/dotfiles/config

# Get monitor resolution
mon_data=$(hyprctl -j monitors)
mon_x_res=$(jq '.[] | select(.focused==true) | .width' <<<"${mon_data}")
mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
mon_x_res=$((mon_x_res * 100 / mon_scale))

# Get border settings
hypr_border=${hypr_border:-10}
hypr_width=${hypr_width:-2}
wind_border=$((hypr_border * 3))
elem_border=$((hypr_border * 2))

# Font settings
font_scale=${ROFI_SCALE:-10}
font_name=${ROFI_FONT:-"JetBrainsMono Nerd Font"}

# Build overrides
font_override="* {font: \"${font_name} ${font_scale}\";}"
r_override="window{
    border:${hypr_width}px;
    border-radius:${wind_border}px;
} 
element{
    border-radius:${elem_border}px;
}"

# Launch rofi
rofi -show drun \
    -show-icons \
    -theme-str "${font_override}" \
    -theme-str "${r_override}" \
    -theme "style_1"
```

### Example 2: Dynamic Grid Selector

```bash
#!/usr/bin/env bash

# Get monitor resolution
mon_data=$(hyprctl -j monitors)
mon_x_res=$(jq '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width else .height end' <<<"${mon_data}")
mon_scale=$(jq '.[] | select(.focused==true) | .scale' <<<"${mon_data}" | sed "s/\.//")
mon_x_res=$((mon_x_res * 100 / mon_scale))

# Calculate columns
font_scale=${ROFI_SCALE:-10}
elm_width=$(((20 + 12 + 16) * font_scale))
max_avail=$((mon_x_res - (4 * font_scale)))
col_count=$((max_avail / elm_width))
[[ "${col_count}" -gt 5 ]] && col_count=5

# Border settings
hypr_border=${hypr_border:-10}
elem_border=$((hypr_border * 5))
icon_border=$((elem_border - 5))

# Build overrides
r_override="window{width:100%;} 
listview{columns:${col_count};}
element{
    orientation:vertical;
    border-radius:${elem_border}px;
}
element-icon{
    border-radius:${icon_border}px;
    size:20em;
} 
element-text{enabled:false;}"

# Launch selector
rofi -dmenu \
    -theme-str "${r_override}" \
    -theme "selector"
```

### Example 3: Cursor-Based Positioning

```bash
#!/usr/bin/env bash

# Get cursor position
readarray -t curPos < <(hyprctl cursorpos -j | jq -r '.x,.y')

# Get monitor info
readarray -t monRes < <(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width,.height,.scale,.x,.y')
readarray -t offRes < <(hyprctl -j monitors | jq -r '.[] | select(.focused==true).reserved | map(tostring) | join("\n")')

# Calculate scale-adjusted resolution
monRes[2]="${monRes[2]//./}"
monRes[0]=$((monRes[0] * 100 / monRes[2]))
monRes[1]=$((monRes[1] * 100 / monRes[2]))

# Adjust cursor position relative to monitor
curPos[0]=$((curPos[0] - monRes[3]))
curPos[1]=$((curPos[1] - monRes[4]))

# Determine position
if [ "${curPos[0]}" -ge "$((monRes[0] / 2))" ]; then
    x_pos="east"
    x_off="-$((monRes[0] - curPos[0] - offRes[2]))"
else
    x_pos="west"
    x_off="$((curPos[0] - offRes[0]))"
fi

if [ "${curPos[1]}" -ge "$((monRes[1] / 2))" ]; then
    y_pos="south"
    y_off="-$((monRes[1] - curPos[1] - offRes[3]))"
else
    y_pos="north"
    y_off="$((curPos[1] - offRes[1]))"
fi

# Build position override
r_override="window{
    location:${x_pos} ${y_pos};
    anchor:${x_pos} ${y_pos};
    x-offset:${x_off}px;
    y-offset:${y_off}px;
}"

rofi -dmenu \
    -theme-str "${r_override}" \
    -theme "style_1"
```

---

## Complete Implementation Guide

### Step 1: Directory Structure

```
~/.config/
├── rofi/
│   ├── config.rasi          # Main rofi config
│   └── theme.rasi           # Color theme (generated from dcol)
├── dotfiles/
│   ├── rofi/
│   │   └── themes/          # Rofi style files
│   │       ├── style_1.rasi
│   │       ├── style_2.rasi
│   │       └── selector.rasi
│   └── wallbash/
│       └── theme/
│           └── rofi.dcol    # Color template
└── hyde/
    └── config.toml          # Configuration file
```

### Step 2: Create Color Template

Create `~/.config/dotfiles/wallbash/theme/rofi.dcol`:

```bash
$HOME/.config/rofi/theme.rasi
* {
    main-bg:            #<wallbash_pry1>B3;
    main-fg:            #<wallbash_1xa9>E6;
    main-br:            #<wallbash_pry3>E6;
    main-ex:            #<wallbash_pry2>E6;
    select-bg:          #<wallbash_4xa8>80;
    select-fg:          #<wallbash_4xa1>E6;
    separatorcolor:     transparent;
    border-color:       transparent;
}
```

### Step 3: Create Theme Files

Create style files in `~/.config/dotfiles/rofi/themes/`:

- `style_1.rasi` - Your main launcher style
- `selector.rasi` - Grid selector style
- Additional styles as needed

### Step 4: Implement Color Processing

Create a script to process dcol templates (see Color Replacement Implementation section).

### Step 5: Create Launcher Script

Create `~/.local/bin/rofilaunch`:

```bash
#!/usr/bin/env bash
# Your launcher implementation
# (See Example 1 for reference)
```

### Step 6: Configuration Management

Create `~/.config/hyde/config.toml`:

```toml
[rofi]
scale = 10

[rofi.launch]
scale = 5
drun_style = "style_1"
window_style = "style_1"
```

### Step 7: Integration

1. Call color processing when wallpaper changes
2. Source configuration in launcher scripts
3. Use dynamic layout calculations for selectors
4. Apply runtime overrides via `-theme-str`

---

## Advanced Topics

### Fullscreen Detection

```bash
# Check if theme has fullscreen enabled
rofi -show drun \
    -config "style_1" \
    -dump-theme | \
    grep -q "fullscreen.*true" && \
    touch "${STATE_DIR}/fullscreen_drun" || \
    rm -f "${STATE_DIR}/fullscreen_drun"

# Use in launcher
if [[ -f "${STATE_DIR}/fullscreen_drun" ]]; then
    hypr_width="0"
    wind_border="0"
fi
```

### Vertical Monitor Detection

```bash
mon_data=$(hyprctl -j monitors)
is_vertical=$(jq -e '.[] | select(.focused==true) | if (.transform % 2 == 0) then .width / .height else .height / .width end < 1' <<<"${mon_data}")

if [[ "$is_vertical" == "true" ]]; then
    # Adjust layout for vertical monitor
    col_count=$((col_count / 2))
fi
```

### Multi-Monitor Support

```bash
# Get focused monitor
focused_mon=$(hyprctl -j monitors | jq '.[] | select(.focused==true)')

# Get all monitors
all_mons=$(hyprctl -j monitors)

# Calculate position relative to specific monitor
mon_x=$(jq '.x' <<<"${focused_mon}")
mon_y=$(jq '.y' <<<"${focused_mon}")
mon_width=$(jq '.width' <<<"${focused_mon}")
mon_height=$(jq '.height' <<<"${focused_mon}")
```

---

## Troubleshooting

### Common Issues

1. **Colors not updating**: Ensure dcol template is processed when wallpaper changes
2. **Layout breaks on different resolutions**: Use dynamic column calculation
3. **Font not applying**: Check font override string format
4. **Border radius inconsistent**: Ensure hypr_border is properly sourced
5. **Theme not found**: Check theme file path and `@theme` directive

### Debug Tips

```bash
# Test color replacement
sed "${sed_script}" template.dcol

# Dump rofi theme
rofi -show drun -dump-theme

# Test layout calculation
echo "Columns: ${col_count}, Width: ${elm_width}, Available: ${max_avail}"

# Check monitor data
hyprctl -j monitors | jq '.[] | select(.focused==true)'
```

---

## Reference

### Rofi Widgets

- `window` - Main window container
- `mainbox` - Main container box
- `inputbar` - Input/search bar
- `listbox` - List container
- `listview` - List view widget
- `element` - List item element
- `element-icon` - Element icon
- `element-text` - Element text
- `mode-switcher` - Mode switcher widget
- `button` - Button widget

### Rofi Properties

- `columns` - Number of columns
- `lines` - Number of lines
- `layout` - Layout direction (vertical/horizontal)
- `dynamic` - Dynamic sizing
- `fixed-columns` - Fixed column count
- `fixed-height` - Fixed height
- `spacing` - Spacing between elements
- `padding` - Internal padding
- `border-radius` - Border radius
- `background-color` - Background color
- `text-color` - Text color

### Color Format

- Hex: `#RRGGBB` or `#RRGGBBAA`
- RGBA: `rgba(R, G, B, A)`
- Variables: `@variable-name`

---

## License

This guide is based on HyDE's rofi theming system. Adapt as needed for your dotfiles.


