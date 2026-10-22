import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    required property var shell
    property int pullRequestCount: shell.githubReviews.pullRequests.length
    property int bodyHeight: pullRequestCount > 0
        ? Math.min(pullRequestCount, 6) * 94 - 6 : 90

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

    function riskColor(risk) {
        if (risk === "high")
            return "#d1434c";
        if (risk === "medium")
            return "#f9e2af";
        return "#a6e3a1";
    }

    function triageLine(pullRequest) {
        const triage = shell.githubReviews.triage[pullRequest.url];
        if (pullRequest.isDraft)
            return "Draft, not triaged";
        if (!triage || (triage.status === "running" && !triage.summary))
            return "Triaging…";
        if (triage.status === "error" && !triage.summary)
            return "Triage failed: " + triage.error;
        return triage.summary;
    }

    function triageMeta(pullRequest) {
        const triage = shell.githubReviews.triage[pullRequest.url];
        if (!triage || !triage.risk)
            return "";
        const flags = (triage.flags || []).join(", ").replace(/&/g, "&amp;").replace(/</g, "&lt;");
        return "  ·  <font color=\"" + riskColor(triage.risk) + "\">● " + triage.risk + "</font>  ·  ~"
            + triage.minutes + " min" + (flags !== "" ? "  ·  " + flags : "");
    }

    function agentActions(pullRequest) {
        return [
            { action: "review", icon: "󰈈", hint: "Review with an agent" },
            { action: "second-opinion", icon: "󰀎", hint: "Second opinion: two agents side by side" }
        ];
    }

    implicitWidth: 560
    implicitHeight: bodyHeight + 91
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
                text: "󰊤"
                color: "#b4befe"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 21
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "Review requests"
                    color: "#ffffff"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.pullRequestCount === 1 ? "1 pull request"
                        : root.pullRequestCount + " pull requests"
                    color: "#8b949e"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 9
                color: refreshMouse.containsMouse ? "#1f68b5ab" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: root.shell.githubReviews.loading ? "󰑓" : "󰑐"
                    color: root.shell.githubReviews.loading ? "#8b949e" : "#68b5ab"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 16
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    enabled: !root.shell.githubReviews.loading
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shell.githubReviews.refresh()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: "#12ffffff"
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.bodyHeight
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                visible: root.pullRequestCount === 0
                width: parent.width - 32
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: root.shell.githubReviews.loading ? "Loading review requests…"
                    : root.shell.githubReviews.error !== "" ? root.shell.githubReviews.error
                    : "You're all caught up."
                color: root.shell.githubReviews.error !== "" ? "#d1434c" : "#8b949e"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
            }

            ListView {
                id: pullRequestList
                anchors.fill: parent
                visible: root.pullRequestCount > 0
                clip: true
                spacing: 6
                model: root.shell.githubReviews.pullRequests

                delegate: Rectangle {
                    id: pullRequest

                    required property var modelData
                    required property int index
                    property string hint: ""
                    width: pullRequestList.width
                    height: 88
                    radius: 11
                    color: rowHover.hovered ? "#1f68b5ab" : "#092a2b2f"
                    border.width: 1
                    border.color: rowHover.hovered ? "#5568b5ab" : "#0dffffff"

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
                                + (pullRequest.modelData.isDraft ? "  ·  draft" : "")
                                + (stackRail.label !== "" ? "  ·  " + stackRail.label : "")
                            color: "#b4befe"
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
                            text: root.triageLine(pullRequest.modelData)
                            color: "#a9b1ba"
                            elide: Text.ElideRight
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 11
                        }

                        Text {
                            width: parent.width
                            textFormat: Text.StyledText
                            text: pullRequest.hint !== "" ? pullRequest.hint
                                : "@" + pullRequest.modelData.author + "  ·  "
                                    + root.relativeTime(pullRequest.modelData.updatedAt)
                                    + root.triageMeta(pullRequest.modelData)
                            color: pullRequest.hint !== "" ? "#68b5ab" : "#7d8690"
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
                        color: rowHover.hovered ? "#68b5ab" : "#5c656e"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: pullRequestMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", pullRequest.modelData.url]);
                            root.shell.workOverlayOpen = false;
                        }
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
    }
}
