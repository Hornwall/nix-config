import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    required property Item anchorItem

    function launch(command) {
        visible = false;
        Quickshell.execDetached(command);
    }

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Left
        gravity: Edges.Bottom | Edges.Right
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 364
    implicitHeight: panel.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ScriptValue {
        id: stats
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/dashboard-stats.sh"]
        interval: 3000
        active: root.visible
    }

    Rectangle {
        id: panel
        implicitWidth: root.implicitWidth
        implicitHeight: content.implicitHeight + 24
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
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                text: clock.hours < 5 ? "Good night"
                    : clock.hours < 12 ? "Good morning"
                    : clock.hours < 18 ? "Good afternoon"
                    : "Good evening"
                color: "#ffffff"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 4
                text: Qt.locale("sv_SE").toString(clock.date, "dddd d MMMM  ·  HH:mm")
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
            }

            Heading { text: "QUICK LAUNCH" }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                columnSpacing: 6
                rowSpacing: 6

                Repeater {
                    model: [
                        { label: "󰈹  Firefox", command: ["firefox"] },
                        { label: "󰒱  Slack", command: ["slack"] },
                        { label: "󰓇  Spotify", command: ["spotify"] },
                        { label: "󰠮  Obsidian", command: ["obsidian"] },
                        { label: "  Terminal", command: ["ghostty"] },
                        { label: "󰀻  All apps", command: ["walker"] }
                    ]

                    PopupButton {
                        required property var modelData
                        Layout.fillWidth: true
                        text: modelData.label
                        accent: "#b7bcba"
                        onClicked: root.launch(modelData.command)
                    }
                }
            }

            Heading { text: "SYSTEM" }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                Layout.bottomMargin: 2
                text: stats.text.replace(/<[^>]*>/g, "")
                color: "#b7bcba"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
                lineHeight: 1.35
            }

            Heading { text: "POWER" }

            GridLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 4
                columns: 2
                columnSpacing: 6

                PopupButton {
                    Layout.fillWidth: true
                    text: "⏻ Shutdown"
                    accent: "#d1434c"
                    onClicked: root.launch(["systemctl", "poweroff"])
                }
                PopupButton {
                    Layout.fillWidth: true
                    text: "󰜉 Restart"
                    accent: "#fab387"
                    onClicked: root.launch(["systemctl", "reboot"])
                }
                PopupButton {
                    Layout.fillWidth: true
                    text: "󰍃 Logout"
                    accent: "#a6e3a1"
                    onClicked: root.launch(["hyprctl", "dispatch", "exit"])
                }
                PopupButton {
                    Layout.fillWidth: true
                    text: "󰒲 Sleep"
                    accent: "#89dceb"
                    onClicked: root.launch(["systemctl", "suspend"])
                }
            }
        }
    }

    component Heading: Text {
        Layout.fillWidth: true
        Layout.topMargin: 5
        text: ""
        color: "#9aa4ac"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1.4
    }
}
