import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var shell
    required property var modelData
    property var monitor: Hyprland.monitorFor(screen)
    property var workspace: monitor ? monitor.activeWorkspace : null
    property bool emptyWorkspace: workspace !== null
        && workspace.toplevels.values.length === 0

    screen: modelData
    visible: emptyWorkspace
    color: "transparent"
    implicitWidth: Math.min(1136, modelData.width - 48)
    implicitHeight: Math.max(reviewRequests.implicitHeight, myPullRequests.implicitHeight)
    exclusiveZone: 0

    anchors {
        top: true
        left: true
    }
    margins {
        top: Math.max(48, Math.round((modelData.height - root.implicitHeight) / 2))
        left: Math.max(24, Math.round((modelData.width - root.implicitWidth) / 2))
    }

    WlrLayershell.namespace: "quickshell-empty-workspace"
    WlrLayershell.layer: WlrLayer.Bottom

    RowLayout {
        anchors.fill: parent
        spacing: 16

        ReviewRequestsWidget {
            id: reviewRequests
            Layout.fillWidth: true
            Layout.fillHeight: true
            shell: root.shell
        }

        MyPullRequestsWidget {
            id: myPullRequests
            Layout.fillWidth: true
            Layout.fillHeight: true
            shell: root.shell
        }
    }
}
