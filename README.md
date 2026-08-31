# New Charter for Omarchy

A complete New Charter desktop theme and branding pack for Omarchy 4.

![New Charter desktop preview](theme/preview.png)

The selectable **New Charter** theme uses New Charter's warm paper, ink,
coral, sky-blue, pale-blue, and signal-yellow palette. The installer also
applies New Charter branding to user-visible surfaces that are independent of
the selected Omarchy style.

## What it installs

### Selectable theme

- Desktop and lock-screen wallpaper
- Terminal and application palette
- Omarchy shell colors
- Theme selector previews
- Yaru red icon theme

### Branding that persists across every style

- Screensaver wordmark
- About/fastfetch identity
- Omarchy menu labels
- Maintenance-terminal logo and `New Charter` window title
- Generated Claude and VS Code theme names
- Optional Plymouth boot/decryption and SDDM login branding
- Optional Limine bootloader banner

The installer never edits `/usr/share/omarchy`. System boot/login branding is
published through Omarchy's supported Plymouth command.

## Install

Clone the repository on an Omarchy machine and run the installer from a
terminal:

```bash
git clone git@github.com:danapsta/new-charter-omarchy.git
cd new-charter-omarchy
./install.sh
```

The default installation applies the desktop theme and then prompts for sudo
to publish the boot/login branding. Use a user-only installation when system
branding is not desired:

```bash
./install.sh --user-only
```

Available options:

```text
--user-only   Skip Plymouth, SDDM, and Limine
--no-activate Install files without selecting the New Charter theme
--help        Show installer help
```

Log out and back in once after the first install. This activates the
user-command path used to brand every maintenance terminal.

## Update

The installer is idempotent, so updates are simply:

```bash
git pull --ff-only
./install.sh
```

Each run stores recoverable snapshots under:

```text
~/.local/state/new-charter-omarchy/backups/
```

The original pre-install configuration is retained separately for uninstall.

## Uninstall

Restore the original user configuration:

```bash
./uninstall.sh
```

To also reset Plymouth/SDDM and restore the backed-up Limine banner:

```bash
./uninstall.sh --system
```

Current files are moved into an uninstall backup before restoration.

## Rebuilding artwork

The committed PNG assets are ready to install. To regenerate them from the
source SVG artwork:

```bash
./scripts/build-assets
```

This requires `rsvg-convert` and ImageMagick.

## Brand source

Design cues and the official wordmark are derived from
[newchartertech.com](https://www.newchartertech.com/). New Charter names,
logos, and brand assets remain the property of New Charter.
