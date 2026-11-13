import QtQuick
import QtQuick.Particles
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import "."
import "Ledges.js" as Ledges

PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "omarchy-snow"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    readonly property var monitor: Hyprland.monitorFor(screen)
    property var ledges: []
    property real age: 0
    property var deposits: ({})
    readonly property bool moving: !Style.reduceMotion

    function refreshLedges() {
        if (!monitor) { ledges = []; return }
        var windows = Hyprland.toplevels.values.map(t => t.lastIpcObject)
        ledges = Ledges.visibleLedges(windows, monitor.lastIpcObject, width, height)
    }
    Component.onCompleted: { Hyprland.refreshToplevels(); refreshLedges() }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!geometryRefresh.running) geometryRefresh.start()
        }
    }
    Timer {
        id: geometryRefresh
        interval: 100
        onTriggered: { Hyprland.refreshToplevels(); root.refreshLedges(); settleRefresh.restart() }
    }
    Timer { id: settleRefresh; interval: 80; onTriggered: root.refreshLedges() }
    onWidthChanged: refreshLedges()
    onHeightChanged: refreshLedges()

    Item {
        anchors.fill: parent
        opacity: SnowState.strength
        ParticleSystem { id: snow; anchors.fill: parent; paused: !root.moving }
        Emitter {
            startTime: 30000
            system: snow; group: "distant"
            x: -80; y: -16; width: root.width + 160
            emitRate: Math.min(9, root.width / 240)
            maximumEmitted: 240
            lifeSpan: Math.min(120000, (root.height + 70) / 24 * 1000)
            size: 3; sizeVariation: 1.2; endSize: 3
            velocity: AngleDirection { angle: 83; angleVariation: 10; magnitude: 24; magnitudeVariation: 4 }
        }
        Emitter {
            startTime: 30000
            system: snow; group: "middle"
            x: -120; y: -16; width: root.width + 240
            emitRate: Math.min(7, root.width / 310)
            maximumEmitted: 180
            lifeSpan: Math.min(100000, (root.height + 70) / 43 * 1000)
            size: 5; sizeVariation: 2; endSize: 5
            velocity: AngleDirection { angle: 81; angleVariation: 12; magnitude: 43; magnitudeVariation: 7 }
        }
        Emitter {
            startTime: 30000
            system: snow; group: "near"
            x: -160; y: -20; width: root.width + 320
            emitRate: Math.min(3, root.width / 800)
            maximumEmitted: 70
            lifeSpan: Math.min(80000, (root.height + 90) / 66 * 1000)
            size: 9; sizeVariation: 3; endSize: 9
            velocity: AngleDirection { angle: 79; angleVariation: 9; magnitude: 66; magnitudeVariation: 10 }
        }
        ImageParticle { system: snow; groups: ["distant"]; source: "assets/soft.svg"; opacity: 0.38; entryEffect: ImageParticle.Fade }
        ImageParticle { system: snow; groups: ["middle"]; source: "assets/soft.svg"; opacity: 0.72; entryEffect: ImageParticle.Fade }
        ImageParticle {
            system: snow; groups: ["near"]; source: "assets/flake.svg"; opacity: 0.7
            rotationVariation: 180; rotationVelocity: 9; rotationVelocityVariation: 16
            entryEffect: ImageParticle.Fade
        }
        Wander { system: snow; groups: ["distant", "middle", "near"]; anchors.fill: parent; xVariance: 13; yVariance: 3; pace: 0.22 }

        Canvas {
            id: banks
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var next = {}
                for (var i = 0; i < root.ledges.length; i++) {
                    var edge = root.ledges[i]
                    var deposited = root.deposits[edge.key] || 0
                    deposited = Math.min(1, deposited + 0.25 / 65)
                    next[edge.key] = deposited
                    Ledges.paintBank(ctx, edge, deposited)
                }
                root.deposits = next
                Ledges.paintBank(ctx, {x: 0, y: height, width: width, kind: "floor", seed: 9}, Math.min(1, root.age / 90))
            }
        }
        Timer {
            interval: 250; repeat: true; running: root.moving && SnowState.enabled
            onTriggered: { root.age += 0.25; banks.requestPaint() }
        }
    }
}
