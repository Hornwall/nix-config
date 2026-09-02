import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var pullRequests: []
    property bool loading: false
    property string error: ""
    property var lastUpdated: null

    function refresh() {
        if (fetchProcess.running)
            return;

        loading = true;
        fetchProcess.running = true;
    }

    Process {
        id: fetchProcess
        command: [Quickshell.shellPath("scripts/github-pull-requests.sh")]

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output === "")
                    return;

                try {
                    const result = JSON.parse(output);
                    root.pullRequests = result.pullRequests || [];
                    root.error = result.error || "";
                    root.lastUpdated = new Date();
                } catch (exception) {
                    root.error = "Invalid response from GitHub";
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0)
                root.error = "Could not load your GitHub pull requests";
        }
    }

    Timer {
        interval: 300000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
