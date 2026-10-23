import QtQuick
import Quickshell

// Starts `agent-run <action> <url>` (agent-run picks the agent and opens it in tmux), or any other command.
Rectangle {
    id: root

    property string action: ""
    property string url: ""
    property var command: ["agent-run", action, url]
    required property string icon
    required property string hint
    property bool hovered: mouse.containsMouse
    // Red, e.g. while a destructive action waits for a second click.
    property bool danger: false
    // A keyboard shortcut shown as a badge in the corner.
    property string key: ""

    signal triggered

    width: 26
    height: 26
    radius: 8
    color: danger ? "#2ef38ba8" : hovered ? "#2e68b5ab" : "transparent"
    border.width: 1
    border.color: danger ? "#73f38ba8" : hovered ? "#7368b5ab" : "#12ffffff"

    Text {
        anchors.centerIn: parent
        text: root.icon
        color: root.danger ? "#f38ba8" : root.hovered ? "#68b5ab" : "#8b949e"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 14
    }

    Rectangle {
        visible: root.key !== ""
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: -4
        width: 13
        height: 13
        radius: 4
        color: "#68b5ab"

        Text {
            anchors.centerIn: parent
            text: root.key
            color: "#1e1f22"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 9
            font.weight: Font.Bold
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.command.length > 0)
                Quickshell.execDetached(root.command);
            root.triggered();
        }
    }
}
