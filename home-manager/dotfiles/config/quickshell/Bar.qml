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
        top: 0
        left: 6
        right: 6
    }

    WlrLayershell.namespace: "quickshell-bar"

    PwObjectTracker {
        objects: [bar.sink]
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

    Rectangle {
        anchors.fill: parent
        radius: 0
        topLeftRadius: 0
        topRightRadius: 0
        bottomLeftRadius: 16
        bottomRightRadius: 16
        color: "#e6161719"

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            implicitHeight: 1
            color: "#0fffffff"
        }

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
            onClicked: mouse => {
                if (mouse.button === Qt.MiddleButton && bar.player && bar.player.canTogglePlaying)
                    bar.player.togglePlaying();
                else
                    mediaPopup.visible = !mediaPopup.visible;
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
                id: audioButton
                text: {
                    if (!bar.sink || !bar.sink.audio)
                        return "󰕾 --";
                    if (bar.sink.audio.muted)
                        return "󰖁 0%";
                    const volume = Math.round(bar.sink.audio.volume * 100);
                    return (volume < 35 ? "󰕿 " : volume < 70 ? "󰖀 " : "󰕾 ") + volume + "%";
                }
                textColor: "#ffffff"
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && bar.sink && bar.sink.audio)
                        bar.sink.audio.muted = !bar.sink.audio.muted;
                    else
                        audioPopup.visible = !audioPopup.visible;
                }
                onWheel: wheel => {
                    if (bar.sink && bar.sink.audio) {
                        const delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                        bar.sink.audio.volume = Math.max(0, Math.min(1, bar.sink.audio.volume + delta));
                    }
                }
            }

            BarButton {
                id: networkButton
                text: !bar.networkDevice ? "󰤭"
                    : bar.networkDevice.type === DeviceType.Wired ? "󰈀" : "󰤨"
                onClicked: networkPopup.visible = !networkPopup.visible
            }

            BarButton {
                id: bluetoothButton
                visible: bar.bluetoothAdapter !== null
                text: !bar.bluetoothAdapter || !bar.bluetoothAdapter.enabled ? "󰂲"
                    : bar.bluetoothConnected ? "󰂱" : "󰂯"
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton && bar.bluetoothAdapter)
                        bar.bluetoothAdapter.enabled = !bar.bluetoothAdapter.enabled;
                    else
                        bluetoothPopup.visible = !bluetoothPopup.visible;
                }
            }

            BarButton {
                id: powerButton
                visible: bar.battery.ready && bar.battery.isLaptopBattery
                text: {
                    const percent = Math.round(bar.battery.percentage * 100);
                    const batteryIcon = bar.battery.state === UPowerDeviceState.Charging ? "󰂄"
                        : percent < 15 ? "󰁺" : percent < 40 ? "󰁾"
                        : percent < 70 ? "󰂀" : percent < 90 ? "󰂂" : "󰁹";
                    return batteryIcon + " " + percent + "%";
                }
                textColor: bar.battery.percentage < 0.15 ? "#d1434c" : "#ffffff"
                onClicked: powerPopup.visible = !powerPopup.visible
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
                visible: bar.shell.weather.weatherData !== null
                text: {
                    const weather = bar.shell.weather;
                    if (!weather.weatherData)
                        return "";
                    return weather.iconFor(weather.weatherData.current.weatherCode, weather.weatherData.current.isDay)
                        + " " + weather.weatherData.current.temperature + "°C";
                }
                textColor: "#ffffff"
                onClicked: weatherPopup.visible = !weatherPopup.visible
            }

            SystemClock {
                id: clock
                precision: SystemClock.Minutes
            }

            BarButton {
                id: clockButton
                text: Qt.locale("sv_SE").toString(clock.date, "ddd MMM dd  HH:mm")
                textColor: "#ffffff"
                onClicked: calendarPopup.visible = !calendarPopup.visible
            }

            BarButton {
                id: notificationButton
                property int count: bar.shell.notificationServer.trackedNotifications.values.length
                text: (bar.shell.doNotDisturb ? "󰂛" : "󰂚") + (count > 0 ? " " + count : "")
                textColor: bar.shell.doNotDisturb ? "#ab78ad" : "#b4befe"
                onClicked: notificationPopup.visible = !notificationPopup.visible
            }
        }
    }

    DashboardPopup {
        id: dashboardPopup
        anchorItem: dashboardButton
    }

    MediaPopup {
        id: mediaPopup
        anchorItem: music
        player: bar.player
    }

    AudioPopup {
        id: audioPopup
        anchorItem: audioButton
    }

    NetworkPopup {
        id: networkPopup
        anchorItem: networkButton
    }

    BluetoothPopup {
        id: bluetoothPopup
        anchorItem: bluetoothButton
    }

    WeatherPopup {
        id: weatherPopup
        anchorItem: weatherButton
        weather: bar.shell.weather
    }

    PowerPopup {
        id: powerPopup
        anchorItem: powerButton
    }

    CalendarPopup {
        id: calendarPopup
        anchorItem: clockButton
        clock: clock
    }

    NotificationCenterPopup {
        id: notificationPopup
        anchorItem: notificationButton
        shell: bar.shell
    }
}
