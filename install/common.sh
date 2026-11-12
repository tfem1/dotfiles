# shellcheck shell=bash
# Shared helpers for install.sh: messages, dry-run aware commands, prompts,
# distro detection. Sourced, never run directly.

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[1;31mxx\033[0m %s\n' "$*" >&2
  exit 1
}

# Runs a command, or only prints it with --dry-run.
run() {
  if ((DRY_RUN)); then
    printf '   [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Asks a yes/no question on the terminal (works with `curl | bash` too).
confirm() {
  ((ASSUME_YES || DRY_RUN)) && return 0
  local answer=""
  [[ -r /dev/tty ]] || die "no terminal to confirm; re-run with --yes"
  read -r -p "$1 [y/N] " answer </dev/tty || true
  [[ $answer == [yY]* ]]
}

# Prints arch, debian, fedora or yvis from /etc/os-release (ID, then
# ID_LIKE), or openbsd (which has no os-release).
detect_family() {
  if [[ "${TFEM_UNAME:-$(uname -s)}" == OpenBSD ]]; then
    echo openbsd
    return
  fi
  local file="${TFEM_OS_RELEASE:-/etc/os-release}" id="" like=""
  [[ -r $file ]] || die "cannot read $file"
  # shellcheck source=/dev/null
  id="$(. "$file" && printf '%s' "${ID:-}")"
  # shellcheck source=/dev/null
  like="$(. "$file" && printf '%s' "${ID_LIKE:-}")"
  local word
  for word in $id $like; do
    case "$word" in
      arch | archlinux) echo arch && return ;;
      debian | ubuntu) echo debian && return ;;
      fedora) echo fedora && return ;;
      yvis) echo yvis && return ;;
    esac
  done
  die "unsupported distribution '$id' (supported: Arch, Debian, Fedora, YVIS and their derivatives; OpenBSD in part)"
}
