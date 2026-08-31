import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    property bool barVisible: true
    property bool doNotDisturb: false
    property var latestNotification: null
    property bool toastVisible: false
    property int toastSerial: 0
    property alias notificationServer: notifications

    NotificationServer {
        id: notifications
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        actionsSupported: true
        imageSupported: true

        onNotification: notification => {
            notification.tracked = true;

            if (!notification.lastGeneration && !root.doNotDisturb) {
                root.latestNotification = notification;
                root.toastSerial += 1;
                root.toastVisible = true;
            }
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            shell: root
        }
    }

    Variants {
        model: Quickshell.screens

        NotificationToasts {
            shell: root
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.barVisible = !root.barVisible;
        }

        function show(): void {
            root.barVisible = true;
        }

        function hide(): void {
            root.barVisible = false;
        }
    }
}
