import QtQuick
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    pluginId: "headsetBattery"

    SliderSetting {
        settingKey: "pollInterval"
        label: "Poll interval"
        description: "How often HeadsetControl is queried. Shorter means connect/disconnect shows up faster."
        defaultValue: 30
        minimum: 10
        maximum: 300
        unit: "s"
    }

    ToggleSetting {
        settingKey: "notificationsEnabled"
        label: "Low-battery notifications"
        description: "Send a desktop notification when the headset battery runs low"
        defaultValue: true
    }

    SliderSetting {
        settingKey: "warnThreshold"
        label: "Warning threshold"
        description: "Send a heads-up notification at or below this level"
        defaultValue: 20
        minimum: 5
        maximum: 50
        unit: "%"
    }

    SliderSetting {
        settingKey: "urgentThreshold"
        label: "Urgent threshold"
        description: "Send an urgent notification at or below this level (also turns the bar text red)"
        defaultValue: 10
        minimum: 1
        maximum: 30
        unit: "%"
    }
}
