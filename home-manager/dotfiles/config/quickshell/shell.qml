import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

ShellRoot {
    id: root

    property alias barVisible: persistentState.barVisible
    property alias doNotDisturb: persistentState.doNotDisturb
    property var latestNotification: null
    property bool toastVisible: false
    property int toastSerial: 0
    property alias notificationServer: notifications
    property alias weather: weatherService
    property alias githubReviews: githubReviewService

    PersistentProperties {
        id: persistentState
        reloadableId: "shell-state"

        property bool barVisible: true
        property bool doNotDisturb: false
    }

    WeatherService {
        id: weatherService
    }

    GithubReviewService {
        id: githubReviewService
    }

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

    VolumeOsd {}
    BrightnessOsd {}

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

    Variants {
        model: Quickshell.screens

        EmptyWorkspaceWidgets {
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
