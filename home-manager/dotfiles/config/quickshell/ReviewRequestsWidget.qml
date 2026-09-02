import QtQuick
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: root

    required property var shell
    property int pullRequestCount: shell.githubReviews.pullRequests.length
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
                                + (pullRequest.modelData.isDraft ? "  ·  draft" : "")
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
                            text: "@" + pullRequest.modelData.author + "  ·  "
                                + root.relativeTime(pullRequest.modelData.updatedAt)
                            color: "#7d8690"
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
