import QtQuick

Rectangle {
    id: root

    property bool shown: false
    signal closeRequested()

    radius: 14
    color: "#f51e1f22"
    border.width: 1
    border.color: "#14ffffff"
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.97
    transformOrigin: Item.TopRight

    Behavior on opacity {
        NumberAnimation {
            duration: 140
            easing.type: Easing.OutCubic
        }
    }

    Behavior on scale {
        NumberAnimation {
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    Shortcut {
        enabled: root.shown
        sequence: "Escape"
        context: Qt.WindowShortcut
        onActivated: root.closeRequested()
    }
}
