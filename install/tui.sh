# shellcheck shell=bash
# The installer's screen: the TFEM banner, then what will be installed, to
# change with the keyboard before anything happens. Pure bash and ANSI
# escapes, nothing to install. Sourced by install.sh; skipped with --yes,
# --dry-run or --no-tui, or without a terminal (the plain prompt is used).
#
#   up/down (or k/j)  move        space  turn on or off
#   left/right        choose      enter  install      q  quit

TUI_TTY="${TFEM_TTY:-/dev/tty}"
TUI_ACCENT=$'\033[38;2;95;208;192m'   # the teal of the default theme
TUI_DIM=$'\033[2m' TUI_BOLD=$'\033[1m' TUI_OFF=$'\033[0m'
TUI_ROW=0
TUI_LOGINS=(stacked-clock welcome-panel none)

tui_banner() {
  printf '%s' "$TUI_ACCENT$TUI_BOLD"
  cat <<'BANNER'
  ████████╗███████╗███████╗███╗   ███╗
  ╚══██╔══╝██╔════╝██╔════╝████╗ ████║
     ██║   █████╗  █████╗  ██╔████╔██║
     ██║   ██╔══╝  ██╔══╝  ██║╚██╔╝██║
     ██║   ██║     ███████╗██║ ╚═╝ ██║
     ╚═╝   ╚═╝     ╚══════╝╚═╝     ╚═╝
BANNER
  printf '%s' "$TUI_OFF"
  printf '  %sHyprland + Quickshell, one settings file%s\n\n' "$TUI_DIM" "$TUI_OFF"
}

# One line per choice: "label|variable|what it does". SDDM_THEME is a choice
# of three, the others are on or off.
tui_items() {
  local items=("Packages|WITH_PACKAGES|apps, Hyprland, Quickshell, fonts (asks for sudo)"
    "Wallpapers|WITH_WALLPAPERS|pixel-art forests and cats from wallhaven.cc"
    "Icons|WITH_ICONS|FairyWren, folders in the theme's color"
    "Monocraft|WITH_FONTS|the pixel font used everywhere")
  ((DESKTOP)) && items+=("Login screen|SDDM_THEME|SDDM theme, in the theme's colors (asks for sudo)")
  printf '%s\n' "${items[@]}"
}

tui_value() { # the text after the box: [x], [ ] or the login screen
  local name=$1
  if [[ $name == SDDM_THEME ]]; then
    printf '< %s >' "${SDDM_THEME:-none}"
  elif ((${!name})); then
    printf '%s[x]%s' "$TUI_ACCENT" "$TUI_OFF"
  else
    printf '[ ]'
  fi
}

tui_draw() {
  printf '\033[H\033[2J'
  tui_banner
  printf '  %sSystem:%s %s    %sInto:%s %s\n\n' "$TUI_BOLD" "$TUI_OFF" "$FAMILY" "$TUI_BOLD" "$TUI_OFF" "$ROOT"
  local index=0 label name text pointer
  while IFS='|' read -r label name text; do
    pointer="  "
    ((index == TUI_ROW)) && pointer="$TUI_ACCENT> $TUI_OFF"
    printf '  %s%-14s %s  %s%s%s\n' "$pointer" "$label" "$(tui_value "$name")" "$TUI_DIM" "$text" "$TUI_OFF"
    index=$((index + 1))
  done < <(tui_items)
  printf '\n  %sYour configs are backed up first; --uninstall puts them back.%s\n' "$TUI_DIM" "$TUI_OFF"
  printf '  %s↑↓ move   space on/off   ←→ choose   enter install   q quit%s\n' "$TUI_DIM" "$TUI_OFF"
}

tui_toggle() { # $1: the row's variable, $2: +1 or -1 for the login screen
  local name=$1 step=${2:-1} i
  if [[ $name == SDDM_THEME ]]; then
    for i in "${!TUI_LOGINS[@]}"; do
      [[ ${TUI_LOGINS[$i]} == "${SDDM_THEME:-none}" ]] && break
    done
    i=$(((i + step + ${#TUI_LOGINS[@]}) % ${#TUI_LOGINS[@]}))
    SDDM_THEME="${TUI_LOGINS[$i]}"
    [[ $SDDM_THEME == none ]] && SDDM_THEME=""
  else
    printf -v "$name" '%d' $((1 - ${!name}))
  fi
}

# Reads one key: up, down, left, right, space, enter, quit, or other.
tui_key() {
  local key rest
  IFS= read -rsn1 key <&3 || { echo quit; return; }
  case "$key" in
    $'\033')
      IFS= read -rsn2 -t 0.05 rest <&3 || rest=""
      case "$rest" in "[A") echo up ;; "[B") echo down ;; "[C") echo right ;; "[D") echo left ;; *) echo quit ;; esac ;;
    k) echo up ;; j) echo down ;; l) echo right ;; h) echo left ;;
    " ") echo space ;; "") echo enter ;; q | Q) echo quit ;; *) echo other ;;
  esac
}

# The screen; returns 1 when the user quits.
tui_run() {
  local rows names key
  mapfile -t names < <(tui_items | cut -d'|' -f2)
  rows=${#names[@]}
  exec 3<"$TUI_TTY"
  printf '\033[?25l'
  trap 'printf "\033[?25h"' EXIT
  while :; do
    tui_draw
    key="$(tui_key)"
    case "$key" in
      up) TUI_ROW=$(((TUI_ROW + rows - 1) % rows)) ;;
      down) TUI_ROW=$(((TUI_ROW + 1) % rows)) ;;
      space | right) tui_toggle "${names[$TUI_ROW]}" 1 ;;
      left) tui_toggle "${names[$TUI_ROW]}" -1 ;;
      enter) break ;;
      quit)
        exec 3<&-
        trap - EXIT
        printf '\033[?25h\n'
        return 1
        ;;
    esac
  done
  exec 3<&-
  trap - EXIT
  printf '\033[?25h\033[H\033[2J'
  tui_banner
}

# True when the screen can be shown: a terminal, and nothing said to skip it.
tui_wanted() {
  ((ASSUME_YES || DRY_RUN || ! WITH_TUI)) && return 1
  [[ -t 1 && ${TERM:-dumb} != dumb ]] && { : <"$TUI_TTY"; } 2>/dev/null
}
