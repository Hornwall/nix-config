import QtQuick
import Quickshell
import Quickshell.Io

// Live agent sessions (claude, codex, pi) reported by their hooks via `agent-run hook`.
Scope {
    id: root

    property var sessions: []
    property int waitingCount: sessions.filter(session => session.status === "waiting").length

    function focus(session) {
        Quickshell.execDetached(["agent-run", "focus", session.id]);
    }

    Process {
        id: watchProcess
        command: ["agent-run", "sessions", "--watch"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.sessions = JSON.parse(data);
                } catch (exception) {
                    root.sessions = [];
                }
            }
        }

        onExited: (exitCode, exitStatus) => restartTimer.start()
    }

    // Restart the watcher if agent-run exits, e.g. after a home-manager switch.
    Timer {
        id: restartTimer
        interval: 5000
        onTriggered: watchProcess.running = true
    }
}
