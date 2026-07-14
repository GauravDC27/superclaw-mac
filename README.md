# SuperClaw for macOS

One-line installer for the SuperClaw macOS app.

SuperClaw is not yet notarized by Apple, so downloading the `.dmg` in a browser and
double-clicking triggers Gatekeeper ("damaged" / "unidentified developer"). Installing
via the command line below avoids that — `curl` does not set the `com.apple.quarantine`
flag, and the installer clears it explicitly.

The disk image is **AES-256 encrypted**, so it cannot be opened without the password.
The password is **not** stored in this repo — you supply it in the install command.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/GauravDC27/superclaw-mac/main/install-superclaw.sh | bash -s -- '<password>'
```

That downloads the encrypted image, mounts it with your password, installs
**SuperClaw.app** (into `/Applications`, falling back to `~/Applications` on managed
Macs), clears the quarantine flag, and launches it.

## Manual install

1. Download `SuperClaw-1.1.0.dmg` from the [latest release](../../releases/latest).
2. Double-click to mount, and enter the password when prompted.
3. Drag **SuperClaw.app** into Applications.
4. First launch: right-click the app → **Open**, or run
   `xattr -dr com.apple.quarantine /Applications/SuperClaw.app`.

## Build

Universal build (Apple Silicon + Intel), v1.1.0.
