import QtQuick
import Quickshell.Io

Item {
    id: root

    property var command: []
    property int interval: 0
    property bool active: true
    property string text: ""

    function refresh() {
        if (active && !process.running && command.length > 0)
            process.running = true;
    }

    visible: false
    implicitWidth: 0
    implicitHeight: 0

    Process {
        id: process
        command: root.command
        stdout: StdioCollector {
            onStreamFinished: root.text = this.text.trim()
        }
    }

    Timer {
        interval: root.interval
        repeat: true
        running: root.active && root.interval > 0
        onTriggered: root.refresh()
    }

    onActiveChanged: refresh()
    Component.onCompleted: refresh()
}
