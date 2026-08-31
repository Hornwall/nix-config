import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris

PopupWindow {
    id: root

    required property Item anchorItem
    required property var player

    function formatTime(seconds) {
        if (!isFinite(seconds) || seconds < 0)
            return "0:00";
        const minutes = Math.floor(seconds / 60);
        const remainder = Math.floor(seconds % 60).toString().padStart(2, "0");
        return minutes + ":" + remainder;
    }

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom
        gravity: Edges.Bottom
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 430
    implicitHeight: content.implicitHeight + 24

    Timer {
        running: root.visible && root.player && root.player.isPlaying
        repeat: true
        interval: 1000
        onTriggered: root.player.positionChanged()
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#f51e1f22"
        border.width: 1
        border.color: "#14ffffff"

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                    radius: 10
                    color: "#2a2b2f"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: root.player ? root.player.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !root.player || root.player.trackArtUrl === ""
                        text: "󰎆"
                        color: "#68b5ab"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 32
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: root.player ? root.player.trackTitle || "Unknown title" : "Nothing playing"
                        color: "#ffffff"
                        elide: Text.ElideRight
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.player ? root.player.trackArtist || root.player.identity : ""
                        color: "#b7bcba"
                        elide: Text.ElideRight
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 12
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.player && root.player.trackAlbum !== ""
                        text: root.player ? root.player.trackAlbum : ""
                        color: "#7d858d"
                        elide: Text.ElideRight
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 10
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 6

                        PopupButton {
                            enabled: root.player && root.player.canGoPrevious
                            implicitWidth: 48
                            implicitHeight: 34
                            text: "󰒮"
                            onClicked: root.player.previous()
                        }

                        PopupButton {
                            enabled: root.player && root.player.canTogglePlaying
                            implicitWidth: 54
                            implicitHeight: 38
                            text: root.player && root.player.isPlaying ? "󰏤" : "󰐊"
                            onClicked: root.player.togglePlaying()
                        }

                        PopupButton {
                            enabled: root.player && root.player.canGoNext
                            implicitWidth: 48
                            implicitHeight: 34
                            text: "󰒭"
                            onClicked: root.player.next()
                        }

                        Item { Layout.fillWidth: true }

                        PopupButton {
                            visible: root.player && root.player.canRaise
                            implicitWidth: 42
                            implicitHeight: 34
                            text: "󰍉"
                            onClicked: root.player.raise()
                        }
                    }
                }
            }

            Slider {
                Layout.fillWidth: true
                visible: root.player && root.player.positionSupported
                from: 0
                to: root.player && root.player.lengthSupported ? root.player.length : 1
                value: root.player ? root.player.position : 0
                onMoved: root.player.position = value
            }

            RowLayout {
                visible: root.player && root.player.positionSupported
                Layout.fillWidth: true

                Text {
                    text: root.formatTime(root.player ? root.player.position : 0)
                    color: "#7d858d"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.formatTime(root.player ? root.player.length : 0)
                    color: "#7d858d"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }
            }

            RowLayout {
                visible: Mpris.players.values.length > 1
                Layout.fillWidth: true

                Text {
                    text: "PLAYERS"
                    color: "#7d858d"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }

                Repeater {
                    model: Mpris.players

                    PopupButton {
                        required property MprisPlayer modelData
                        implicitHeight: 30
                        text: modelData.identity
                        accent: modelData === root.player ? "#68b5ab" : "#b7bcba"
                        onClicked: {
                            if (modelData.canRaise)
                                modelData.raise();
                        }
                    }
                }
            }
        }
    }
}
