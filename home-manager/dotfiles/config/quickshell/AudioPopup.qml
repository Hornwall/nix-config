import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

PopupWindow {
    id: root

    required property Item anchorItem
    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    property var audioDevices: Pipewire.nodes.values.filter(node => node.audio && !node.isStream)
    property var sinks: audioDevices.filter(node => node.isSink)
    property var sources: audioDevices.filter(node => !node.isSink)

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 380
    implicitHeight: Math.min(560, content.implicitHeight + 24)

    PwObjectTracker {
        objects: root.audioDevices
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#f51e1f22"
        border.width: 1
        border.color: "#14ffffff"

        ScrollView {
            anchors.fill: parent
            anchors.margins: 12
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                id: content
                width: parent.width
                spacing: 8

                Heading { text: "AUDIO" }

                AudioControl {
                    Layout.fillWidth: true
                    label: "󰕾  Output"
                    node: root.sink
                }

                AudioControl {
                    Layout.fillWidth: true
                    label: "󰍬  Microphone"
                    node: root.source
                }

                Heading { text: "OUTPUT DEVICE" }

                Repeater {
                    model: ScriptModel { values: root.sinks }

                    PopupButton {
                        required property var modelData
                        Layout.fillWidth: true
                        text: (modelData === root.sink ? "󰄬  " : "")
                            + (modelData.description || modelData.nickname || modelData.name)
                        accent: modelData === root.sink ? "#68b5ab" : "#b7bcba"
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                    }
                }

                Heading {
                    visible: root.sources.length > 0
                    text: "INPUT DEVICE"
                }

                Repeater {
                    model: ScriptModel { values: root.sources }

                    PopupButton {
                        required property var modelData
                        Layout.fillWidth: true
                        text: (modelData === root.source ? "󰄬  " : "")
                            + (modelData.description || modelData.nickname || modelData.name)
                        accent: modelData === root.source ? "#68b5ab" : "#b7bcba"
                        onClicked: Pipewire.preferredDefaultAudioSource = modelData
                    }
                }
            }
        }
    }

    component Heading: Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        text: ""
        color: "#7d858d"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 1.2
    }

    component AudioControl: Rectangle {
        id: control

        required property string label
        required property var node

        implicitHeight: layout.implicitHeight + 16
        radius: 11
        color: "#2a2b2f"

        ColumnLayout {
            id: layout
            anchors.fill: parent
            anchors.margins: 8
            spacing: 5

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: control.label
                    color: "#b7bcba"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 13
                }

                Text {
                    text: control.node && control.node.audio
                        ? Math.round(control.node.audio.volume * 100) + "%" : "--"
                    color: "#ffffff"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 13
                }

                PopupButton {
                    implicitWidth: 42
                    implicitHeight: 30
                    text: control.node && control.node.audio && control.node.audio.muted ? "󰖁" : "󰕾"
                    accent: control.node && control.node.audio && control.node.audio.muted ? "#d1434c" : "#68b5ab"
                    onClicked: {
                        if (control.node && control.node.audio)
                            control.node.audio.muted = !control.node.audio.muted;
                    }
                }
            }

            Slider {
                Layout.fillWidth: true
                from: 0
                to: 1
                value: control.node && control.node.audio ? control.node.audio.volume : 0
                enabled: control.node && control.node.audio
                onMoved: control.node.audio.volume = value
            }
        }
    }
}
