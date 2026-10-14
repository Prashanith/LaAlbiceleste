#!/usr/bin/env bash
# =============================================================================
#  LaAlbiceleste GRUB Theme — Install Script
#  Usage:
#    sudo ./install.sh              Install the theme
#    sudo ./install.sh --uninstall  Remove the theme and restore backup
#    sudo ./install.sh --dry-run    Preview actions without making changes
# =============================================================================

set -euo pipefail

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

# ── Config ────────────────────────────────────────────────────────────────────
THEME_NAME="la_albiceleste"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_SRC="${SCRIPT_DIR}/${THEME_NAME}"
GRUB_THEMES_DIR="/boot/grub/themes"
GRUB_THEMES_DIR2="/boot/grub2/themes"   # Fedora / openSUSE path
GRUB_DEFAULT_CFG="/etc/default/grub"
THEME_DEST=""   # resolved below
DRY_RUN=false
UNINSTALL=false

# ── Argument parsing ──────────────────────────────────────────────────────────
for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    --uninstall) UNINSTALL=true ;;
    --help|-h)
      echo "Usage: sudo $0 [--dry-run] [--uninstall]"
      exit 0 ;;
    *) die "Unknown option: $arg" ;;
  esac
done

run() {
  # Wrapper: prints the command and optionally skips it in dry-run mode
  if $DRY_RUN; then
    echo -e "  ${YELLOW}[DRY-RUN]${RESET} $*"
  else
    eval "$@"
  fi
}

# ── Helpers ───────────────────────────────────────────────────────────────────
banner() {
  echo ""
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${CYAN}║   LaAlbiceleste — GRUB Theme Installer   ║${RESET}"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${RESET}"
  echo ""
}

check_root() {
  if [[ "$EUID" -ne 0 ]]; then
    die "This script must be run as root. Try:  sudo $0"
  fi
}

check_source() {
  if [[ ! -d "$THEME_SRC" ]]; then
    die "Theme source not found at: ${THEME_SRC}\nRun this script from the repository root."
  fi
  if [[ ! -f "${THEME_SRC}/theme.txt" ]]; then
    die "theme.txt not found inside ${THEME_SRC}."
  fi
}

detect_grub_dir() {
  if [[ -d "$GRUB_THEMES_DIR" ]]; then
    THEME_DEST="${GRUB_THEMES_DIR}/${THEME_NAME}"
  elif [[ -d "$GRUB_THEMES_DIR2" ]]; then
    THEME_DEST="${GRUB_THEMES_DIR2}/${THEME_NAME}"
    GRUB_THEMES_DIR="$GRUB_THEMES_DIR2"
  else
    # Neither exists — create the standard one
    warn "GRUB themes directory not found. It will be created at ${GRUB_THEMES_DIR}."
    THEME_DEST="${GRUB_THEMES_DIR}/${THEME_NAME}"
  fi
  info "GRUB themes directory : ${GRUB_THEMES_DIR}"
  info "Theme install target  : ${THEME_DEST}"
}

detect_update_cmd() {
  # Returns the correct grub update command for this distro
  if command -v update-grub &>/dev/null; then
    echo "update-grub"
  elif command -v grub-mkconfig &>/dev/null; then
    local out="/boot/grub/grub.cfg"
    [[ -f /boot/grub2/grub.cfg ]] && out="/boot/grub2/grub.cfg"
    echo "grub-mkconfig -o ${out}"
  elif command -v grub2-mkconfig &>/dev/null; then
    local out="/boot/grub2/grub.cfg"
    [[ -f /boot/efi/EFI/fedora/grub.cfg ]] && out="/boot/efi/EFI/fedora/grub.cfg"
    echo "grub2-mkconfig -o ${out}"
  else
    echo ""
  fi
}

# ── Install ───────────────────────────────────────────────────────────────────
do_install() {
  info "Starting installation..."

  # 1. Create themes directory if needed
  if [[ ! -d "$GRUB_THEMES_DIR" ]]; then
    info "Creating ${GRUB_THEMES_DIR}"
    run "mkdir -p '${GRUB_THEMES_DIR}'"
  fi

  # 2. Remove old installation if present
  if [[ -d "$THEME_DEST" ]]; then
    warn "Existing theme found at ${THEME_DEST} — removing it first."
    run "rm -rf '${THEME_DEST}'"
  fi

  # 3. Copy theme
  info "Copying theme files to ${THEME_DEST}"
  run "cp -r '${THEME_SRC}' '${THEME_DEST}'"
  success "Theme files copied."

  # 4. Backup grub config
  local backup="${GRUB_DEFAULT_CFG}.bak.$(date +%Y%m%d_%H%M%S)"
  info "Backing up ${GRUB_DEFAULT_CFG} → ${backup}"
  run "cp '${GRUB_DEFAULT_CFG}' '${backup}'"
  success "Backup saved: ${backup}"

  # 5. Set GRUB_THEME in /etc/default/grub
  local theme_path="${THEME_DEST}/theme.txt"
  if grep -q "^GRUB_THEME=" "$GRUB_DEFAULT_CFG" 2>/dev/null; then
    info "Updating existing GRUB_THEME entry..."
    run "sed -i 's|^GRUB_THEME=.*|GRUB_THEME=\"${theme_path}\"|' '${GRUB_DEFAULT_CFG}'"
  elif grep -q "^#GRUB_THEME=" "$GRUB_DEFAULT_CFG" 2>/dev/null; then
    info "Uncommenting and setting GRUB_THEME entry..."
    run "sed -i 's|^#GRUB_THEME=.*|GRUB_THEME=\"${theme_path}\"|' '${GRUB_DEFAULT_CFG}'"
  else
    info "Appending GRUB_THEME entry..."
    run "echo 'GRUB_THEME=\"${theme_path}\"' >> '${GRUB_DEFAULT_CFG}'"
  fi
  success "GRUB_THEME set to: ${theme_path}"

  # 6. Regenerate GRUB config
  local update_cmd
  update_cmd="$(detect_update_cmd)"
  if [[ -z "$update_cmd" ]]; then
    warn "Could not detect grub update command (update-grub / grub-mkconfig)."
    warn "Please run your distro's GRUB update command manually."
  else
    info "Regenerating GRUB config with: ${update_cmd}"
    run "$update_cmd"
    success "GRUB config regenerated."
  fi

  echo ""
  echo -e "${GREEN}${BOLD}✔  Installation complete!${RESET}"
  echo -e "   Reboot to see the LaAlbiceleste theme in action."
  echo ""
}

# ── Uninstall ─────────────────────────────────────────────────────────────────
do_uninstall() {
  info "Starting uninstall..."

  # 1. Remove theme directory
  if [[ -d "$THEME_DEST" ]]; then
    info "Removing ${THEME_DEST}"
    run "rm -rf '${THEME_DEST}'"
    success "Theme directory removed."
  else
    warn "Theme not found at ${THEME_DEST} — nothing to remove."
  fi

  # 2. Remove GRUB_THEME from /etc/default/grub
  if grep -q "^GRUB_THEME=" "$GRUB_DEFAULT_CFG" 2>/dev/null; then
    local backup="${GRUB_DEFAULT_CFG}.bak.$(date +%Y%m%d_%H%M%S)"
    info "Backing up ${GRUB_DEFAULT_CFG} → ${backup}"
    run "cp '${GRUB_DEFAULT_CFG}' '${backup}'"
    info "Removing GRUB_THEME line from ${GRUB_DEFAULT_CFG}"
    run "sed -i '/^GRUB_THEME=/d' '${GRUB_DEFAULT_CFG}'"
    success "GRUB_THEME removed from config."
  else
    warn "No GRUB_THEME entry found in ${GRUB_DEFAULT_CFG}."
  fi

  # 3. Regenerate GRUB config
  local update_cmd
  update_cmd="$(detect_update_cmd)"
  if [[ -n "$update_cmd" ]]; then
    info "Regenerating GRUB config with: ${update_cmd}"
    run "$update_cmd"
    success "GRUB config regenerated."
  else
    warn "Please run your distro's GRUB update command manually."
  fi

  echo ""
  echo -e "${GREEN}${BOLD}✔  Uninstall complete.${RESET}"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
banner
check_root
check_source
detect_grub_dir

if $DRY_RUN; then
  warn "Dry-run mode — no changes will be made.\n"
fi

if $UNINSTALL; then
  do_uninstall
else
  do_install
fi
