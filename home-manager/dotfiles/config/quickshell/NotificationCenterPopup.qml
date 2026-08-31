import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

PopupWindow {
    id: root

    required property Item anchorItem
    required property var shell
    property var notifications: shell.notificationServer.trackedNotifications.values

    function clearAll() {
        const current = [...notifications];
        for (const notification of current)
            notification.dismiss();
    }

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 430
    implicitHeight: 560

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#f51e1f22"
        border.width: 1
        border.color: "#14ffffff"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "NOTIFICATIONS"
                    color: "#9aa4ac"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                }

                PopupButton {
                    implicitWidth: 74
                    implicitHeight: 30
                    text: root.shell.doNotDisturb ? "󰂛  DND" : "󰂚  DND"
                    accent: root.shell.doNotDisturb ? "#ab78ad" : "#9aa4ac"
                    onClicked: root.shell.doNotDisturb = !root.shell.doNotDisturb
                }

                PopupButton {
                    visible: root.notifications.length > 0
                    implicitWidth: 68
                    implicitHeight: 30
                    text: "Clear"
                    accent: "#d1434c"
                    onClicked: root.clearAll()
                }
            }

            Text {
                visible: root.notifications.length === 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                Layout.fillHeight: true
                text: "󰂚\nAll caught up"
                horizontalAlignment: Text.AlignHCenter
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 14
                lineHeight: 1.5
            }

            ScrollView {
                visible: root.notifications.length > 0
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: ScriptModel { values: [...root.notifications].reverse() }

                        NotificationCard {
                            required property Notification modelData
                            Layout.fillWidth: true
                            notification: modelData
                        }
                    }
                }
            }
        }
    }
}
