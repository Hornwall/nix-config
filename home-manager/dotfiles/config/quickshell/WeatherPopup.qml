import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    required property Item anchorItem
    required property var weather
    property var forecast: weather.weatherData
    property var locale: Qt.locale("sv_SE")

    function hour(time) {
        return time ? time.slice(11, 16) : "--";
    }

    function dayName(date, index) {
        if (index === 0)
            return "Today";
        return locale.toString(new Date(date + "T12:00:00"), "ddd");
    }

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 470
    implicitHeight: content.implicitHeight + 28

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
            anchors.margins: 14
            spacing: 8

            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: root.forecast ? root.forecast.location.toUpperCase() : "WEATHER"
                        color: "#9aa4ac"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.2
                    }

                    Text {
                        text: root.weather.lastUpdated
                            ? "Updated " + root.locale.toString(root.weather.lastUpdated, "HH:mm") : ""
                        color: "#9aa4ac"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 9
                    }
                }

                Text {
                    visible: root.weather.error !== ""
                    text: root.weather.error
                    color: "#d1434c"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 9
                }

                PopupButton {
                    implicitWidth: 34
                    implicitHeight: 30
                    text: root.weather.loading ? "󰑓" : "󰑐"
                    onClicked: root.weather.refresh()
                }
            }

            RowLayout {
                visible: root.forecast !== null
                Layout.fillWidth: true
                Layout.topMargin: 2
                spacing: 14

                Text {
                    text: root.forecast
                        ? root.weather.iconFor(root.forecast.current.weatherCode, root.forecast.current.isDay) : ""
                    color: "#68b5ab"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 46
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: root.forecast ? root.forecast.current.temperature + "°" : "--"
                        color: "#ffffff"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 34
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: root.forecast
                            ? root.weather.descriptionFor(root.forecast.current.weatherCode) : ""
                        color: "#ffffff"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 14
                    }

                    Text {
                        text: root.forecast ? "Feels like " + root.forecast.current.apparentTemperature + "°" : ""
                        color: "#9aa4ac"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 10
                    }
                }
            }

            GridLayout {
                visible: root.forecast !== null
                Layout.fillWidth: true
                columns: 4
                columnSpacing: 6

                Metric {
                    icon: "󰖎"
                    label: "Humidity"
                    value: root.forecast ? root.forecast.current.humidity + "%" : "--"
                }
                Metric {
                    icon: "󰖝"
                    label: "Wind"
                    value: root.forecast ? root.forecast.current.windSpeed + " km/h" : "--"
                }
                Metric {
                    icon: "󰖗"
                    label: "Rain"
                    value: root.forecast ? root.forecast.current.precipitation + " mm" : "--"
                }
                Metric {
                    icon: "󰔏"
                    label: "UV max"
                    value: root.forecast ? root.forecast.daily[0].uvIndex.toFixed(1) : "--"
                }
            }

            Heading {
                visible: root.forecast !== null
                text: "NEXT 24 HOURS"
            }

            RowLayout {
                visible: root.forecast !== null
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.forecast ? root.forecast.hourly : []

                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: hourlyContent.implicitHeight + 12
                        radius: 9
                        color: "#2a2b2f"

                        ColumnLayout {
                            id: hourlyContent
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.hour(modelData.time)
                                color: "#9aa4ac"
                                font.family: "FiraCode Nerd Font"
                                font.pixelSize: 9
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: root.weather.iconFor(modelData.weatherCode, modelData.isDay)
                                color: "#68b5ab"
                                font.family: "FiraCode Nerd Font"
                                font.pixelSize: 18
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: modelData.temperature + "°"
                                color: "#ffffff"
                                font.family: "FiraCode Nerd Font"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                visible: modelData.precipitationProbability > 0
                                text: modelData.precipitationProbability + "%"
                                color: "#89b4d8"
                                font.family: "FiraCode Nerd Font"
                                font.pixelSize: 8
                            }
                        }
                    }
                }
            }

            Heading {
                visible: root.forecast !== null
                text: "7-DAY FORECAST"
            }

            Repeater {
                model: root.forecast ? root.forecast.daily : []

                RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32

                    Text {
                        Layout.preferredWidth: 58
                        text: root.dayName(modelData.date, index)
                        color: index === 0 ? "#ffffff" : "#b7bcba"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 11
                        font.weight: index === 0 ? Font.DemiBold : Font.Normal
                    }

                    Text {
                        Layout.preferredWidth: 24
                        text: root.weather.iconFor(modelData.weatherCode, true)
                        color: "#68b5ab"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 17
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.weather.descriptionFor(modelData.weatherCode)
                        color: "#9aa4ac"
                        elide: Text.ElideRight
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 10
                    }

                    Text {
                        visible: modelData.precipitationProbability > 0
                        Layout.preferredWidth: 42
                        text: "󰖗 " + modelData.precipitationProbability + "%"
                        color: "#89b4d8"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 9
                    }

                    Text {
                        Layout.preferredWidth: 64
                        horizontalAlignment: Text.AlignRight
                        text: modelData.minimum + "° / " + modelData.maximum + "°"
                        color: "#ffffff"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 11
                    }
                }
            }

            RowLayout {
                visible: root.forecast !== null
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 3
                spacing: 20

                Text {
                    text: root.forecast ? "󰖜 " + root.hour(root.forecast.daily[0].sunrise) : ""
                    color: "#fab387"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }

                Text {
                    text: root.forecast ? "󰖛 " + root.hour(root.forecast.daily[0].sunset) : ""
                    color: "#ab78ad"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                }
            }
        }
    }

    component Heading: Text {
        Layout.fillWidth: true
        Layout.topMargin: 4
        text: ""
        color: "#9aa4ac"
        font.family: "FiraCode Nerd Font"
        font.pixelSize: 10
        font.weight: Font.Bold
        font.letterSpacing: 1.1
    }

    component Metric: Rectangle {
        required property string icon
        required property string label
        required property string value

        Layout.fillWidth: true
        implicitHeight: 58
        radius: 9
        color: "#2a2b2f"

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 1

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: icon + "  " + value
                color: "#ffffff"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 10
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: label
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 8
            }
        }
    }
}
