import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: root

    required property Item anchorItem
    required property SystemClock clock

    property int displayedMonth: clock.date.getMonth()
    property int displayedYear: clock.date.getFullYear()
    property var selectedDate: clock.date
    property var calendarLocale: Qt.locale("sv_SE")

    function changeMonth(offset) {
        let month = displayedMonth + offset;
        let year = displayedYear;

        if (month < 0) {
            month = 11;
            year -= 1;
        } else if (month > 11) {
            month = 0;
            year += 1;
        }

        displayedMonth = month;
        displayedYear = year;
    }

    function showToday() {
        displayedMonth = clock.date.getMonth();
        displayedYear = clock.date.getFullYear();
        selectedDate = clock.date;
    }

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 338
    implicitHeight: content.implicitHeight + 24

    PopupPanel {
        anchors.fill: parent
        shown: root.visible
        onCloseRequested: root.visible = false

        ColumnLayout {
            id: content
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 7

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.calendarLocale.toString(clock.date, "HH:mm")
                color: "#ffffff"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 28
                font.weight: Font.DemiBold
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                Layout.bottomMargin: 3
                text: root.calendarLocale.toString(clock.date, "dddd d MMMM yyyy")
                color: "#b7bcba"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 12
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#14ffffff"
            }

            RowLayout {
                Layout.fillWidth: true

                PopupButton {
                    implicitWidth: 34
                    implicitHeight: 30
                    text: "󰅁"
                    onClicked: root.changeMonth(-1)
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.calendarLocale.monthName(root.displayedMonth)
                        + " " + root.displayedYear
                    color: "#ffffff"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                PopupButton {
                    implicitWidth: 34
                    implicitHeight: 30
                    text: "󰅂"
                    onClicked: root.changeMonth(1)
                }
            }

            DayOfWeekRow {
                id: weekDays
                Layout.alignment: Qt.AlignHCenter
                locale: root.calendarLocale
                spacing: 4

                delegate: Text {
                    required property string shortName
                    width: 38
                    height: 24
                    text: shortName
                    color: "#9aa4ac"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            MonthGrid {
                id: monthGrid
                Layout.alignment: Qt.AlignHCenter
                month: root.displayedMonth
                year: root.displayedYear
                locale: root.calendarLocale
                spacing: 4

                onClicked: date => root.selectedDate = date

                delegate: Rectangle {
                    required property var model
                    property bool inMonth: model.month === monthGrid.month
                    property bool isToday: model.day === root.clock.date.getDate()
                        && model.month === root.clock.date.getMonth()
                        && model.year === root.clock.date.getFullYear()
                    property bool isSelected: model.day === root.selectedDate.getDate()
                        && model.month === root.selectedDate.getMonth()
                        && model.year === root.selectedDate.getFullYear()

                    implicitWidth: 38
                    implicitHeight: 34
                    radius: 8
                    color: isToday ? "#68b5ab"
                        : isSelected ? "#3368b5ab" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: parent.model.day
                        color: parent.isToday ? "#161719"
                            : parent.inMonth ? "#ffffff" : "#7f8992"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 12
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                    }
                }
            }

            PopupButton {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 2
                implicitWidth: 90
                implicitHeight: 30
                text: "Today"
                onClicked: root.showToday()
            }
        }
    }
}
