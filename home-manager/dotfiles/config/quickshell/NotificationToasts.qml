import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    required property var shell
    required property var modelData
    property var notification: shell.latestNotification
    property bool focusedScreen: Hyprland.focusedMonitor === Hyprland.monitorFor(screen)

    screen: modelData
    visible: shell.toastVisible && notification !== null && focusedScreen
    aboveWindows: true
    color: "transparent"
    implicitWidth: 390
    implicitHeight: card.implicitHeight
    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        right: true
    }
    margins {
        top: 48
        right: 12
    }

    WlrLayershell.namespace: "quickshell-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    Connections {
        target: root.shell

        function onToastSerialChanged() {
            if (root.visible)
                hideTimer.restart();
        }
    }

    Timer {
        id: hideTimer
        interval: root.notification && root.notification.expireTimeout > 0
            ? Math.max(2500, Math.min(10000, root.notification.expireTimeout)) : 5000
        onTriggered: root.shell.toastVisible = false
    }

    onVisibleChanged: {
        if (visible)
            hideTimer.restart();
        else
            hideTimer.stop();
    }

    NotificationCard {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        notification: root.notification
        compact: true
    }
}
