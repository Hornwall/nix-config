import QtQuick
import QtQuick.Layouts
import Quickshell

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
    implicitWidth: 280
    implicitHeight: content.implicitHeight + 28

    ScriptValue {
        id: forecast
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/weather-forecast.sh"]
        interval: 1800000
        active: root.visible
    }

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
            anchors.margins: 14
            spacing: 8

            Text {
                text: "STOCKHOLM"
                color: "#7d858d"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 1.2
            }

            Text {
                Layout.fillWidth: true
                text: forecast.text.replace(/<[^>]*>/g, "")
                color: "#ffffff"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
                lineHeight: 1.2
            }
        }
    }
}
