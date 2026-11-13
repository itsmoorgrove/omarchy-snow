pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Commons as Commons
import qs.Ui as Ui
import "."

Ui.KeyboardPanel {
    id: root
    signal automaticRequested(bool value)
    signal snowRequested()
    contentWidth: fittedContentWidth(Style.space(340))
    contentHeight: fittedContentHeight(content.implicitHeight, Style.space(500))
    focusTarget: content
    property Translations translations: Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: Style.space(16)
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_A) { root.automaticRequested(!SnowState.automatic); event.accepted = true }
            else if (event.key === Qt.Key_Space) { root.snowRequested(); event.accepted = true }
        }
        Text {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: strings.t("settings.title")
            font.family: Style.font.family
            font.pixelSize: Style.font.body + 5
            font.weight: Font.DemiBold
            color: Commons.Color.foreground
        }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: strings.t("settings.snow")
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                color: Commons.Color.foreground
            }
            Ui.ToggleSwitch { checked: SnowState.enabled; onToggled: root.snowRequested() }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Commons.Color.foreground; opacity: 0.12 }
        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                textFormat: Text.PlainText
                text: strings.t("settings.automatic")
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                color: Commons.Color.foreground
            }
            Ui.ToggleSwitch { checked: SnowState.automatic; onToggled: root.automaticRequested(!SnowState.automatic) }
        }
        Text {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: SnowState.location ? strings.t("settings.location").arg(SnowState.location.name) : strings.t("status.location")
            wrapMode: Text.WordWrap
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: "#b8e4f5"
        }
        Text {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: strings.t("status." + SnowState.status)
            wrapMode: Text.WordWrap
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            color: Commons.Color.foreground
            opacity: 0.8
        }
        Text {
            Layout.fillWidth: true
            textFormat: Text.PlainText
            text: strings.t("settings.privacy")
            wrapMode: Text.WordWrap
            font.family: Style.font.family
            font.pixelSize: Style.font.body - 1
            color: Commons.Color.foreground
            opacity: 0.55
        }
        Ui.Button {
            Layout.fillWidth: true
            text: strings.t("settings.refresh")
            enabled: SnowState.automatic && !SnowState.busy
            focusable: true
            onClicked: SnowState.refresh()
        }
    }
}
