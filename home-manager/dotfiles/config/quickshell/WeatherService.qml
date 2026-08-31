import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var weatherData: null
    property bool loading: false
    property string error: ""
    property var lastUpdated: null

    function iconFor(code, isDay) {
        if (code === 0)
            return isDay === false ? "󰖔" : "󰖙";
        if (code === 1 || code === 2)
            return isDay === false ? "󰼱" : "󰖕";
        if (code === 3)
            return "󰖐";
        if (code === 45 || code === 48)
            return "󰖑";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82))
            return "󰖗";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return "󰖘";
        if (code >= 95)
            return "󰖓";
        return "󰖕";
    }

    function descriptionFor(code) {
        if (code === 0) return "Clear sky";
        if (code === 1) return "Mostly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Foggy";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code >= 61 && code <= 67) return "Rain";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Rain showers";
        if (code === 85 || code === 86) return "Snow showers";
        if (code >= 95) return "Thunderstorms";
        return "Mixed conditions";
    }

    function refresh() {
        if (fetchProcess.running)
            return;
        loading = true;
        error = "";
        fetchProcess.running = true;
    }

    Process {
        id: fetchProcess
        command: [Quickshell.shellPath("scripts/weather.sh")]

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();
                if (output === "")
                    return;

                try {
                    root.weatherData = JSON.parse(output);
                    root.lastUpdated = new Date();
                    root.error = "";
                } catch (exception) {
                    root.error = "Invalid weather response";
                }
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0)
                root.error = root.weatherData ? "Could not refresh weather" : "Weather unavailable";
        }
    }

    Timer {
        interval: 1800000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
