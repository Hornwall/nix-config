import QtQuick
import QtQuick.Layouts
import Quickshell

// Running agent sessions; agents waiting on you are listed first. Click a row to jump to it, or reply
// and answer permission prompts from here.
Rectangle {
    id: root

    required property var shell
    property var sessions: shell.agentSessions.sessions
    property int sessionCount: sessions.length
    // The session being replied to, and the draft; kept here because rows are re-created on every update.
    property string replyingTo: ""
    property string replyText: ""
    // The session whose stop button was clicked once; a second click stops it.
    property string stoppingId: ""
    property int bodyHeight: Math.min(sessionCount, 4) * 54 - 6
        + (sessions.some(session => session.id === replyingTo) ? 40 : 0)
    // The row picked with the keyboard, or -1.
    property int selected: -1

    onSelectedChanged: if (selected >= 0)
        sessionList.positionViewAtIndex(selected, ListView.Contain)

    function open(index) {
        if (index < 0 || index >= sessionCount)
            return;
        shell.agentSessions.focus(sessions[index]);
        shell.workOverlayOpen = false;
    }

    function reply(index) {
        const session = sessions[index];
        if (!session || session.status === "waiting")
            return;
        replyText = "";
        replyingTo = replyingTo === session.id ? "" : session.id;
    }

    // The first call arms the stop; a second within three seconds stops the agent.
    function stop(index) {
        const session = sessions[index];
        if (!session)
            return;
        if (stoppingId === session.id) {
            Quickshell.execDetached(["agent-run", "kill", session.id]);
            stoppingId = "";
        } else {
            stoppingId = session.id;
            stopTimer.restart();
        }
    }

    function overseer() {
        Quickshell.execDetached(["agent-run", "overseer"]);
        shell.workOverlayOpen = false;
    }

    function answer(index, allow) {
        const session = sessions[index];
        if (session && session.status === "waiting" && session.waiting_for === "permission")
            Quickshell.execDetached(["agent-run", allow ? "approve" : "deny", session.id]);
    }

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

    Timer {
        id: stopTimer
        interval: 3000
        onTriggered: root.stoppingId = ""
    }
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

            AgentActionButton {
                icon: "󰚩"
                hint: "Overseer: a claude that watches and steers these agents (v)"
                command: []
                onTriggered: root.overseer()
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
                required property int index
                property bool highlighted: sessionMouse.containsMouse || root.selected === index
                property bool replying: root.replyingTo === modelData.id
                property bool askingPermission: modelData.status === "waiting" && modelData.waiting_for === "permission"
                width: sessionList.width
                height: replying ? 88 : 48
                radius: 11
                color: highlighted ? "#1f68b5ab" : "#092a2b2f"
                border.width: 1
                border.color: highlighted ? "#5568b5ab"
                    : session.modelData.status === "waiting" ? "#40f9e2af" : "#0dffffff"

                Item {
                    id: header
                    width: parent.width
                    height: 48

                    MouseArea {
                        id: sessionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.open(session.index)
                    }

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
                            text: session.modelData.paused ? "Agent events paused"
                                : session.modelData.suggestion ? "󰚩 overseer: " + session.modelData.suggestion
                                : session.modelData.ask ? session.modelData.ask
                                : session.modelData.message !== "" ? session.modelData.message
                                : session.modelData.agent + "  ·  " + session.modelData.cwd
                            color: session.modelData.suggestion ? "#b4befe"
                                : session.modelData.status === "waiting" ? "#f9e2af" : "#7d8690"
                            elide: Text.ElideRight
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 10
                        }
                    }

                    Row {
                        id: actions
                        anchors.right: parent.right
                        anchors.rightMargin: 11
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        AgentActionButton {
                            visible: session.askingPermission
                            icon: "󰄬"
                            hint: "Allow"
                            command: []
                            onTriggered: root.answer(session.index, true)
                        }

                        AgentActionButton {
                            visible: session.askingPermission
                            icon: "󰅖"
                            hint: "Deny"
                            command: []
                            onTriggered: root.answer(session.index, false)
                        }

                        AgentActionButton {
                            visible: session.modelData.role === "overseer"
                            icon: session.modelData.paused ? "󰐊" : "󰏤"
                            hint: session.modelData.paused ? "Resume sending agent events to the overseer"
                                : "Pause agent events to the overseer"
                            command: ["agent-run", "overseer", session.modelData.paused ? "resume" : "pause"]
                        }

                        AgentActionButton {
                            visible: session.modelData.status !== "waiting"
                            icon: "󰍩"
                            hint: "Reply"
                            command: []
                            onTriggered: root.reply(session.index)
                        }

                        AgentActionButton {
                            property bool armed: root.stoppingId === session.modelData.id
                            icon: armed ? "󰅙" : "󰓛"
                            hint: armed ? "Click again to stop" : "Stop"
                            danger: armed
                            command: []
                            onTriggered: root.stop(session.index)
                        }
                    }

                    Text {
                        id: status
                        anchors.right: actions.left
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.statusLabel(session.modelData.status) + "  ·  "
                            + root.relativeTime(session.modelData.updated)
                        color: root.statusColor(session.modelData.status)
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 10
                    }
                }

                Rectangle {
                    visible: session.replying
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: header.bottom
                    anchors.margins: 8
                    anchors.topMargin: 0
                    height: 32
                    radius: 8
                    color: "#14ffffff"
                    border.width: 1
                    border.color: replyInput.activeFocus ? "#7368b5ab" : "#12ffffff"

                    TextInput {
                        id: replyInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        clip: true
                        color: "#f2f2f2"
                        selectionColor: "#7368b5ab"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 12
                        // Kept on the widget so a session update re-creating this row keeps the draft.
                        text: root.replyText
                        onTextEdited: root.replyText = text
                        visible: session.replying
                        onVisibleChanged: if (visible) forceActiveFocus()
                        Component.onCompleted: if (visible) forceActiveFocus()

                        function send() {
                            if (text.trim() !== "")
                                Quickshell.execDetached(["agent-run", "reply", session.modelData.id, text]);
                            root.replyingTo = "";
                            root.replyText = "";
                            root.shell.workOverlayOpen = false;
                        }

                        Keys.onReturnPressed: send()
                        Keys.onEnterPressed: send()
                        Keys.onEscapePressed: {
                            root.replyingTo = "";
                            root.forceActiveFocus();
                        }

                        Text {
                            visible: replyInput.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Reply to " + session.modelData.agent + "…  (Enter sends, Esc cancels)"
                            color: "#5d6670"
                            font: replyInput.font
                        }
                    }
                }
            }
        }
    }
}
