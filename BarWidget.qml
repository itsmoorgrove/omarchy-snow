pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui as Ui
import "."

Ui.BarWidget {
    id: root
    moduleName: "local.snow"
    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    property bool settingsOpen: false
    readonly property bool opened: settingsOpen
    function open() { settingsOpen = true }
    function close() { settingsOpen = false }
    function toggle() { settingsOpen = !settingsOpen }
    function closeForPopoutSwitch() { close() }
    function setAutomatic(value) {
        var next = Object.assign({}, root.settings, {automatic: value})
        if (root.bar && root.bar.shell && root.bar.shell.updateEntryInline(root.moduleName, next))
            SnowState.automatic = value
    }
    function toggleSnow() {
        var next = !SnowState.enabled
        if (SnowState.automatic) setAutomatic(false)
        SnowState.enabled = next
    }
    onSettingsChanged: SnowState.automatic = setting("automatic", false) === true
    Component.onCompleted: SnowState.automatic = setting("automatic", false) === true

    Translations { id: strings; directory: Qt.resolvedUrl("i18n") }
    Ui.BarIconButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: "❄"
        active: SnowState.enabled || SnowState.automatic
        activeColor: "#b8e4f5"
        tooltipText: strings.t("snow.hint")
        onPressed: b => {
            if (b === Qt.LeftButton) root.toggleSnow()
            else if (b === Qt.RightButton) root.toggle()
        }
    }
    SettingsPanel {
        anchorItem: button
        bar: root.bar
        owner: root
        open: root.settingsOpen
        onAutomaticRequested: value => root.setAutomatic(value)
        onSnowRequested: root.toggleSnow()
    }
    Loader {
        active: SnowState.strength > 0 && root.bar !== null
        sourceComponent: SnowSurface { screen: root.QsWindow.window ? root.QsWindow.window.screen : null }
    }
}
