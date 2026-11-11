# dms-headset-battery

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS) bar widget that shows the battery level and connection state of your wireless headset, using [HeadsetControl](https://github.com/Sapd/HeadsetControl).

**Tested with:** Logitech G PRO X 2 LIGHTSPEED (`046d:0af7`), HeadsetControl 4.2.0. It should work with any headset for which HeadsetControl supports battery status ([device list](https://github.com/Sapd/HeadsetControl#supported-headsets)).

## What it shows

| State | Bar |
|---|---|
| Connected | 🎧 `87%` |
| Charging | 🎧 `64%` ⚡ |
| Off / out of range | dimmed icon, last known level, greyed out |
| At or below urgent threshold | text turns red |
| No headset / HeadsetControl error | dimmed `headset_off` icon in red with `!` (if no level was ever seen) |

Low-battery desktop notifications are sent once when the level drops to the **warning** (default 20%) threshold and once more at the **urgent** (default 10%) threshold. They reset once the headset charges.

## Install

### Arch Linux (package)

```sh
git clone https://github.com/arthurb123/dms-headset-battery
cd dms-headset-battery/pkg/aur/dms-headset-battery-git   # builds the latest commit
makepkg -si
```

This installs the plugin system-wide into `/etc/xdg/quickshell/dms-plugins/HeadsetBattery` and pulls in `headsetcontrol` and `libnotify`. After a tagged release, `pkg/aur/dms-headset-battery` builds that release instead.

### Any distro (per user)

Install `headsetcontrol` (and `notify-send` for notifications), then:

```sh
git clone https://github.com/arthurb123/dms-headset-battery
cd dms-headset-battery
./install.sh            # symlinks into ~/.config/dms/plugins (use --copy to copy)
```

`./install.sh --uninstall` removes it. Don't combine the per-user install with the package.

### Enable it

1. DMS Settings → Plugins → enable **Headset Battery** (use "Scan for Plugins" if it isn't listed).
2. Add the **Headset Battery** widget to a bar section.
3. Optionally tune the poll interval (default 30 s), thresholds and notifications on the plugin's settings page.

## Permissions

HeadsetControl talks to the headset over `/dev/hidraw*`. On most desktops the logged-in user gets access automatically via `uaccess`. If `headsetcontrol -b` reports a permission error, install HeadsetControl's udev rules (`headsetcontrol -u > /etc/udev/rules.d/70-headsets.rules` as root, then `udevadm control --reload && udevadm trigger`).

## How it works

The plugin is a DMS *composite* plugin:

- **`HeadsetDaemon.qml`** runs once, calls `headsetcontrol -b -o json` every poll interval, publishes the parsed state to all bar instances through a plugin global variable, remembers the last known level across restarts, and sends notifications.
- **`HeadsetWidget.qml`** is the bar pill (one per bar/monitor); it only renders the shared state.
- **`headset.js`** holds the parsing and notification logic. It has no QML dependencies and is unit-tested:

```sh
node --test tests/*.test.mjs
```

## License

MIT
