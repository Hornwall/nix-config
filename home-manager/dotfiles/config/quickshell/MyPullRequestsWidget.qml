import QtQuick
import Quickshell

// One tab of PullRequestsWidget.
Item {
    id: root

    required property var shell
    property int pullRequestCount: shell.githubPullRequests.pullRequests.length
    property int bodyHeight: pullRequestCount > 0
        ? Math.min(pullRequestCount, 6) * 78 - 6 : 90
    // The row picked with the keyboard, or -1.
    property int selected: -1

    onSelectedChanged: if (selected >= 0)
        pullRequestList.positionViewAtIndex(selected, ListView.Contain)

    function open(index) {
        const pullRequest = shell.githubPullRequests.pullRequests[index];
        if (!pullRequest)
            return;
        Quickshell.execDetached(["xdg-open", pullRequest.url]);
        shell.workOverlayOpen = false;
    }

    // Runs the row's nth agent action, as numbered on its buttons.
    function runAction(index, number) {
        const pullRequest = shell.githubPullRequests.pullRequests[index];
        const action = pullRequest ? agentActions(pullRequest)[number] : undefined;
        if (!action)
            return;
        Quickshell.execDetached(["agent-run", action.action, pullRequest.url]);
        shell.workOverlayOpen = false;
    }

    function relativeTime(value) {
        const seconds = Math.max(0, Math.floor((Date.now() - new Date(value).getTime()) / 1000));
        if (seconds < 60)
            return "just now";
        if (seconds < 3600)
            return Math.floor(seconds / 60) + "m ago";
        if (seconds < 86400)
            return Math.floor(seconds / 3600) + "h ago";
        return Math.floor(seconds / 86400) + "d ago";
    }

    function reviewLabel(pullRequest) {
        if (pullRequest.isDraft)
            return "Draft";
        if (pullRequest.reviewDecision === "APPROVED")
            return "Approved";
        if (pullRequest.reviewDecision === "CHANGES_REQUESTED")
            return "Changes requested";
        if (pullRequest.reviewDecision === "REVIEW_REQUIRED")
            return "Awaiting review";
        return "Ready";
    }

    function checkLabel(pullRequest) {
        if (pullRequest.checkStatus === "SUCCESS")
            return "checks passing";
        if (pullRequest.checkStatus === "FAILURE" || pullRequest.checkStatus === "ERROR")
            return "checks failing";
        if (pullRequest.checkStatus === "PENDING" || pullRequest.checkStatus === "EXPECTED")
            return "checks pending";
        return "no checks";
    }

    function agentActions(pullRequest) {
        const actions = [];
        if (pullRequest.checkStatus === "FAILURE" || pullRequest.checkStatus === "ERROR")
            actions.push({ action: "fix-ci", icon: "󰖷", hint: "Fix failing checks with an agent" });
        if (pullRequest.reviewDecision === "CHANGES_REQUESTED")
            actions.push({ action: "address-comments", icon: "󰍨", hint: "Address review comments with an agent" });
        if (pullRequest.mergeable === "CONFLICTING")
            actions.push({ action: "rebase", icon: "󰘭", hint: "Rebase and resolve conflicts with an agent" });
        if (pullRequest.stack && pullRequest.stack.position === 1)
            actions.push({ action: "rebase-stack", icon: "󰘬", hint: "Rebase the whole stack of " + pullRequest.stack.size + " with an agent" });
        actions.push({ action: "checkout", icon: "󰊢", hint: "Check out in a worktree" });
        return actions;
    }

    function statusText(pullRequest) {
        const parts = [reviewLabel(pullRequest), checkLabel(pullRequest)];
        if (pullRequest.mergeable === "CONFLICTING")
            parts.push("has conflicts");
        return parts.join("  ·  ");
    }

    function statusColor(pullRequest) {
        if (pullRequest.mergeable === "CONFLICTING"
                || pullRequest.reviewDecision === "CHANGES_REQUESTED"
                || pullRequest.checkStatus === "FAILURE"
                || pullRequest.checkStatus === "ERROR")
            return "#d1434c";
        if (pullRequest.isDraft)
            return "#8b949e";
        if (pullRequest.reviewDecision === "REVIEW_REQUIRED"
                || pullRequest.checkStatus === "PENDING"
                || pullRequest.checkStatus === "EXPECTED")
            return "#e5c07b";
        return "#68b5ab";
    }

    implicitHeight: bodyHeight

    Text {
        anchors.centerIn: parent
        visible: root.pullRequestCount === 0
        width: parent.width - 32
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        text: root.shell.githubPullRequests.loading ? "Loading your pull requests…"
            : root.shell.githubPullRequests.error !== "" ? root.shell.githubPullRequests.error
            : "You have no open pull requests."
        color: root.shell.githubPullRequests.error !== "" ? "#d1434c" : "#8b949e"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 13
    }

    ListView {
        id: pullRequestList
        anchors.fill: parent
        visible: root.pullRequestCount > 0
        clip: true
        spacing: 6
        model: root.shell.githubPullRequests.pullRequests

        delegate: Rectangle {
            id: pullRequest

            required property var modelData
            required property int index
            property string hint: ""
            property bool highlighted: rowHover.hovered || root.selected === index
            width: pullRequestList.width
            height: 72
            radius: 11
            color: highlighted ? "#1f68b5ab" : "#092a2b2f"
            border.width: 1
            border.color: highlighted ? "#5568b5ab" : "#0dffffff"

            HoverHandler {
                id: rowHover
            }

            StackRail {
                id: stackRail
                pullRequests: pullRequestList.model
                index: pullRequest.index
                gap: pullRequestList.spacing
            }

            Column {
                anchors.left: parent.left
                anchors.right: actions.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 3

                Text {
                    width: parent.width
                    text: pullRequest.modelData.repository + " #" + pullRequest.modelData.number
                        + "  ·  " + root.relativeTime(pullRequest.modelData.updatedAt)
                        + (stackRail.label !== "" ? "  ·  " + stackRail.label : "")
                    color: "#a6e3a1"
                    elide: Text.ElideRight
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: pullRequest.modelData.title
                    color: "#f2f2f2"
                    elide: Text.ElideRight
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width
                    text: pullRequest.hint !== "" ? pullRequest.hint : root.statusText(pullRequest.modelData)
                    color: pullRequest.hint !== "" ? "#68b5ab" : root.statusColor(pullRequest.modelData)
                    elide: Text.ElideRight
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }
            }

            Text {
                id: arrow
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "󰅂"
                color: pullRequest.highlighted ? "#68b5ab" : "#5c656e"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 17
            }

            MouseArea {
                id: pullRequestMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open(pullRequest.index)
            }

            Row {
                id: actions
                anchors.right: arrow.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: root.agentActions(pullRequest.modelData)

                    AgentActionButton {
                        required property var modelData
                        required property int index
                        key: root.selected === pullRequest.index ? String(index + 1) : ""
                        action: modelData.action
                        icon: modelData.icon
                        hint: modelData.hint
                        url: pullRequest.modelData.url
                        onHoveredChanged: pullRequest.hint = hovered ? hint : ""
                        onTriggered: root.shell.workOverlayOpen = false
                    }
                }
            }
        }
    }
}
