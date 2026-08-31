import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

PopupWindow {
    id: root

    required property Item anchorItem
    required property SystemClock clock

    property int displayedMonth: clock.date.getMonth()
    property int displayedYear: clock.date.getFullYear()
    property var selectedDate: clock.date
    property var calendarLocale: Qt.locale("sv_SE")
    property var monthEvents: []
    property bool agendaLoading: false
    property string agendaError: ""
    property var selectedEvents: eventsForDate(selectedDate)

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

    function dayStart(date) {
        return new Date(date.getFullYear(), date.getMonth(), date.getDate());
    }

    function eventsForDate(date) {
        const startDate = dayStart(date);
        const endDate = new Date(
            startDate.getFullYear(), startDate.getMonth(), startDate.getDate() + 1);
        const start = startDate.getTime() / 1000;
        const end = endDate.getTime() / 1000;
        return monthEvents.filter(event => event.start < end && event.end > start);
    }

    function hasEvents(day, month, year) {
        return eventsForDate(new Date(year, month, day)).length > 0;
    }

    function isAllDay(event) {
        const start = new Date(event.start * 1000);
        const end = new Date(event.end * 1000);
        return start.getHours() === 0 && start.getMinutes() === 0
            && end.getHours() === 0 && end.getMinutes() === 0;
    }

    function eventTime(event) {
        if (isAllDay(event))
            return "All day";

        const selectedStartDate = dayStart(selectedDate);
        const selectedEndDate = new Date(
            selectedStartDate.getFullYear(), selectedStartDate.getMonth(),
            selectedStartDate.getDate() + 1);
        const selectedStart = selectedStartDate.getTime() / 1000;
        const selectedEnd = selectedEndDate.getTime() / 1000;
        const start = new Date(event.start * 1000);
        const end = new Date(event.end * 1000);

        if (event.start < selectedStart)
            return "Until " + calendarLocale.toString(end, "HH:mm");
        if (event.end > selectedEnd)
            return calendarLocale.toString(start, "HH:mm") + " →";
        return calendarLocale.toString(start, "HH:mm")
            + "–" + calendarLocale.toString(end, "HH:mm");
    }

    function eventIsOngoing(event) {
        const now = clock.date.getTime() / 1000;
        return event.start <= now && event.end > now;
    }

    function refreshAgenda() {
        if (!visible)
            return;

        const rangeStart = new Date(displayedYear, displayedMonth, -6);
        const rangeEnd = new Date(displayedYear, displayedMonth + 1, 8);
        agendaLoading = true;
        agendaError = "";
        agendaProcess.exec([
            "gjs", "-m", Quickshell.shellPath("scripts/agenda.js"),
            String(Math.floor(rangeStart.getTime() / 1000)),
            String(Math.floor(rangeEnd.getTime() / 1000))
        ]);
    }

    anchor {
        item: root.anchorItem
        edges: Edges.Bottom | Edges.Right
        gravity: Edges.Bottom | Edges.Left
        margins.top: 6
    }
    grabFocus: true
    color: "transparent"
    implicitWidth: 430
    implicitHeight: content.implicitHeight + 24

    onVisibleChanged: {
        if (visible)
            agendaRefresh.restart();
    }
    onDisplayedMonthChanged: agendaRefresh.restart()
    onDisplayedYearChanged: agendaRefresh.restart()

    Timer {
        id: agendaRefresh
        interval: 100
        onTriggered: root.refreshAgenda()
    }

    Process {
        id: agendaProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output === "")
                    return;
                try {
                    root.monthEvents = JSON.parse(output);
                    root.agendaError = "";
                } catch (exception) {
                    root.agendaError = "Could not read calendar data";
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.agendaLoading = false;
            if (exitCode !== 0)
                root.agendaError = "Calendar service unavailable";
        }
    }

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
                    property bool hasAgenda: root.hasEvents(model.day, model.month, model.year)

                    implicitWidth: 38
                    implicitHeight: 34
                    radius: 8
                    color: isToday ? "#68b5ab"
                        : isSelected ? "#3368b5ab" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: parent.hasAgenda ? -2 : 0
                        text: parent.model.day
                        color: parent.isToday ? "#161719"
                            : parent.inMonth ? "#ffffff" : "#7f8992"
                        font.family: "FiraCode Nerd Font"
                        font.pixelSize: 12
                        font.weight: parent.isToday ? Font.Bold : Font.Normal
                    }

                    Rectangle {
                        visible: parent.hasAgenda
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        width: 4
                        height: 4
                        radius: 2
                        color: parent.isToday ? "#161719" : "#68b5ab"
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

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: 3
                implicitHeight: 1
                color: "#14ffffff"
            }

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "AGENDA · " + root.calendarLocale.toString(root.selectedDate, "ddd d MMM")
                    color: "#9aa4ac"
                    font.family: "FiraCode Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 1.0
                }

                PopupButton {
                    implicitWidth: 34
                    implicitHeight: 28
                    text: root.agendaLoading ? "󰑓" : "󰑐"
                    onClicked: root.refreshAgenda()
                }

                PopupButton {
                    implicitWidth: 34
                    implicitHeight: 28
                    text: "󰃭"
                    onClicked: Quickshell.execDetached(["gnome-calendar"])
                }
            }

            Text {
                visible: root.agendaLoading && root.monthEvents.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                text: "Loading agenda…"
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
            }

            Text {
                visible: !root.agendaLoading && root.agendaError !== ""
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                text: root.agendaError
                color: "#d1434c"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
            }

            Text {
                visible: !root.agendaLoading && root.agendaError === ""
                    && root.selectedEvents.length === 0
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                text: "No events scheduled"
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 11
            }

            Repeater {
                model: root.selectedEvents.slice(0, 6)

                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: eventContent.implicitHeight + 14
                    radius: 10
                    color: "#2a2b2f"

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 3
                        color: root.eventIsOngoing(modelData) ? "#a6e3a1" : "#68b5ab"
                    }

                    RowLayout {
                        id: eventContent
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 8

                        Text {
                            Layout.preferredWidth: 80
                            text: root.eventTime(modelData)
                            color: root.eventIsOngoing(modelData) ? "#a6e3a1" : "#9aa4ac"
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.summary
                            color: "#ffffff"
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.family: "FiraCode Nerd Font"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Text {
                visible: root.selectedEvents.length > 6
                Layout.alignment: Qt.AlignHCenter
                text: "+" + (root.selectedEvents.length - 6) + " more events"
                color: "#9aa4ac"
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 10
            }
        }
    }
}
