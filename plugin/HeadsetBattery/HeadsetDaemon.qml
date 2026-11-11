import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Widgets
import "headset.js" as Headset

// Single background instance: polls HeadsetControl, publishes the result to all
// bar widget instances through a plugin global var, and sends low-battery notifications.
PluginComponent {
    id: root

    property var popoutService: null

    readonly property int pollSeconds: Math.max(10, Number(pluginData.pollInterval ?? 30))
    readonly property bool notificationsEnabled: pluginData.notificationsEnabled ?? true
    readonly property int warnAt: Number(pluginData.warnThreshold ?? 20)
    readonly property int urgentAt: Number(pluginData.urgentThreshold ?? 10)

    // Persisted across shell restarts so the bar can show the last known level
    // and so we don't re-send a notification we already sent.
    property int lastLevel: -1
    property int notifyTier: 0

    PluginGlobalVar {
        id: sharedState
        varName: "state"
        defaultValue: ({ kind: "unknown", level: -1, lastLevel: -1, device: "" })
    }

    Component.onCompleted: {
        lastLevel = pluginService?.loadPluginState(pluginId, "lastLevel", -1) ?? -1;
        notifyTier = pluginService?.loadPluginState(pluginId, "notifyTier", 0) ?? 0;
        sharedState.set({ kind: "unknown", level: -1, lastLevel: lastLevel, device: "" });
    }

    Timer {
        interval: root.pollSeconds * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!poller.running)
                poller.running = true;
        }
    }

    Process {
        id: poller
        command: ["headsetcontrol", "-b", "-o", "json"]
        stdout: StdioCollector {
            id: out
        }
        onExited: (exitCode, exitStatus) => root.handleResult(out.text, exitCode)
    }

    function handleResult(text, exitCode) {
        let state = (text && text.trim()) ? Headset.parseHeadsetControl(text) : { kind: "error", level: -1, device: "" };
        if (state.kind === "error")
            console.warn("headsetBattery: could not read headsetcontrol output (exit " + exitCode + ")");

        if (state.level >= 0 && state.level !== lastLevel) {
            lastLevel = state.level;
            pluginService?.savePluginState(pluginId, "lastLevel", lastLevel);
        }

        sharedState.set({ kind: state.kind, level: state.level, lastLevel: lastLevel, device: state.device });

        const step = Headset.lowBatteryStep(notifyTier, state, warnAt, urgentAt);
        if (step.tier !== notifyTier) {
            notifyTier = step.tier;
            pluginService?.savePluginState(pluginId, "notifyTier", notifyTier);
        }
        if (step.notify && notificationsEnabled)
            sendNotification(step.notify, state);
    }

    function sendNotification(kind, state) {
        const urgent = kind === "urgent";
        const name = state.device || "Headset";
        Quickshell.execDetached([
            "notify-send",
            "--app-name=Headset Battery",
            "--icon=audio-headset",
            "--urgency=" + (urgent ? "critical" : "normal"),
            urgent ? "Headset battery critically low" : "Headset battery low",
            name + ": " + state.level + "% remaining"
        ]);
    }
}
