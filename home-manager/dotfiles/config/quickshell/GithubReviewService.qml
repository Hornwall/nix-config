import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var pullRequests: []
    property bool loading: false
    property string error: ""
    property var lastUpdated: null
    // Background triage by `agent-run triage`, keyed by PR url.
    property var triage: ({})

    function refresh() {
        if (fetchProcess.running)
            return;

        loading = true;
        fetchProcess.running = true;
    }

    Process {
        id: fetchProcess
        command: [Quickshell.shellPath("scripts/github-review-requests.sh")]

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
                    root.startTriage();
                } catch (exception) {
                    root.error = "Invalid response from GitHub";
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0)
                root.error = "Could not load GitHub review requests";
        }
    }

    function startTriage() {
        const urls = pullRequests.filter(pullRequest => !pullRequest.isDraft)
            .map(pullRequest => pullRequest.url);
        if (urls.length > 0)
            Quickshell.execDetached(["agent-run", "triage"].concat(urls));
    }

    Process {
        id: triageProcess
        command: ["agent-run", "triage", "--watch"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                try {
                    root.triage = JSON.parse(data);
                } catch (exception) {}
            }
        }

        onExited: (exitCode, exitStatus) => triageRestartTimer.start()
    }

    Timer {
        id: triageRestartTimer
        interval: 5000
        onTriggered: triageProcess.running = true
    }

    Timer {
        interval: 300000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
