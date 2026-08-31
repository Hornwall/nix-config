import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower

PanelWindow {
    id: bar

    required property var shell
    required property var modelData
    property var networkDevice: Networking.devices.values.find(device => device.connected) || null
    property var bluetoothAdapter: Bluetooth.defaultAdapter
    property bool bluetoothConnected: Bluetooth.devices.values.some(device => device.connected)
    property var player: Mpris.players.values.find(candidate => candidate.isPlaying)
        || Mpris.players.values[0] || null
    property var sink: Pipewire.defaultAudioSink
    property var battery: UPower.displayDevice

    screen: modelData
    visible: shell.barVisible
    aboveWindows: true
    color: "transparent"
    implicitHeight: 36
    exclusiveZone: visible ? 36 : 0

    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        left: 6
        right: 6
    }

    WlrLayershell.namespace: "quickshell-bar"

    PwObjectTracker {
        objects: [bar.sink]
    }

    ScriptValue {
        id: weather
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.sh"]
        interval: 1800000
    }

    ScriptValue {
        id: voxtype
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/voxtype-icon.sh"]
        interval: 2000
    }

    ScriptValue {
        id: recording
        command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/recording-icon.sh"]
        interval: 2000
    }

    ScriptValue {
        id: notificationCount
        command: ["sh", "-c", "swaync-client -c 2>/dev/null || echo 0"]
        interval: 2000
    }

    Rectangle {
        anchors.fill: parent
        radius: 16
        color: "#e6161719"
        border.width: 1
        border.color: "#0fffffff"

        RowLayout {
            id: start
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 6
            spacing: 5

            BarButton {
                id: dashboardButton
                text: "󰍜"
                onClicked: dashboardPopup.visible = !dashboardPopup.visible
            }

            Repeater {
                model: Hyprland.workspaces

                Rectangle {
                    id: workspaceDot
                    required property HyprlandWorkspace modelData
                    property bool onScreen: modelData.id > 0
                        && modelData.monitor === Hyprland.monitorFor(bar.screen)

                    Layout.preferredWidth: onScreen ? 14 : 0
                    Layout.preferredHeight: 14
                    Layout.leftMargin: onScreen ? 3 : 0
                    Layout.rightMargin: onScreen ? 3 : 0
                    visible: onScreen
                    radius: 7
                    color: modelData.focused ? "#68b5ab" : "transparent"
                    border.width: 2
                    border.color: modelData.urgent ? "#d1434c"
                        : modelData.focused ? "#68b5ab"
                        : modelData.active ? "#b7bcba" : "#5c656e"

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: workspaceDot.modelData.activate()
                    }
                }
            }
        }

        BarButton {
            id: music
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            visible: bar.player !== null && bar.player.trackTitle !== ""
            width: Math.min(500, implicitWidth)
            text: bar.player
                ? bar.player.trackTitle + (bar.player.trackArtist ? " — " + bar.player.trackArtist : "")
                : ""
            textColor: "#b7bcba"
            onClicked: {
                if (bar.player && bar.player.canTogglePlaying)
                    bar.player.isPlaying = !bar.player.isPlaying;
            }
        }

        RowLayout {
            id: end
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 6
            spacing: 1

            BarButton {
                text: {
                    if (!bar.sink || !bar.sink.audio)
                        return "󰕾 --";
                    if (bar.sink.audio.muted)
                        return "󰖁 0%";
                    const volume = Math.round(bar.sink.audio.volume * 100);
                    return (volume < 35 ? "󰕿 " : volume < 70 ? "󰖀 " : "󰕾 ") + volume + "%";
                }
                textColor: "#ffffff"
                onClicked: {
                    if (bar.sink && bar.sink.audio)
                        bar.sink.audio.muted = !bar.sink.audio.muted;
                }
                onWheel: wheel => {
                    if (bar.sink && bar.sink.audio) {
                        const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + delta));
                    }
                }
            }

            BarButton {
                text: !bar.networkDevice ? "󰤭"
                    : bar.networkDevice.type === DeviceType.Wired ? "󰈀" : "󰤨"
                onClicked: Quickshell.execDetached(["ghostty", "-e", "nmtui"])
            }

            BarButton {
                visible: bar.bluetoothAdapter !== null
                text: !bar.bluetoothAdapter || !bar.bluetoothAdapter.enabled ? "󰂲"
                    : bar.bluetoothConnected ? "󰂱" : "󰂯"
                onClicked: {
                    if (bar.bluetoothAdapter)
                        bar.bluetoothAdapter.enabled = !bar.bluetoothAdapter.enabled;
                }
            }

            BarButton {
                visible: bar.battery.ready && bar.battery.isLaptopBattery
                text: {
                    const percent = Math.round(bar.battery.percentage * 100);
                    const icon = percent < 15 ? "󰁺" : percent < 40 ? "󰁾"
                        : percent < 70 ? "󰂀" : percent < 90 ? "󰂂" : "󰁹";
                    return icon + " " + percent + "%";
                }
                textColor: bar.battery.percentage < 0.15 ? "#d1434c" : "#ffffff"
            }

            BarButton {
                id: profileButton
                visible: bar.battery.ready && bar.battery.isLaptopBattery
                text: PowerProfiles.profile === PowerProfile.Performance ? "󰓅"
                    : PowerProfiles.profile === PowerProfile.PowerSaver ? "󰌪" : "󰾅"
                onClicked: profilePopup.visible = !profilePopup.visible
            }

            BarButton {
                text: voxtype.text || "󰍬"
            }

            BarButton {
                visible: recording.text !== ""
                text: recording.text
                textColor: "#ff5555"
            }

            Repeater {
                model: SystemTray.items

                Item {
                    id: trayItem
                    required property SystemTrayItem modelData
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 32

                    IconImage {
                        anchors.centerIn: parent
                        implicitWidth: 18
                        implicitHeight: 18
                        source: trayItem.modelData.icon
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        onClicked: function(mouse) {
                            if (mouse.button === Qt.MiddleButton) {
                                trayItem.modelData.secondaryActivate();
                            } else if (mouse.button === Qt.RightButton || trayItem.modelData.onlyMenu) {
                                const pos = bar.contentItem.mapFromItem(trayItem, 0, trayItem.height);
                                trayItem.modelData.display(bar, pos.x, pos.y);
                            } else {
                                trayItem.modelData.activate();
                            }
                        }
                    }
                }
            }

            BarButton {
                id: weatherButton
                visible: weather.text !== ""
                text: weather.text.replace(/<[^>]*>/g, "")
                textColor: "#ffffff"
                onClicked: weatherPopup.visible = !weatherPopup.visible
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            BarButton {
                text: Qt.locale("sv_SE").toString(clock.date, "ddd MMM dd  HH:mm")
                textColor: "#ffffff"
            }

            BarButton {
                text: "󰂚" + (notificationCount.text !== "0" && notificationCount.text !== ""
                    ? " " + notificationCount.text : "")
                textColor: "#b4befe"
                onClicked: Quickshell.execDetached(["swaync-client", "-t", "-sw"])
            }
        }
    }

    DashboardPopup {
        id: dashboardPopup
        anchorItem: dashboardButton
    }

    WeatherPopup {
        id: weatherPopup
        anchorItem: weatherButton
    }

    PowerProfilePopup {
        id: profilePopup
        anchorItem: profileButton
    }
}
