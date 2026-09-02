import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    required property var shell
    property int pullRequestCount: shell.githubPullRequests.pullRequests.length
    property int bodyHeight: pullRequestCount > 0
        ? Math.min(pullRequestCount, 6) * 78 - 6 : 90

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
                text: "󰘬"
                color: "#a6e3a1"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 21
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: "My pull requests"
                    color: "#ffffff"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.pullRequestCount === 1 ? "1 open pull request"
                        : root.pullRequestCount + " open pull requests"
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
                    text: root.shell.githubPullRequests.loading ? "󰑓" : "󰑐"
                    color: root.shell.githubPullRequests.loading ? "#8b949e" : "#68b5ab"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 16
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    enabled: !root.shell.githubPullRequests.loading
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shell.githubPullRequests.refresh()
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
                    width: pullRequestList.width
                    height: 72
                    radius: 11
                    color: pullRequestMouse.containsMouse ? "#1f68b5ab" : "#092a2b2f"
                    border.width: 1
                    border.color: pullRequestMouse.containsMouse ? "#5568b5ab" : "#0dffffff"

                    Column {
                        anchors.left: parent.left
                        anchors.right: arrow.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 3

                        Text {
                            width: parent.width
                            text: pullRequest.modelData.repository + " #" + pullRequest.modelData.number
                                + "  ·  " + root.relativeTime(pullRequest.modelData.updatedAt)
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
                            text: root.statusText(pullRequest.modelData)
                            color: root.statusColor(pullRequest.modelData)
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
                        color: pullRequestMouse.containsMouse ? "#68b5ab" : "#5c656e"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: pullRequestMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached(["xdg-open", pullRequest.modelData.url])
                    }
                }
            }
        }
    }
}
