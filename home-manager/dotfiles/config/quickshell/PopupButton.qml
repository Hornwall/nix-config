import QtQuick

Rectangle {
    id: root

    property alias text: label.text
    property color accent: "#68b5ab"
    signal clicked()

    activeFocusOnTab: enabled
    implicitWidth: 100
    implicitHeight: 42
    radius: 11
    opacity: enabled ? 1 : 0.4
    color: mouseArea.containsMouse || activeFocus
        ? Qt.rgba(accent.r, accent.g, accent.b, 0.14) : "#092a2b2f"
    border.width: activeFocus ? 2 : 1
    border.color: mouseArea.containsMouse || activeFocus
        ? Qt.rgba(accent.r, accent.g, accent.b, 0.65) : "#0dffffff"

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Behavior on opacity {
        NumberAnimation { duration: 120 }
    }

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
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.forceActiveFocus()
        onClicked: root.clicked()
    }

    Keys.onReturnPressed: event => {
        root.clicked();
        event.accepted = true;
    }
    Keys.onEnterPressed: event => {
        root.clicked();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        root.clicked();
        event.accepted = true;
    }
}
