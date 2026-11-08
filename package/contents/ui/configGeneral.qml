import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Layouts 1.15
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: configPage

    property alias cfg_pollIntervalSeconds: pollIntervalSpinBox.value
    property alias cfg_showCursor: showCursorCheck.checked
    property alias cfg_showClaude: showClaudeCheck.checked
    property alias cfg_showCodex: showCodexCheck.checked
    property alias cfg_helperPath: helperPathField.text
    // displayMode is a string in main.xml. Plasma passes every cfg_ value as an
    // initial property when it creates this page, so aliasing it to an int
    // (ComboBox.currentIndex) made the whole page fail to construct.
    property string cfg_displayMode: "remaining"

    QQC2.SpinBox {
        id: pollIntervalSpinBox

        Kirigami.FormData.label: i18n("Poll interval (seconds):")
        from: 10
        to: 3600
        stepSize: 10
    }

    QQC2.CheckBox {
        id: showCursorCheck

        Kirigami.FormData.label: i18n("Providers:")
        text: i18n("Show Cursor")
    }

    QQC2.CheckBox {
        id: showClaudeCheck

        text: i18n("Show Claude")
    }

    QQC2.CheckBox {
        id: showCodexCheck

        text: i18n("Show Codex")
    }

    QQC2.ComboBox {
        id: displayModeCombo

        Kirigami.FormData.label: i18n("Display mode:")
        textRole: "text"
        valueRole: "value"
        model: [{
            "value": "remaining",
            "text": i18n("Remaining (drains down)")
        }, {
            "value": "usage",
            "text": i18n("Usage (fills up)")
        }]
        onActivated: configPage.cfg_displayMode = currentValue
        Component.onCompleted: {
            var idx = indexOfValue(configPage.cfg_displayMode);
            currentIndex = idx >= 0 ? idx : 0;
        }
    }

    QQC2.TextField {
        id: helperPathField

        Kirigami.FormData.label: i18n("Helper binary path (leave empty for default):")
        placeholderText: "~/.local/share/token-juice/token-juice-helper"
    }

}
