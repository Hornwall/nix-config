import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: root

    required property var notification
    property bool compact: false

    implicitHeight: content.implicitHeight + 18
    radius: 12
    color: "#2a2b2f"
    border.width: 1
    border.color: notification && notification.urgency === NotificationUrgency.Critical
        ? "#80d1434c" : "#0dffffff"

    RowLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 9
        spacing: 9

        Item {
            property string iconSource: {
                if (!root.notification)
                    return "";
                if (root.notification.image)
                    return root.notification.image;
                return root.notification.appIcon
                    ? Quickshell.iconPath(root.notification.appIcon, true) : "";
            }

            Layout.alignment: Qt.AlignTop
            implicitWidth: root.compact ? 30 : 38
            implicitHeight: implicitWidth

            Text {
                anchors.centerIn: parent
                visible: parent.iconSource === ""
                text: "󰂚"
                color: "#68b5ab"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: root.compact ? 20 : 24
            }

            IconImage {
                anchors.fill: parent
                visible: parent.iconSource !== ""
                source: parent.iconSource
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: root.notification ? root.notification.appName : ""
                    color: "#9aa4ac"
                    elide: Text.ElideRight
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                PopupButton {
                    implicitWidth: 28
                    implicitHeight: 26
                    text: "󰅖"
                    accent: "#9aa4ac"
                    onClicked: root.notification.dismiss()
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.notification ? root.notification.summary : ""
                color: "#ffffff"
                wrapMode: Text.Wrap
                font.family: "FiraCode Nerd Font"
                font.pixelSize: root.compact ? 12 : 13
                font.weight: Font.DemiBold
            }

            Text {
                visible: root.notification && root.notification.body !== ""
                Layout.fillWidth: true
                text: root.notification ? root.notification.body : ""
                textFormat: Text.PlainText
                color: "#b7bcba"
                wrapMode: Text.Wrap
                maximumLineCount: root.compact ? 3 : 8
                elide: Text.ElideRight
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
            }

            RowLayout {
                visible: root.notification && root.notification.actions.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 3

                Repeater {
                    model: root.notification ? root.notification.actions : []

                    PopupButton {
                        required property NotificationAction modelData
                        implicitHeight: 30
                        text: modelData.text
                        onClicked: modelData.invoke()
                    }
                }
            }
        }
    }
}
