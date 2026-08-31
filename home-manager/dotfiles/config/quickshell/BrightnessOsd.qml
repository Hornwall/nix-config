import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property bool shouldShow: false
    property string kind: "screen"
    property real value: 0

    function refresh(requestedKind) {
        kind = requestedKind;
        queryProcess.exec(requestedKind === "keyboard"
            ? ["brightnessctl", "-m", "-d", "*::kbd_backlight"]
            : ["brightnessctl", "-m", "-c", "backlight"]);
    }

    function show() {
        shouldShow = true;
        hideTimer.restart();
    }

    IpcHandler {
        target: "brightness"

        function showScreen(): void {
            root.refresh("screen");
        }

        function showKeyboard(): void {
            root.refresh("keyboard");
        }
    }

    Process {
        id: queryProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split(",");
                if (fields.length < 4)
                    return;

                const percentage = Number(fields[3].replace("%", ""));
                if (!isNaN(percentage)) {
                    root.value = Math.max(0, Math.min(1, percentage / 100));
                    root.show();
                }
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1200
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
                        text: root.kind === "keyboard" ? "󰌌"
                            : root.value < 0.35 ? "󰃞" : root.value < 0.7 ? "󰃟" : "󰃠"
                        color: "#68b5ab"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 22
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 9
                        radius: 5
                        color: "#2a2b2f"
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * root.value
                            radius: parent.radius
                            color: "#68b5ab"

                            Behavior on width {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }

                    Text {
                        text: Math.round(root.value * 100) + "%"
                        color: "#ffffff"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
    }
}
