import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Wayland

Scope {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property bool shouldShow: false

    function show() {
        if (!sink || !sink.audio)
            return;
        shouldShow = true;
        hideTimer.restart();
    }

    PwObjectTracker {
        objects: [root.sink]
    }

    Connections {
        target: root.sink ? root.sink.audio : null

        function onVolumesChanged() {
            root.show();
        }

        function onMutedChanged() {
            root.show();
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
                        property real volume: root.sink && root.sink.audio
                            ? root.sink.audio.volume : 0
                        text: root.sink && root.sink.audio && root.sink.audio.muted ? "󰖁"
                            : volume < 0.35 ? "󰕿" : volume < 0.7 ? "󰖀" : "󰕾"
                        color: root.sink && root.sink.audio && root.sink.audio.muted
                            ? "#d1434c" : "#68b5ab"
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
                            width: parent.width * Math.max(0, Math.min(1,
                                root.sink && root.sink.audio && !root.sink.audio.muted
                                    ? root.sink.audio.volume : 0))
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
                        text: root.sink && root.sink.audio && !root.sink.audio.muted
                            ? Math.round(root.sink.audio.volume * 100) + "%" : "Muted"
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
