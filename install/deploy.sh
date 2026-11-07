# shellcheck shell=bash
# Backup, deployment of the configs and the CLI, and uninstall.
# Sourced by install.sh; uses ROOT, PROFILE, DRY_RUN and the helpers.

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tfem"
INSTALL_LOG="$STATE_DIR/install.log"
BIN_DIR="$HOME/.local/bin"
CLI_NAMES=(tfem dots wm)
DEFAULT_WALLPAPER="forest/wallhaven-oggp1m.jpg"

# Appends a line to the install log, read back by --uninstall.
record() {
  ((DRY_RUN)) && return 0
  mkdir -p "$STATE_DIR"
  printf '%s\n' "$*" >>"$INSTALL_LOG"
}

# Every path the installer writes; existing ones are copied first.
managed_paths() {
  printf '%s\n' "$CONFIG_HOME/hypr" "$CONFIG_HOME/tfem"
  local name
  for name in "${CLI_NAMES[@]}"; do printf '%s\n' "$BIN_DIR/$name"; done
}

backup_existing() {
  local backup path
  backup="$STATE_DIR/backups/install-$(date +%Y%m%d-%H%M%S)"
  while read -r path; do
    [[ -e $path || -L $path ]] || continue
    run mkdir -p "$backup$(dirname "$path")"
    run cp -a "$path" "$backup$path"
  done < <(managed_paths)
  record "backup $backup"
  info "backup of your current files: $backup"
}

deploy_hypr() {
  [[ -e $CONFIG_HOME/hypr ]] || record "created $CONFIG_HOME/hypr"
  run mkdir -p "$CONFIG_HOME/hypr"
  run cp -r "$ROOT/hypr/." "$CONFIG_HOME/hypr/"
  info "Hyprland config copied to $CONFIG_HOME/hypr"
}

# Links the CLI and its neutral aliases; never replaces someone else's command.
link_cli() {
  run mkdir -p "$BIN_DIR"
  local name target
  for name in "${CLI_NAMES[@]}"; do
    target="$BIN_DIR/$name"
    if [[ -e $target && "$(readlink -f "$target")" != "$ROOT/tfem" ]]; then
      warn "$target already exists and is not ours: left untouched"
      continue
    fi
    run ln -sfn "$ROOT/tfem" "$target"
    record "link $target"
  done
  case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) warn "add $BIN_DIR to your PATH to use the tfem command and the screenshot keys" ;;
  esac
}

# First install with wallpapers: start from a forest wallpaper.
seed_settings() {
  local file="$CONFIG_HOME/tfem/theme.toml"
  [[ -e $file ]] && return 0
  ((WITH_WALLPAPERS)) || return 0
  run mkdir -p "$CONFIG_HOME/tfem"
  if ((DRY_RUN)); then
    printf '   [dry-run] write %s\n' "$file"
  else
    printf '# Your settings: only the keys written here replace the defaults.\n\n[wallpaper]\npath = "%s"\n' \
      "$DEFAULT_WALLPAPER" >"$file"
  fi
}

uninstall() {
  [[ -r $INSTALL_LOG ]] || die "nothing to uninstall: $INSTALL_LOG not found"
  # The first backup holds the files as they were before the first install.
  local backup path line
  backup="$(awk '$1 == "backup" { print $2; exit }' "$INSTALL_LOG")"
  while read -r line; do
    path="${line#link }"
    [[ $line == link\ * && -L $path ]] && run rm -f "$path"
  done <"$INSTALL_LOG"
  if [[ -n $backup && -e $backup$CONFIG_HOME/hypr ]]; then
    run rm -rf "$CONFIG_HOME/hypr"
    run cp -a "$backup$CONFIG_HOME/hypr" "$CONFIG_HOME/hypr"
    info "your previous Hyprland config is back"
  elif grep -qx "created $CONFIG_HOME/hypr" "$INSTALL_LOG"; then
    run rm -rf "$CONFIG_HOME/hypr"
  fi
  run mv "$INSTALL_LOG" "$INSTALL_LOG.uninstalled-$(date +%Y%m%d-%H%M%S)"
  info "kept: your settings ($CONFIG_HOME/tfem), wallpapers, backups and installed packages"
  if grep -qx "cloned $ROOT" "$INSTALL_LOG"* 2>/dev/null; then
    info "remove the downloaded project with: rm -rf $ROOT"
  fi
}
