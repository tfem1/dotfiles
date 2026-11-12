# shellcheck shell=bash
# Package selection and installation for the detected distro family.
# Sourced by install.sh; uses FAMILY, PROFILE, ROOT, DRY_RUN, ASSUME_YES, SDDM_THEME.

# Prints the cells of packages.tsv for this family and profile, one per line.
# A cell may hold several packages (spaces) and alternatives ("a|b").
# SDDM is left out with --no-sddm.
package_cells() {
  local column skip=""
  case "$FAMILY" in arch) column=3 ;; debian) column=4 ;; fedora) column=5 ;; openbsd) column=6 ;; yvis) column=7 ;; esac
  [[ -n ${SDDM_THEME:-} ]] || skip=sddm
  awk -F'\t' -v col="$column" -v profile="$PROFILE" -v skip="$skip" -v wm="wm-${WM:-hyprland}" '
    /^#/ || NF < 6 || $1 == skip { next }
    $2 ~ /^wm-/ { if ($2 == wm) print $1 "\t" $col; next }
    $2 == "core" || profile == "full" { print $1 "\t" $col }
  ' "$ROOT/install/packages.tsv"
}

package_available() {
  case "$FAMILY" in
    arch) pacman -Si "$1" >/dev/null 2>&1 ;;
    # "show" also succeeds for packages with no installable version: ask for the candidate.
    debian) [[ "$(apt-cache policy "$1" 2>/dev/null | awk '/Candidate:/ { print $2 }')" =~ ^[^\(] ]] ;;
    fedora) dnf info "$1" >/dev/null 2>&1 ;;
    # "python%3.12" is the branch of python-3.12.x; a stem must match a whole name.
    openbsd) pkg_info -Q "$(printf '%s' "$1" | tr '%' '-')" 2>/dev/null | grep -q "^$(printf '%s' "$1" | tr '%' '-')[-.0-9]" ;;
    # Installed or in a synced repository index.
    yvis) yone info "$1" >/dev/null 2>&1 ;;
  esac
}

# Fills CHOSEN (names to install), UNAVAILABLE and NOT_PACKAGED (keys).
resolve_packages() {
  CHOSEN=() UNAVAILABLE=() NOT_PACKAGED=()
  local key cell word option found
  while IFS=$'\t' read -r key cell; do
    if [[ $cell == - ]]; then
      NOT_PACKAGED+=("$key")
      continue
    fi
    for word in $cell; do
      found=""
      for option in ${word//|/ }; do
        if package_available "$option"; then found="$option" && break; fi
      done
      if [[ -n $found ]]; then CHOSEN+=("$found"); else UNAVAILABLE+=("$word"); fi
    done
  done < <(package_cells)
}

install_packages() {
  if [[ $FAMILY == debian ]] && ! ((DRY_RUN)); then sudo apt-get update; fi
  resolve_packages
  ((${#NOT_PACKAGED[@]})) && warn "not in the official $FAMILY repositories: ${NOT_PACKAGED[*]}"
  ((${#UNAVAILABLE[@]})) && warn "not found in your repositories, skipped: ${UNAVAILABLE[*]}"
  ((${#CHOSEN[@]})) || return 0
  info "installing ${#CHOSEN[@]} packages"
  case "$FAMILY" in
    arch)
      local confirm_flag=()
      ((ASSUME_YES)) && confirm_flag=(--noconfirm)
      run sudo pacman -S --needed "${confirm_flag[@]}" "${CHOSEN[@]}"
      ;;
    debian) run sudo apt install -y "${CHOSEN[@]}" ;;
    fedora) run sudo dnf install -y "${CHOSEN[@]}" ;;
    openbsd) run doas pkg_add -I "${CHOSEN[@]}" ;;
    yvis)
      local confirm_flag=()
      ((ASSUME_YES)) && confirm_flag=(--noconfirm)
      run sudo yone install "${confirm_flag[@]}" "${CHOSEN[@]}"
      ;;
  esac
}

# The Hyprland config is written in Lua, read by Hyprland 0.55 and newer.
# The window manager picked is there (Hyprland: and recent enough).
check_wm() {
  [[ $FAMILY == openbsd ]] && WM=hyprland   # nothing to install there: check_hyprland says why
  case "$WM" in
    sway | niri)
      if command -v "$WM" >/dev/null 2>&1; then
        info "$(wm_title) found"
      else
        warn "$(wm_title) is not installed: install the '$WM' package"
      fi
      ;;
    *) check_hyprland ;;
  esac
}

check_hyprland() {
  if [[ $FAMILY == openbsd ]]; then
    warn "OpenBSD has no Hyprland nor Quickshell yet (Hyprland's OpenBSD port is in progress):"
    warn "the desktop is not installed; your apps (kitty, GTK, Qt) get the themes."
    return 0
  fi
  if ! command -v Hyprland >/dev/null 2>&1; then
    warn "Hyprland is not installed: the desktop needs Hyprland 0.55 or newer."
    hyprland_hint
    return 0
  fi
  local version major minor
  version="$(Hyprland --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1 || true)"
  major="${version%%.*}"
  minor="${version#*.}" && minor="${minor%%.*}"
  if [[ -z $version ]]; then
    warn "could not read the Hyprland version; this config needs 0.55 or newer"
  elif ((major == 0 && minor < 55)); then
    warn "Hyprland $version is too old for this config (Lua, needs 0.55 or newer)"
    hyprland_hint
  else
    info "Hyprland $version found"
  fi
}

hyprland_hint() {
  case "$FAMILY" in
    fedora) warn "Fedora ships no Hyprland: enable a COPR you trust, e.g. 'sudo dnf copr enable sdegler/hyprland', then run the installer again." ;;
    debian) warn "Debian 13 has no Hyprland and Ubuntu 26.04 ships 0.53: use Debian testing or unstable." ;;
    arch) warn "Install it with: sudo pacman -S hyprland" ;;
    yvis) warn "Install it with: sudo yone install hyprland" ;;
  esac
}
