#!/bin/bash
#
# SuperClaw — macOS one-line installer (public build)
# --------------------------------------------------------------------------
# Downloads the AES-256 encrypted SuperClaw disk image from GitHub Releases,
# mounts it with the distribution password you supply, installs SuperClaw.app,
# and clears the Gatekeeper quarantine flag so the (unsigned / ad-hoc-signed)
# app opens without the "damaged / unidentified developer" warning.
#
# The password is NOT stored in this repo — you must pass it, so the public
# encrypted image is useless to anyone who does not have the password.
#
# Usage:
#   curl -fsSL <URL-to-this-script> | bash -s -- '<password>'
#   # or:  SUPERCLAW_PASSWORD='<password>' curl ... | bash
#
# Optional:
#   SUPERCLAW_DMG_URL   override the download URL of the encrypted .dmg
# --------------------------------------------------------------------------
set -euo pipefail

DMG_URL="${SUPERCLAW_DMG_URL:-https://github.com/GauravDC27/superclaw-mac/releases/download/v1.1.0/SuperClaw-1.1.0.dmg}"
DMG_PASSWORD="${1:-${SUPERCLAW_PASSWORD:-}}"
APP_NAME="SuperClaw.app"

log() { printf '\033[1;35m→\033[0m %s\n' "$*"; }
ok()  { printf '\033[1;32m✓ %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

[ "$(uname)" = "Darwin" ] || die "The SuperClaw installer runs on macOS only."
[ -n "$DMG_PASSWORD" ] || die "Password required. Run:  curl -fsSL <url> | bash -s -- '<password>'"

TMP="$(mktemp -d)"; MNT="$TMP/mnt"; DMG="$TMP/SuperClaw.dmg"
cleanup(){ hdiutil detach "$MNT" >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT

log "Downloading SuperClaw…"
curl -fL --progress-bar "$DMG_URL" -o "$DMG" || die "Download failed from $DMG_URL"

log "Mounting encrypted image…"
mkdir -p "$MNT"
printf '%s' "$DMG_PASSWORD" | hdiutil attach -stdinpass -nobrowse -readonly -mountpoint "$MNT" "$DMG" >/dev/null \
  || die "Could not mount image (wrong password or corrupt download)."
[ -d "$MNT/$APP_NAME" ] || die "$APP_NAME not found inside the disk image."

# Quit any running instance so we can replace it.
# (pkill, not osascript: never reads stdin and triggers no GUI/automation prompt.)
pkill -f '/SuperClaw\.app/Contents/MacOS/SuperClaw' 2>/dev/null || true
sleep 1

# Pick an install location that works for this user:
#   1. /Applications if writable (typical admin Mac)
#   2. in-place replace of an existing /Applications/SuperClaw.app we own
#      (managed/non-admin Macs where /Applications itself isn't writable)
#   3. ~/Applications as a no-admin fallback
install_to() {
  local dir="$1" dest="$1/$APP_NAME"
  if [ -w "$dir" ]; then
    rm -rf "$dest" && cp -R "$MNT/$APP_NAME" "$dir/" && { INSTALLED="$dest"; return 0; }
  elif [ -d "$dest" ] && [ -O "$dest" ]; then
    rm -rf "$dest"/* "$dest"/.[!.]* 2>/dev/null || true
    cp -R "$MNT/$APP_NAME/." "$dest/" && { INSTALLED="$dest"; return 0; }
  fi
  return 1
}

log "Installing $APP_NAME…"
INSTALLED=""
install_to "/Applications" \
  || { mkdir -p "$HOME/Applications" && install_to "$HOME/Applications"; } \
  || die "Could not install to /Applications or ~/Applications."

log "Clearing Gatekeeper quarantine…"
xattr -dr com.apple.quarantine "$INSTALLED" 2>/dev/null || true

ok "SuperClaw installed to $INSTALLED"
log "Launching…"
open "$INSTALLED" || true
