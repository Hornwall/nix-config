import QtQuick
import Quickshell

// Starts `agent-run <action> <url>`; agent-run picks the agent and opens it in tmux.
Rectangle {
    id: root

    required property string action
    required property string url
    required property string icon
    required property string hint
    property bool hovered: mouse.containsMouse

    signal triggered

    width: 26
    height: 26
    radius: 8
    color: hovered ? "#2e68b5ab" : "transparent"
    border.width: 1
    border.color: hovered ? "#7368b5ab" : "#12ffffff"

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.hovered ? "#68b5ab" : "#8b949e"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 14
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["agent-run", root.action, root.url]);
            root.triggered();
        }
    }
}
