import QtQuick
import QtQuick.Layouts
import Quickshell

// Running agent sessions; agents waiting on you are listed first. Click a row to jump to it.
Rectangle {
    id: root

    required property var shell
    property var sessions: shell.agentSessions.sessions
    property int sessionCount: sessions.length
    property int bodyHeight: Math.min(sessionCount, 4) * 54 - 6

    function statusColor(status) {
        if (status === "waiting")
            return "#f9e2af";
        if (status === "working")
            return "#68b5ab";
        if (status === "done")
            return "#a6e3a1";
        return "#7d8690";
    }

    function statusLabel(status) {
        if (status === "waiting")
            return "needs you";
        if (status === "working")
            return "working";
        if (status === "done")
            return "done";
        return "idle";
    }

    function agentIcon(agent) {
        if (agent === "claude")
            return "󰚩";
        if (agent === "codex")
            return "󰘦";
        return "󰆍";
    }

    function relativeTime(seconds) {
        const age = Math.max(0, Math.floor(Date.now() / 1000 - seconds));
        if (age < 60)
            return "just now";
        if (age < 3600)
            return Math.floor(age / 60) + "m ago";
        if (age < 86400)
            return Math.floor(age / 3600) + "h ago";
        return Math.floor(age / 86400) + "d ago";
    }

    visible: sessionCount > 0
    implicitHeight: visible ? bodyHeight + 91 : 0
    radius: 16
    color: "#e61e1f22"
    border.width: 1
    border.color: "#18ffffff"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: 10

            Text {
                text: "󱙺"
                color: "#b4befe"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 21
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Agents"
                    color: "#ffffff"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Text {
                    text: (root.sessionCount === 1 ? "1 session" : root.sessionCount + " sessions")
                        + (root.shell.agentSessions.waitingCount > 0
                            ? "  ·  " + root.shell.agentSessions.waitingCount + " need you" : "")
                    color: root.shell.agentSessions.waitingCount > 0 ? "#f9e2af" : "#8b949e"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#12ffffff"
        }

        ListView {
            id: sessionList
            Layout.fillWidth: true
            Layout.preferredHeight: root.bodyHeight
            clip: true
            spacing: 6
            model: root.sessions

            delegate: Rectangle {
                id: session

                required property var modelData
                width: sessionList.width
                height: 48
                radius: 11
                color: sessionMouse.containsMouse ? "#1f68b5ab" : "#092a2b2f"
                border.width: 1
                border.color: sessionMouse.containsMouse ? "#5568b5ab"
                    : session.modelData.status === "waiting" ? "#40f9e2af" : "#0dffffff"

                Rectangle {
                    id: dot
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 8
                    radius: 4
                    color: root.statusColor(session.modelData.status)

                    SequentialAnimation on opacity {
                        running: session.modelData.status === "working"
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) dot.opacity = 1
                        NumberAnimation { to: 0.3; duration: 700 }
                        NumberAnimation { to: 1; duration: 700 }
                    }
                }

                Column {
                    anchors.left: dot.right
                    anchors.right: status.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 3

                    Text {
                        width: parent.width
                        text: root.agentIcon(session.modelData.agent) + "  " + session.modelData.title
                        color: "#f2f2f2"
                        elide: Text.ElideRight
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 13
                    }

                    Text {
                        width: parent.width
                        text: session.modelData.message !== "" ? session.modelData.message
                            : session.modelData.agent + "  ·  " + session.modelData.cwd
                        color: session.modelData.status === "waiting" ? "#f9e2af" : "#7d8690"
                        elide: Text.ElideRight
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 10
                    }
                }

                Text {
                    id: status
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.statusLabel(session.modelData.status) + "  ·  "
                        + root.relativeTime(session.modelData.updated)
                    color: root.statusColor(session.modelData.status)
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.shell.agentSessions.focus(session.modelData);
                        root.shell.workOverlayOpen = false;
                    }
                }
            }
        }
    }
}
