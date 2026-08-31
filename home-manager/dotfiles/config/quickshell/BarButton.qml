import QtQuick

Rectangle {
    id: root

    property alias text: label.text
    property color textColor: "#68b5ab"
    property color hoverColor: "#2168b5ab"
    property int horizontalPadding: 8
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: 32
    radius: 9
    color: mouseArea.containsMouse ? hoverColor : "transparent"

    Text {
        id: label
        anchors.centerIn: parent
        color: root.textColor
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 14
        elide: Text.ElideRight
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }
}
