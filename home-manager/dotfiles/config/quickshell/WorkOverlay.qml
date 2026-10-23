import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Agents and pull requests on top of everything, toggled with `qs ipc call work toggle`.
// Taking an action, Escape, or clicking the backdrop hides it. Everything can be driven from the
// keyboard; the footer lists the keys.
PanelWindow {
    id: root

    required property var shell
    required property var modelData
    property var monitor: Hyprland.monitorFor(screen)
    // The keyboard selection: a list ("agents", "reviews" or "mine") and a row in it.
    property string section: "agents"
    property int row: 0
    // The open pull request tab, returned to when moving down from the agents.
    property string column: "reviews"

    function widget(name) {
        return name === "agents" ? agentSessions : name === "reviews" ? pullRequests.reviews : pullRequests.mine;
    }

    function count(name) {
        return name === "agents" ? agentSessions.sessionCount : widget(name).pullRequestCount;
    }

    // An empty list is skipped unless force is set, as when switching tabs.
    function select(name, index, force) {
        if (count(name) === 0 && !force)
            return false;
        section = name;
        row = Math.max(0, Math.min(index, count(name) - 1));
        if (name !== "agents")
            column = name;
        return true;
    }

    function move(delta) {
        if (row + delta >= 0 && row + delta < count(section))
            row += delta;
        else if (delta > 0 && section === "agents")
            select(column, 0) || select(column === "reviews" ? "mine" : "reviews", 0);
        else if (delta < 0 && section !== "agents")
            select("agents", count("agents") - 1);
    }

    function cycle() {
        const order = ["agents", "reviews", "mine"];
        for (let step = 1; step <= order.length; step++) {
            if (select(order[(order.indexOf(section) + step) % order.length], 0))
                return;
        }
    }

    function handleKey(event) {
        const current = widget(section);
        // Lists can shrink while the overlay is open.
        row = Math.min(row, Math.max(0, count(section) - 1));
        switch (event.key) {
        case Qt.Key_J:
        case Qt.Key_Down:
            move(1);
            break;
        case Qt.Key_K:
        case Qt.Key_Up:
            move(-1);
            break;
        case Qt.Key_H:
        case Qt.Key_Left:
            select("reviews", 0, true);
            break;
        case Qt.Key_L:
        case Qt.Key_Right:
            select("mine", 0, true);
            break;
        case Qt.Key_Tab:
            cycle();
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_O:
            current.open(row);
            break;
        case Qt.Key_Escape:
            shell.workOverlayOpen = false;
            break;
        default:
            if (section === "agents" && event.key === Qt.Key_R)
                current.reply(row);
            else if (section === "agents" && event.key === Qt.Key_X)
                current.stop(row);
            else if (section === "agents" && (event.key === Qt.Key_A || event.key === Qt.Key_D))
                current.answer(row, event.key === Qt.Key_A);
            else if (section !== "agents" && event.key >= Qt.Key_1 && event.key <= Qt.Key_9)
                current.runAction(row, event.key - Qt.Key_1);
            else
                return;
        }
        event.accepted = true;
    }

    // Start at the top of the first list with anything in it.
    onVisibleChanged: if (visible) {
        select("agents", 0) || select("reviews", 0) || select("mine", 0);
        content.forceActiveFocus();
    }

    screen: modelData
    visible: shell.workOverlayOpen && Hyprland.focusedMonitor === monitor
    color: "#a6000000"
    exclusiveZone: -1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.namespace: "quickshell-work-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    MouseArea {
        anchors.fill: parent
        onClicked: root.shell.workOverlayOpen = false
    }

    Item {
        id: content
        anchors.centerIn: parent
        width: Math.min(1136, root.width - 48)
        height: Math.min(root.height - 96, agentSessions.implicitHeight + (agentSessions.visible ? 16 : 0)
            + pullRequests.implicitHeight)
        focus: true
        Keys.onPressed: event => root.handleKey(event)

        // Clicks between the widgets should not reach the backdrop.
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            AgentSessionsWidget {
                id: agentSessions
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                shell: root.shell
                selected: root.section === "agents" ? root.row : -1
            }

            PullRequestsWidget {
                id: pullRequests
                Layout.fillWidth: true
                Layout.fillHeight: true
                shell: root.shell
                tab: root.column
                selected: root.section === "agents" ? -1 : root.row
                onTabClicked: name => {
                    root.select(name, 0, true);
                    content.forceActiveFocus();
                }
            }
        }
    }

    Rectangle {
        anchors.top: content.bottom
        anchors.topMargin: 12
        anchors.horizontalCenter: content.horizontalCenter
        width: keyHints.implicitWidth + 28
        height: 26
        radius: 13
        color: "#e61e1f22"
        border.width: 1
        border.color: "#18ffffff"

        Text {
            id: keyHints
            anchors.centerIn: parent
            text: "j/k move  ·  h/l switch tab  ·  tab next list  ·  ⏎ open  ·  "
                + (root.section === "agents" ? "r reply  ·  x x stop  ·  a/d allow/deny" : "1–9 agent actions")
                + "  ·  esc close"
            color: "#8b949e"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
        }
    }
}
