// Pure helpers shared by the daemon and the bar widget.
// Kept free of QML APIs so they can be unit-tested with Node (see tests/).

// Turn `headsetcontrol -b -o json` output into a small state object:
//   { kind, level, device }
// kind:  "online"   headset connected, level known
//        "charging" headset reports charging (level may be -1)
//        "offline"  dongle present but headset off / out of range
//        "nodevice" no supported headset found
//        "error"    output could not be understood
// level: 0-100, or -1 when unknown
function parseHeadsetControl(stdout) {
    let doc;
    try {
        doc = JSON.parse(stdout);
    } catch (e) {
        return { kind: "error", level: -1, device: "" };
    }

    const devices = (doc && Array.isArray(doc.devices)) ? doc.devices : [];
    // First device that reported battery info, falling back to the first device at all.
    const dev = devices.find(d => d && d.battery) || devices[0];
    if (!dev)
        return { kind: "nodevice", level: -1, device: "" };

    const device = dev.device || dev.product || "Headset";
    const bat = dev.battery;
    if (!bat)
        return { kind: "offline", level: -1, device: device };

    const level = (Number.isInteger(bat.level) && bat.level >= 0 && bat.level <= 100) ? bat.level : -1;

    switch (bat.status) {
    case "BATTERY_AVAILABLE":
        return level >= 0 ? { kind: "online", level: level, device: device }
                          : { kind: "offline", level: -1, device: device };
    case "BATTERY_CHARGING":
        return { kind: "charging", level: level, device: device };
    default: // BATTERY_UNAVAILABLE, BATTERY_ERROR, BATTERY_TIMEOUT, ...
        return { kind: "offline", level: -1, device: device };
    }
}

// Low-battery notification state machine.
// tier: 0 = nothing sent, 1 = warning sent, 2 = urgent sent.
// Returns { tier, notify } where notify is "", "warn" or "urgent".
// Resets when the headset charges, or climbs comfortably above the warning threshold.
const RESET_MARGIN = 5;

function lowBatteryStep(tier, state, warnAt, urgentAt) {
    urgentAt = Math.min(urgentAt, warnAt);

    if (state.kind === "charging")
        return { tier: 0, notify: "" };
    if (state.kind !== "online")
        return { tier: tier, notify: "" };
    if (state.level > warnAt + RESET_MARGIN)
        return { tier: 0, notify: "" };
    if (state.level <= urgentAt)
        return tier < 2 ? { tier: 2, notify: "urgent" } : { tier: tier, notify: "" };
    if (state.level <= warnAt)
        return tier < 1 ? { tier: 1, notify: "warn" } : { tier: tier, notify: "" };
    return { tier: tier, notify: "" };
}
