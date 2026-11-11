import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Widgets

// Bar pill: headset icon + percentage. Purely a view over the state the daemon publishes.
PluginComponent {
    id: root

    property var popoutService: null

    PluginGlobalVar {
        id: sharedState
        varName: "state"
        defaultValue: ({ kind: "unknown", level: -1, lastLevel: -1, device: "" })
    }

    readonly property var st: sharedState.value
    readonly property bool connected: st.kind === "online" || st.kind === "charging"
    readonly property bool charging: st.kind === "charging"
    readonly property bool problem: st.kind === "error" || st.kind === "nodevice"
    // Live level when we have one, otherwise the last known level (shown dimmed).
    readonly property int shownLevel: st.level >= 0 ? st.level : st.lastLevel
    readonly property bool levelIsLive: st.level >= 0
    readonly property int urgentAt: Number(pluginData.urgentThreshold ?? 10)
    readonly property bool low: levelIsLive && !charging && shownLevel <= urgentAt

    readonly property string iconName: problem ? "headset_off" : (connected ? "headphones" : "headset_off")
    readonly property color fgColor: problem ? Theme.error : (low ? Theme.error : Theme.surfaceText)
    readonly property real fgOpacity: (connected && levelIsLive) ? 1.0 : 0.5
    readonly property string levelText: shownLevel >= 0 ? String(shownLevel) : (problem ? "!" : "–")

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS
            opacity: root.fgOpacity

            DIcon {
                anchors.verticalCenter: parent.verticalCenter
                name: root.iconName
                size: root.iconSize
                color: root.fgColor
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.levelText + (root.shownLevel >= 0 ? "%" : "")
                font.pixelSize: root.textSize
                color: root.fgColor
            }

            DIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.charging
                name: "bolt"
                size: root.iconSize * 0.7
                color: root.fgColor
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS
            opacity: root.fgOpacity

            DIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: root.charging ? "bolt" : root.iconName
                size: root.iconSize
                color: root.fgColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.levelText
                font.pixelSize: root.textSize
                color: root.fgColor
            }
        }
    }
}
