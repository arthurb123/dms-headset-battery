#!/usr/bin/env bash
# Per-user install of the Headset Battery DMS plugin (for when you don't use the Arch package).
#   ./install.sh            symlink plugin into ~/.config/dms/plugins (updates via git pull)
#   ./install.sh --copy     copy instead of symlink
#   ./install.sh --uninstall
set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/plugin/HeadsetBattery"
dest_dir="${XDG_CONFIG_HOME:-$HOME/.config}/dms/plugins"
dest="$dest_dir/HeadsetBattery"
system_dir="/etc/xdg/quickshell/dms-plugins/HeadsetBattery"

rescan() {
    if command -v dms >/dev/null 2>&1; then
        dms ipc plugin-scan scan >/dev/null 2>&1 || true
    fi
}

case "${1:-}" in
--uninstall)
    rm -rf "$dest"
    rescan
    echo "Removed $dest"
    exit 0
    ;;
--copy | "") ;;
*)
    echo "usage: $0 [--copy | --uninstall]" >&2
    exit 2
    ;;
esac

if [[ -d "$system_dir" ]]; then
    echo "warning: a system-wide copy exists at $system_dir (Arch package)." >&2
    echo "         Remove the package or skip this per-user install to avoid duplicates." >&2
fi

if ! command -v headsetcontrol >/dev/null 2>&1; then
    echo "warning: headsetcontrol not found in PATH; the plugin will refuse to start until it is installed." >&2
fi
if ! command -v notify-send >/dev/null 2>&1; then
    echo "warning: notify-send (libnotify) not found; low-battery notifications will not be shown." >&2
fi

mkdir -p "$dest_dir"
rm -rf "$dest"
if [[ "${1:-}" == "--copy" ]]; then
    cp -r "$src" "$dest"
    echo "Copied plugin to $dest"
else
    ln -s "$src" "$dest"
    echo "Linked $dest -> $src"
fi

rescan
echo "Now enable 'Headset Battery' in DMS Settings > Plugins and add it to a bar section."
