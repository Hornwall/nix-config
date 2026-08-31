import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking

PopupWindow {
    id: root

    required property Item anchorItem
    property var wifiDevice: Networking.devices.values.find(device => device.type === DeviceType.Wifi) || null
    property var wiredDevice: Networking.devices.values.find(device => device.type === DeviceType.Wired) || null
    property var sortedNetworks: wifiDevice
        ? [...wifiDevice.networks.values].sort((a, b) => {
            if (a.connected !== b.connected)
                return b.connected - a.connected;
            return b.signalStrength - a.signalStrength;
        }) : []

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 390
    implicitHeight: 540

    onVisibleChanged: {
        if (wifiDevice)
            wifiDevice.scannerEnabled = visible;
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
                    text: "NETWORK"
                    color: "#7d858d"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                }

                Text {
                    visible: root.wiredDevice && root.wiredDevice.connected
                    text: "󰈀  Wired"
                    color: "#68b5ab"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 12
                }

                PopupButton {
                    visible: root.wifiDevice !== null
                    implicitWidth: 86
                    implicitHeight: 30
                    text: Networking.wifiEnabled ? "󰖩  Wi-Fi" : "󰖪  Wi-Fi"
                    accent: Networking.wifiEnabled ? "#68b5ab" : "#7d858d"
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
                }
            }

            Text {
                visible: !root.wifiDevice
                Layout.alignment: Qt.AlignHCenter
                text: root.wiredDevice && root.wiredDevice.connected
                    ? "Connected over Ethernet" : "No network device available"
                color: "#b7bcba"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
            }

            ScrollView {
                visible: root.wifiDevice !== null
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: availableWidth

                ColumnLayout {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: ScriptModel { values: root.sortedNetworks }

                        Rectangle {
                            id: networkRow
                            required property var modelData
                            property bool askingForPassword: false
                            property bool supportsPsk: modelData.security === WifiSecurityType.WpaPsk
                                || modelData.security === WifiSecurityType.Wpa2Psk
                                || modelData.security === WifiSecurityType.Sae
                            property string errorText: ""

                            Layout.fillWidth: true
                            implicitHeight: networkContent.implicitHeight + 16
                            radius: 11
                            color: modelData.connected ? "#1f68b5ab" : "#2a2b2f"
                            border.width: 1
                            border.color: modelData.connected ? "#6868b5ab" : "#0dffffff"

                            Connections {
                                target: networkRow.modelData

                                function onConnectionFailed(reason) {
                                    networkRow.errorText = ConnectionFailReason.toString(reason);
                                    networkRow.askingForPassword = true;
                                }
                            }

                            ColumnLayout {
                                id: networkContent
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 5

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: {
                                            const strength = networkRow.modelData.signalStrength;
                                            return strength > 0.7 ? "󰤨" : strength > 0.4 ? "󰤥" : "󰤟";
                                        }
                                        color: "#68b5ab"
                                        font.family: "FiraCode Nerd Font"
                                        font.pixelSize: 16
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        Text {
                                            Layout.fillWidth: true
                                            text: networkRow.modelData.name
                                            elide: Text.ElideRight
                                            color: "#ffffff"
                                            font.family: "FiraCode Nerd Font"
                                            font.pixelSize: 13
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: (networkRow.modelData.known ? "Saved · " : "")
                                                + WifiSecurityType.toString(networkRow.modelData.security)
                                            color: "#7d858d"
                                            font.family: "FiraCode Nerd Font"
                                            font.pixelSize: 10
                                        }
                                    }

                                    PopupButton {
                                        implicitWidth: 90
                                        implicitHeight: 32
                                        text: networkRow.modelData.connected ? "Disconnect"
                                            : networkRow.modelData.stateChanging ? "Connecting…" : "Connect"
                                        accent: networkRow.modelData.connected ? "#d1434c" : "#68b5ab"
                                        onClicked: {
                                            if (networkRow.modelData.connected) {
                                                networkRow.modelData.disconnect();
                                            } else if (networkRow.modelData.known
                                                    || networkRow.modelData.security === WifiSecurityType.Open) {
                                                networkRow.modelData.connect();
                                            } else if (networkRow.supportsPsk) {
                                                networkRow.askingForPassword = true;
                                            } else {
                                                Quickshell.execDetached(["ghostty", "-e", "nmtui"]);
                                            }
                                        }
                                    }
                                }

                                RowLayout {
                                    visible: networkRow.askingForPassword
                                    Layout.fillWidth: true

                                    TextField {
                                        id: password
                                        Layout.fillWidth: true
                                        placeholderText: "Wi-Fi password"
                                        echoMode: TextInput.Password
                                        color: "#ffffff"
                                        selectByMouse: true
                                    }

                                    PopupButton {
                                        implicitWidth: 64
                                        implicitHeight: 32
                                        text: "Join"
                                        onClicked: {
                                            networkRow.errorText = "";
                                            networkRow.modelData.connectWithPsk(password.text);
                                        }
                                    }
                                }

                                Text {
                                    visible: networkRow.errorText !== ""
                                    text: networkRow.errorText
                                    color: "#d1434c"
                                    font.family: "FiraCode Nerd Font"
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
