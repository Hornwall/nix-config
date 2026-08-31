import QtQuick

Rectangle {
    id: root

    property alias text: label.text
    property color accent: "#68b5ab"
    signal clicked()

    implicitWidth: 100
    implicitHeight: 42
    radius: 11
    color: mouseArea.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.14) : "#092a2b2f"
    border.width: 1
    border.color: mouseArea.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.5) : "#0dffffff"

    Text {
        id: label
        anchors.centerIn: parent
        color: root.accent
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 13
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
