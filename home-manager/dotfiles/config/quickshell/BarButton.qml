import QtQuick

Rectangle {
    id: root

    property alias text: label.text
    property color textColor: "#68b5ab"
    property color hoverColor: "#2168b5ab"
    property int horizontalPadding: 8
    signal clicked(var mouse)
    signal wheel(var wheel)

    activeFocusOnTab: enabled
    implicitWidth: label.implicitWidth + horizontalPadding * 2
    implicitHeight: 32
    radius: 9
    opacity: enabled ? 1 : 0.4
    color: mouseArea.containsMouse || activeFocus ? hoverColor : "transparent"

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

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
        enabled: root.enabled
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.forceActiveFocus()
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }

    Keys.onReturnPressed: event => {
        root.clicked({button: Qt.LeftButton});
        event.accepted = true;
    }
    Keys.onEnterPressed: event => {
        root.clicked({button: Qt.LeftButton});
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.clicked({button: Qt.LeftButton});
        event.accepted = true;
    }
}
