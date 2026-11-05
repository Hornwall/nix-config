import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Beyond Identity silently waits for a fingerprint before falling back to a
// password dialog. Follow its journal and show a hint while it is waiting.
Scope {
    id: root

    property bool shouldShow: false

    Process {
        id: journalProcess
        running: true
        command: ["journalctl", "--user", "--follow", "--lines=0", "--output=cat",
            "--unit=beyond-identity-webserver"]

        stdout: SplitParser {
            onRead: line => {
                if (line.includes("verify user started")) {
                    root.shouldShow = true;
                    safetyTimer.restart();
                } else if (line.includes("verify user completed") || line.includes("verify_user")) {
                    root.shouldShow = false;
                }
            }
        }

        onExited: restartTimer.start()
    }

    Timer {
        id: restartTimer
        interval: 5000
        onTriggered: journalProcess.running = true
    }

    Timer {
        id: safetyTimer
        interval: 120000
        onTriggered: root.shouldShow = false
    }

    LazyLoader {
        active: root.shouldShow

        PanelWindow {
            anchors.bottom: true
            margins.bottom: screen.height / 5
            exclusionMode: ExclusionMode.Ignore

            implicitWidth: 380
            implicitHeight: 52
            color: "transparent"
            mask: Region {}

            WlrLayershell.namespace: "quickshell-osd"
            WlrLayershell.layer: WlrLayer.Overlay

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: "#f51e1f22"
                border.width: 1
                border.color: "#14ffffff"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    Text {
                        text: "󰈷"
                        color: "#68b5ab"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 22

                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.35; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "Beyond Identity: touch fingerprint sensor"
                        color: "#ffffff"
                        elide: Text.ElideRight
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
