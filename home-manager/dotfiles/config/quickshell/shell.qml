import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property bool barVisible: true

    Variants {
        model: Quickshell.screens

        Bar {
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
