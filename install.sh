#!/usr/bin/env bash
# One-command installer for the Arch, Debian and Fedora families:
#   bash <(curl -fsSL https://raw.githubusercontent.com/tfem1/dotfiles/main/install.sh)
# Downloads the project, installs the packages, backs up then deploys the
# configs, downloads the wallpapers and the icons and generates the theme.
# See --help.
set -euo pipefail

REPO_URL="${TFEM_REPO_URL:-https://github.com/tfem1/dotfiles.git}"
BRANCH="${TFEM_BRANCH:-main}"
DEST="${TFEM_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/tfem}"
PROFILE=full DRY_RUN=0 ASSUME_YES=0 UNINSTALL=0 WITH_PACKAGES=1 WITH_WALLPAPERS=1 WITH_ICONS=1 SDDM_THEME=stacked-clock

usage() {
  cat <<'EOF'
Usage: install.sh [options]

  --profile minimal|full  minimal: desktop essentials only, no wallpapers
                          full (default): apps, fonts, icons and wallpapers
  --dry-run               show every step, change nothing
  --uninstall             restore your previous config and remove the links
  --yes                   do not ask for confirmation
  --no-packages           skip package installation
  --no-wallpapers         skip the wallpaper download
  --no-icons              skip the FairyWren icons download
  --sddm NAME             the login screen to install: stacked-clock (default)
                          or welcome-panel (SDDM, asks for sudo)
  --no-sddm               do not install SDDM nor its login screen
  --branch NAME           install another branch of the project
  -h, --help              show this help
EOF
}

ARGS=("$@")
while (($#)); do
  case "$1" in
    --profile)
      [[ ${2:-} == minimal || ${2:-} == full ]] || { usage >&2; exit 64; }
      PROFILE="$2" && shift
      ;;
    --dry-run) DRY_RUN=1 ;;
    --uninstall) UNINSTALL=1 ;;
    --yes) ASSUME_YES=1 ;;
    --no-packages) WITH_PACKAGES=0 ;;
    --no-wallpapers) WITH_WALLPAPERS=0 ;;
    --no-icons) WITH_ICONS=0 ;;
    --sddm)
      [[ ${2:-} == stacked-clock || ${2:-} == welcome-panel ]] || { usage >&2; exit 64; }
      SDDM_THEME="$2" && shift
      ;;
    --no-sddm) SDDM_THEME="" ;;
    --branch) BRANCH="${2:?--branch needs a name}" && shift ;;
    -h | --help) usage && exit 0 ;;
    *) usage >&2 && exit 64 ;;
  esac
  shift
done
[[ $PROFILE == minimal ]] && WITH_WALLPAPERS=0

# Started from a download (curl): fetch the project, then run its installer.
ROOT=""
if source_dir="$(dirname "${BASH_SOURCE[0]:-.}")" && [[ -d $source_dir ]]; then
  ROOT="$(cd "$source_dir" && pwd)"
fi
if [[ ! -f $ROOT/install/common.sh ]]; then
  command -v git >/dev/null 2>&1 || { echo "error: git is needed to download the project" >&2; exit 1; }
  ((DRY_RUN)) && DEST="$(mktemp -d)/tfem"
  if [[ -d $DEST/.git ]]; then
    git -C "$DEST" pull --ff-only
  else
    git clone --depth 1 --branch "$BRANCH" "$REPO_URL" "$DEST"
    export TFEM_CLONED=1
  fi
  exec bash "$DEST/install.sh" "${ARGS[@]}"
fi

# shellcheck source=install/common.sh
. "$ROOT/install/common.sh"
# shellcheck source=install/packages.sh
. "$ROOT/install/packages.sh"
# shellcheck source=install/deploy.sh
. "$ROOT/install/deploy.sh"

if ((UNINSTALL)); then
  uninstall
  exit 0
fi

FAMILY="$(detect_family)"
info "distro family: $FAMILY, profile: $PROFILE$( ((DRY_RUN)) && echo ', dry run: nothing changes')"
info "project: $ROOT"
info "will write: $CONFIG_HOME/hypr, $SHELL_DIR, $CONFIG_HOME/tfem, links in $BIN_DIR (existing files are backed up first)"
((WITH_WALLPAPERS)) && info "will download the 51 wallpapers of the collection to ${XDG_PICTURES_DIR:-$HOME/Pictures}/Wallpapers"
[[ -n $SDDM_THEME ]] && info "will install SDDM and the '$SDDM_THEME' login screen (--no-sddm to skip)"
confirm "Continue?" || die "cancelled"

[[ ${TFEM_CLONED:-0} == 1 ]] && record "cloned $ROOT"
((WITH_PACKAGES)) && install_packages
check_hyprland
backup_existing
deploy_hypr
deploy_shell
link_cli

if ((WITH_WALLPAPERS)); then
  info "downloading wallpapers"
  run "$ROOT/tfem" wallpapers fetch || warn "some wallpapers could not be downloaded; run 'tfem wallpapers fetch' later"
fi
if ((WITH_ICONS)); then
  info "downloading the FairyWren icons"
  run "$ROOT/tfem" icons fetch || warn "the icons could not be downloaded; run 'tfem icons fetch' later"
fi
seed_settings

info "generating the theme files"
run "$ROOT/tfem" generate

# The login screen, in the theme's colors; SDDM is turned on unless another
# login manager is in use (that one is left as is).
if [[ -n $SDDM_THEME ]]; then
  info "installing the '$SDDM_THEME' login screen"
  run "$ROOT/tfem" sddm install "$SDDM_THEME" --enable ||
    warn "the login screen was not installed; run 'tfem sddm install $SDDM_THEME --enable' later"
fi

info "done. Restart, then choose Hyprland at the login screen (or run 'start-hyprland' from a TTY)."
info "change the look in ~/.config/tfem/theme.toml, then run 'tfem generate'"
