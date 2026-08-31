import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Bluetooth

PopupWindow {
    id: root

    required property Item anchorItem
    property var adapter: Bluetooth.defaultAdapter
    property var sortedDevices: [...Bluetooth.devices.values].sort((a, b) => {
        if (a.connected !== b.connected)
            return b.connected - a.connected;
        if (a.paired !== b.paired)
            return b.paired - a.paired;
        return a.name.localeCompare(b.name);
    })

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 390
    implicitHeight: 500

    onVisibleChanged: {
        if (adapter && adapter.enabled)
            adapter.discovering = visible;
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "#f51e1f22"
        border.width: 1
        border.color: "#14ffffff"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "BLUETOOTH"
                    color: "#9aa4ac"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                }

                Text {
                    visible: root.adapter && root.adapter.discovering
                    text: "Scanning…"
                    color: "#9aa4ac"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }

                PopupButton {
                    implicitWidth: 82
                    implicitHeight: 30
                    text: root.adapter && root.adapter.enabled ? "󰂯  On" : "󰂲  Off"
                    accent: root.adapter && root.adapter.enabled ? "#68b5ab" : "#9aa4ac"
                    onClicked: {
                        if (root.adapter)
                            root.adapter.enabled = !root.adapter.enabled;
                    }
                }
            }

            Text {
                visible: !root.adapter
                Layout.alignment: Qt.AlignHCenter
                text: "No Bluetooth adapter available"
                color: "#b7bcba"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
            }

            ScrollView {
                visible: root.adapter && root.adapter.enabled
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 6

                    Text {
                        visible: root.sortedDevices.length === 0
                        Layout.alignment: Qt.AlignHCenter
                        text: "Searching for devices…"
                        color: "#9aa4ac"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 12
                    }

                    Repeater {
                        model: ScriptModel { values: root.sortedDevices }

                        Rectangle {
                            id: deviceRow
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: deviceContent.implicitHeight + 16
                            radius: 11
                            color: modelData.connected ? "#1f68b5ab" : "#2a2b2f"
                            border.width: 1
                            border.color: modelData.connected ? "#6868b5ab" : "#0dffffff"

                            RowLayout {
                                id: deviceContent
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Item {
                                    property string iconSource: Quickshell.iconPath(deviceRow.modelData.icon, true)
                                    implicitWidth: 24
                                    implicitHeight: 24

                                    Text {
                                        anchors.centerIn: parent
                                        visible: parent.iconSource === ""
                                        text: "󰂯"
                                        color: "#68b5ab"
                                        font.family: "FiraCode Nerd Font"
                                        font.pixelSize: 18
                                    }

                                    IconImage {
                                        anchors.fill: parent
                                        visible: parent.iconSource !== ""
                                        source: parent.iconSource
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: deviceRow.modelData.name || deviceRow.modelData.deviceName
                                        elide: Text.ElideRight
                                        color: "#ffffff"
                                        font.family: "FiraCode Nerd Font"
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: deviceRow.modelData.connected ? "Connected"
                                            + (deviceRow.modelData.batteryAvailable
                                                ? " · " + Math.round(deviceRow.modelData.battery * 100) + "%" : "")
                                            : deviceRow.modelData.pairing ? "Pairing…"
                                            : deviceRow.modelData.paired ? "Paired" : "Available"
                                        color: deviceRow.modelData.connected ? "#68b5ab" : "#9aa4ac"
                                        font.family: "FiraCode Nerd Font"
                                        font.pixelSize: 10
                                    }
                                }

                                PopupButton {
                                    implicitWidth: 86
                                    implicitHeight: 32
                                    text: deviceRow.modelData.pairing ? "Cancel"
                                        : deviceRow.modelData.connected ? "Disconnect"
                                        : deviceRow.modelData.paired ? "Connect" : "Pair"
                                    accent: deviceRow.modelData.connected ? "#d1434c" : "#68b5ab"
                                    onClicked: {
                                        if (deviceRow.modelData.pairing)
                                            deviceRow.modelData.cancelPair();
                                        else if (deviceRow.modelData.connected)
                                            deviceRow.modelData.disconnect();
                                        else if (deviceRow.modelData.paired)
                                            deviceRow.modelData.connect();
                                        else
                                            deviceRow.modelData.pair();
                                    }
                                }

                                PopupButton {
                                    visible: deviceRow.modelData.paired && !deviceRow.modelData.connected
                                    implicitWidth: 34
                                    implicitHeight: 32
                                    text: "󰆴"
                                    accent: "#d1434c"
                                    onClicked: deviceRow.modelData.forget()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
