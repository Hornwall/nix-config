import QtQuick
import Quickshell.Io

// Today's agent activity and the checkouts agents left behind, with a button to prune them.
Rectangle {
    id: root

    // Stats are read whenever this turns true, i.e. when the overlay opens.
    property bool active: false
    property var stats: null
    // What the last prune did, shown in place of the stats for a while.
    property string pruneResult: ""
    // aboard workspaces whose PR is done; pruning again within a few seconds removes them.
    property var doneWorkspaces: []

    function refresh() {
        if (!statsProcess.running)
            statsProcess.running = true;
    }

    function prune() {
        if (pruneProcess.running)
            return;
        pruneProcess.command = doneWorkspaces.length > 0
            ? ["agent-run", "prune", "--workspaces"].concat(doneWorkspaces) : ["agent-run", "prune"];
        pruneResult = "";
        doneWorkspaces = [];
        pruneProcess.running = true;
    }

    function plural(count, word) {
        return count + " " + word + (count === 1 ? "" : "s");
    }

    function summary() {
        if (pruneProcess.running)
            return "Pruning worktrees…";
        if (pruneResult !== "")
            return pruneResult;
        if (!stats)
            return "";
        const parts = [
            "󰚩 " + stats.sessions + (stats.sessions === 1 ? " session" : " sessions") + " today",
            "󰊤 " + stats.triaged + " triaged · $" + stats.cost.toFixed(2),
            "󰙅 " + stats.worktrees + (stats.worktrees === 1 ? " worktree" : " worktrees")
                + " · " + stats.workspaces + " aboard"
        ];
        return parts.join("   ");
    }

    onActiveChanged: if (active) {
        pruneResult = "";
        doneWorkspaces = [];
        refresh();
    }

    width: row.implicitWidth + 28
    height: 26
    radius: 13
    color: "#e61e1f22"
    border.width: 1
    border.color: "#18ffffff"
    visible: summaryText.text !== ""

    Process {
        id: statsProcess
        command: ["agent-run", "stats"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.stats = JSON.parse(text);
                } catch (exception) {
                    root.stats = null;
                }
            }
        }
    }

    Process {
        id: pruneProcess
        command: ["agent-run", "prune"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                const removed = lines.filter(line => line.startsWith("removed ") && !line.startsWith("removed workspace ")).length;
                const removedWorkspaces = lines.filter(line => line.startsWith("removed workspace ")).length;
                const skipped = lines.filter(line => line.startsWith("skip ")).length;
                // "workspace NAME (PR #N merged)"
                const done = lines.filter(line => line.startsWith("workspace ")).map(line => line.split(" ")[1]);
                const parts = [];
                if (removed > 0)
                    parts.push("Removed " + root.plural(removed, "worktree"));
                if (removedWorkspaces > 0)
                    parts.push("Removed " + root.plural(removedWorkspaces, "aboard workspace"));
                if (skipped > 0)
                    parts.push(skipped + " kept, see agent-run prune");
                if (done.length > 0)
                    parts.push((done.length === 1 ? done[0] + "'s PR is done" : done.length + " workspaces' PRs are done")
                        + ", p again removes " + (done.length === 1 ? "it" : "them") + " with databases");
                if (parts.length === 0)
                    parts.push("Nothing to prune, every checkout's PR is still open");
                if (lines.some(line => line.startsWith("Another prune")))
                    parts.splice(0, parts.length, "A prune is already running");
                root.pruneResult = parts.join("  ·  ");
                root.doneWorkspaces = done;
                if (done.length > 0)
                    disarmTimer.restart();
                root.refresh();
            }
        }
    }

    Timer {
        id: disarmTimer
        interval: 8000
        onTriggered: if (root.doneWorkspaces.length > 0) {
            root.doneWorkspaces = [];
            root.pruneResult = "";
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12

        Text {
            id: summaryText
            anchors.verticalCenter: parent.verticalCenter
            text: root.summary()
            color: "#8b949e"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !pruneProcess.running
            text: root.doneWorkspaces.length > 0 ? "p remove" : "p prune"
            color: root.doneWorkspaces.length > 0 ? (pruneMouse.containsMouse ? "#e06c75" : "#d1434c")
                : pruneMouse.containsMouse ? "#68b5ab" : "#5d8f89"
            font.family: "FiraCode Nerd Font"
            font.pixelSize: 11

            MouseArea {
                id: pruneMouse
                anchors.fill: parent
                anchors.margins: -4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.prune()
            }
        }
    }
}
