pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Weather.js" as Weather

Item {
    id: state
    property bool enabled: false
    property bool automatic: false
    property real strength: enabled ? 1 : 0
    property var location: null
    property string status: "manual"
    property double lastGood: 0
    property string requestLocation: ""
    readonly property string locationKey: location ? location.latitude + "," + location.longitude : ""
    readonly property bool busy: request.running

    Behavior on strength {
        NumberAnimation { duration: Style.duration(state.enabled ? 180 : 120); easing.type: Easing.OutCubic }
    }

    onAutomaticChanged: {
        request.running = false
        lastGood = 0
        enabled = false
        status = automatic ? "waiting" : "manual"
        if (automatic) refresh()
    }
    onLocationKeyChanged: {
        request.running = false
        lastGood = 0
        if (automatic) { enabled = false; refresh() }
    }

    function refresh() {
        if (!automatic || request.running) return
        if (!location) { status = "location"; enabled = false; return }
        status = "checking"
        requestLocation = locationKey
        request.command = ["curl", "--disable", "--fail", "--silent", "--show-error",
            "--proto", "=https", "--connect-timeout", "4", "--max-time", "8",
            "--max-filesize", "16384", "--url",
            "https://api.open-meteo.com/v1/forecast?latitude=" + encodeURIComponent(String(location.latitude))
            + "&longitude=" + encodeURIComponent(String(location.longitude))
            + "&current=weather_code&timeformat=unixtime&timezone=GMT&forecast_days=1"]
        request.running = true
    }
    function accept(raw, exitCode) {
        if (!automatic || requestLocation !== locationKey) return
        var now = Date.now() / 1000
        var report = exitCode === 0 ? Weather.current(raw, now) : null
        if (!report) {
            status = "error"
            if (!lastGood || now - lastGood > 5400) enabled = false
            return
        }
        lastGood = report.time
        enabled = report.snow
        status = report.snow ? "snowing" : "clear"
    }

    FileView {
        id: weatherLocation
        path: Quickshell.env("HOME") + "/.local/state/omarchy/settings/weather.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: state.location = Weather.location(text())
        onLoadFailed: state.location = null
    }
    Process {
        id: request
        stdout: StdioCollector { waitForEnd: true }
        onExited: (exitCode, exitStatus) => state.accept(stdout.text, exitCode)
    }
    Timer { interval: 600000; repeat: true; running: state.automatic; onTriggered: state.refresh() }
    Timer {
        interval: 60000; repeat: true; running: state.automatic
        onTriggered: {
            if (state.lastGood && Date.now() / 1000 - state.lastGood > 5400) {
                state.enabled = false
                state.status = "error"
            }
        }
    }
}
