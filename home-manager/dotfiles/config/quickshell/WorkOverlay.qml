import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Agents and pull requests on top of everything, toggled with `qs ipc call work toggle`.
// Taking an action, Escape, or clicking the backdrop hides it.
PanelWindow {
    id: root

    required property var shell
    required property var modelData
    property var monitor: Hyprland.monitorFor(screen)

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
        anchors.centerIn: parent
        width: Math.min(1136, root.width - 48)
        height: Math.min(root.height - 96, agentSessions.implicitHeight + (agentSessions.visible ? 16 : 0)
            + Math.max(reviewRequests.implicitHeight, myPullRequests.implicitHeight))
        focus: true
        Keys.onEscapePressed: root.shell.workOverlayOpen = false

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
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                ReviewRequestsWidget {
                    id: reviewRequests
                    Layout.fillWidth: true
                    // Both lists share the taller one's height.
                    Layout.preferredHeight: Math.max(reviewRequests.implicitHeight, myPullRequests.implicitHeight)
                    shell: root.shell
                }

                MyPullRequestsWidget {
                    id: myPullRequests
                    Layout.fillWidth: true
                    // Both lists share the taller one's height.
                    Layout.preferredHeight: Math.max(reviewRequests.implicitHeight, myPullRequests.implicitHeight)
                    shell: root.shell
                }
            }
        }
    }
}
