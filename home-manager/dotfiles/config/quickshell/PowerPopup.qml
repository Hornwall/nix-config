import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

PopupWindow {
    id: root

    required property Item anchorItem
    property var battery: UPower.displayDevice

    function formatDuration(seconds) {
        if (!seconds || seconds <= 0)
            return "Calculating…";
        const hours = Math.floor(seconds / 3600);
        const minutes = Math.floor((seconds % 3600) / 60);
        return (hours > 0 ? hours + "h " : "") + minutes + "m";
    }

    function stateLabel() {
        switch (battery.state) {
        case UPowerDeviceState.Charging: return "Charging";
        case UPowerDeviceState.Discharging: return "On battery";
        case UPowerDeviceState.Empty: return "Empty";
        case UPowerDeviceState.FullyCharged: return "Fully charged";
        case UPowerDeviceState.PendingCharge: return "Waiting to charge";
        case UPowerDeviceState.PendingDischarge: return "Waiting to discharge";
        default: return "Unknown";
        }
    }

    function timeLabel() {
        if (battery.state === UPowerDeviceState.Charging)
            return formatDuration(battery.timeToFull) + " until full";
        if (battery.state === UPowerDeviceState.Discharging)
            return formatDuration(battery.timeToEmpty) + " remaining";
        return stateLabel();
    }

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 310
    implicitHeight: content.implicitHeight + 24

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#f51e1f22"
        border.width: 1
        border.color: "#14ffffff"

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 7

            Text {
                Layout.fillWidth: true
                text: "BATTERY"
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1.2
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: battery.state === UPowerDeviceState.Charging ? "󰂄" : "󰁹"
                    color: "#68b5ab"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 30
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: Math.round(battery.percentage * 100) + "%"
                        color: "#ffffff"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 22
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.timeLabel()
                        color: "#b7bcba"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 11
                    }
                }
            }

            ProgressBar {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: battery.percentage
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 4

                DetailLabel { text: "Status" }
                DetailValue { text: root.stateLabel() }

                DetailLabel { text: "Power" }
                DetailValue {
                    text: battery.changeRate !== 0
                        ? Math.abs(battery.changeRate).toFixed(1) + " W" : "--"
                }

                DetailLabel {
                    visible: battery.healthSupported
                    text: "Health"
                }
                DetailValue {
                    visible: battery.healthSupported
                    text: Math.round(battery.healthPercentage) + "%"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                implicitHeight: 1
                color: "#14ffffff"
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 3
                text: "POWER PROFILE"
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1.2
            }

            PopupButton {
                Layout.fillWidth: true
                visible: PowerProfiles.hasPerformanceProfile
                text: "󰓅  Performance"
                accent: PowerProfiles.profile === PowerProfile.Performance ? "#68b5ab" : "#b7bcba"
                onClicked: PowerProfiles.profile = PowerProfile.Performance
            }

            PopupButton {
                Layout.fillWidth: true
                text: "󰾅  Balanced"
                accent: PowerProfiles.profile === PowerProfile.Balanced ? "#68b5ab" : "#b7bcba"
                onClicked: PowerProfiles.profile = PowerProfile.Balanced
            }

            PopupButton {
                Layout.fillWidth: true
                text: "󰌪  Power saver"
                accent: PowerProfiles.profile === PowerProfile.PowerSaver ? "#68b5ab" : "#b7bcba"
                onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
            }
        }
    }

    component DetailLabel: Text {
        Layout.fillWidth: true
        color: "#9aa4ac"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 10
    }

    component DetailValue: Text {
        Layout.alignment: Qt.AlignRight
        color: "#ffffff"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 10
    }
}
