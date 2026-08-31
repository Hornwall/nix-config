import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

PopupWindow {
    id: root

    required property Item anchorItem

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 190
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
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "POWER PROFILE"
                color: "#7d858d"
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
                onClicked: {
                    PowerProfiles.profile = PowerProfile.Performance;
                    root.visible = false;
                }
            }
            PopupButton {
                Layout.fillWidth: true
                text: "󰾅  Balanced"
                accent: PowerProfiles.profile === PowerProfile.Balanced ? "#68b5ab" : "#b7bcba"
                onClicked: {
                    PowerProfiles.profile = PowerProfile.Balanced;
                    root.visible = false;
                }
            }
            PopupButton {
                Layout.fillWidth: true
                text: "󰌪  Power saver"
                accent: PowerProfiles.profile === PowerProfile.PowerSaver ? "#68b5ab" : "#b7bcba"
                onClicked: {
                    PowerProfiles.profile = PowerProfile.PowerSaver;
                    root.visible = false;
                }
            }
        }
    }
}
