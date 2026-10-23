import QtQuick
import QtQuick.Layouts

// Review requests and your own pull requests in one box, one tab each.
Rectangle {
    id: root

    required property var shell
    // "reviews" or "mine".
    property string tab: "reviews"
    property alias reviews: reviewRequests
    property alias mine: myPullRequests
    // The keyboard-selected row in the open tab, or -1.
    property int selected: -1
    property var service: tab === "reviews" ? shell.githubReviews : shell.githubPullRequests
    // Sized for the longer list so switching tabs doesn't resize the box.
    property int bodyHeight: Math.max(reviewRequests.implicitHeight, myPullRequests.implicitHeight)

    signal tabClicked(string name)

    implicitHeight: bodyHeight + 91
    radius: 16
    color: "#e61e1f22"
    border.width: 1
    border.color: "#18ffffff"

    component Tab: Rectangle {
        id: tabButton

        required property string name
        required property string icon
        required property color iconColor
        required property string label
        required property int count
        property bool active: root.tab === name

        Layout.preferredHeight: 34
        Layout.preferredWidth: tabRow.implicitWidth + 24
        radius: 10
        color: active ? "#1f68b5ab" : tabMouse.containsMouse ? "#0dffffff" : "transparent"
        border.width: 1
        border.color: active ? "#5568b5ab" : "transparent"

        Row {
            id: tabRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tabButton.icon
                color: tabButton.iconColor
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 18
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: tabButton.label
                color: tabButton.active ? "#ffffff" : "#a9b1ba"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 14
                font.weight: tabButton.active ? Font.DemiBold : Font.Normal
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(20, countText.implicitWidth + 10)
                height: 18
                radius: 9
                color: "#14ffffff"

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: tabButton.count
                    color: "#a9b1ba"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }
            }
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.tabClicked(tabButton.name)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            spacing: 6

            Tab {
                name: "reviews"
                icon: "󰊤"
                iconColor: "#b4befe"
                label: "Review requests"
                count: reviewRequests.pullRequestCount
            }

            Tab {
                name: "mine"
                icon: "󰘬"
                iconColor: "#a6e3a1"
                label: "My pull requests"
                count: myPullRequests.pullRequestCount
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                radius: 9
                color: refreshMouse.containsMouse ? "#1f68b5ab" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: root.service.loading ? "󰑓" : "󰑐"
                    color: root.service.loading ? "#8b949e" : "#68b5ab"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 16
                }

                MouseArea {
                    id: refreshMouse
                    anchors.fill: parent
                    enabled: !root.service.loading
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.service.refresh()
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

            ReviewRequestsWidget {
                id: reviewRequests
                anchors.fill: parent
                visible: root.tab === "reviews"
                shell: root.shell
                selected: visible ? root.selected : -1
            }

            MyPullRequestsWidget {
                id: myPullRequests
                anchors.fill: parent
                visible: root.tab === "mine"
                shell: root.shell
                selected: visible ? root.selected : -1
            }
        }
    }
}
