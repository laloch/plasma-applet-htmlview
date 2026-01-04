import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Dialogs as QQD
import QtQuick.Layouts 
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_url: urlSrcText.text
    property alias cfg_file: localSrcText.text
    property alias cfg_islocal: localSrcRadioButton.checked
    property int cfg_interval
    property bool cfg_allowInsecure
    property bool cfg_allowRemoteAccess
    property bool cfg_ignoreCertificateErrors

    Kirigami.FormLayout {
        id: root
        Layout.fillWidth: true

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Content Source")
        }

        QQC2.ButtonGroup {
            id: radioGroup
        }

        Component.onCompleted: {
            urlSrcRadioButton.checked = !localSrcRadioButton.checked
        }

        RowLayout {
            id: urlRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:radiobutton", "Remote URL:")

            QQC2.RadioButton {
                id: urlSrcRadioButton
                QQC2.ButtonGroup.group: radioGroup
            }
            QQC2.TextField {
                id: urlSrcText
                Layout.fillWidth: true
                enabled: urlSrcRadioButton.checked
                placeholderText: "https://www.example.com/alieninvasion"
            }
        }
        RowLayout {
            id: fileRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:radiobutton", "Local file:")
            QQC2.RadioButton {
                id: localSrcRadioButton
                QQC2.ButtonGroup.group: radioGroup
            }
            QQC2.TextField {
                id: localSrcText
                Layout.fillWidth: true
                enabled: localSrcRadioButton.checked
                placeholderText: "~/Documetnts/RoswellCatWitness.html"
            }
            QQC2.Button {
                enabled: localSrcRadioButton.checked
                icon.name: "document-open"
                onClicked: fileDialogLoader.active = true

                Loader {
                    id: fileDialogLoader
                    active: false

                    sourceComponent: QQD.FileDialog {
                        id: fileDialog
                        title: i18nc("@title:window", "Choose a Content File")
                        currentFolder: shortcuts.documents
                        nameFilters: [
                            i18n("HTML files (*.html *.htm *.xhtml)"),
                            i18n("Image Files (*.png *.jpg *.jpeg *.bmp *.svg *.svgz)"),
                            i18n("All files (*)"),
                        ]
                        onAccepted: {
                            localSrcText.text = selectedFile.toString().replace("file://", "")
                            fileDialogLoader.active = false
                        }
                        onRejected: {
                            fileDialogLoader.active = false
                        }
                        Component.onCompleted: open()
                    }
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Automatic Refresh")
        }

        RowLayout {
            id: refreshRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:combobox After X minutes", "Forced refresh interval:")

            TimeDurationComboBox {
                Layout.fillWidth: true

                durationPromptAcceptsUnits: [DurationPromptDialog.Unit.Seconds, DurationPromptDialog.Unit.Minutes]
                durationPromptLabel: i18nc("@label:spinbox After X minutes", "Refresh page after:")

                function translateSeconds(n, formatUnit = DurationPromptDialog.Unit.Seconds) {
                    return formatUnit == DurationPromptDialog.Unit.Minutes
                        ? translateMinutes(n / 60) : i18ncp("@option:combobox", "%1 second", "%1 seconds", n);
                }
                function translateMinutes(n) {
                    return i18ncp("@option:combobox", "%1 minute", "%1 minutes", n);
                }
                valueRole: "seconds"
                textRole: "text"
                unitOfValueRole: DurationPromptDialog.Unit.Seconds
                durationPromptFromValue: 1
                presetOptions: [
                    { seconds: -1, text: i18nc("@option:combobox", "Never") },
                    { seconds: 1 * 60, text: translateMinutes(1), unit: DurationPromptDialog.Unit.Minutes },
                    { seconds: 5 * 60, text: translateMinutes(5), unit: DurationPromptDialog.Unit.Minutes },
                    { seconds: 10 * 60, text: translateMinutes(10), unit: DurationPromptDialog.Unit.Minutes },
                    { seconds: 15 * 60, text: translateMinutes(15), unit: DurationPromptDialog.Unit.Minutes },
                    { seconds: 30 * 60, text: translateMinutes(30), unit: DurationPromptDialog.Unit.Minutes },
                    { seconds: 60 * 60, text: translateMinutes(60), unit: DurationPromptDialog.Unit.Minutes },
                    { seconds: -2, text: i18nc("@option:combobox", "Custom…") },
                ]
                customRequesterValue: -2
                configuredValue: cfg_interval
                configuredDisplayUnit: model[indexOfValue(configuredValue)]?.unit ?? DurationPromptDialog.Unit.Minutes

                onRegularValueActivated: {
                    cfg_interval = currentValue;
                }
                onCustomDurationAccepted: {
                    cfg_interval = valueToUnit(customDuration.value, customDuration.unit, DurationPromptDialog.Unit.Seconds);
                }

                onConfiguredValueOptionMissing: {
                    const unit = configuredValue % 60 === 0
                        ? customDuration?.unit ?? DurationPromptDialog.Unit.Minutes
                        : DurationPromptDialog.Unit.Seconds;

                    customOptions = [{
                        seconds: configuredValue,
                        text: translateSeconds(configuredValue, unit),
                        unit: unit,
                    }];
                    customDuration = null;
                }
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Security")
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18nc("@label:checkbox", "Mixed Content:")
            text: i18nc("@option:check", "Allow running insecure content")
            checked: cfg_allowInsecure
            onToggled: cfg_allowInsecure = checked
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18nc("@label:checkbox", "Access Control:")
            text: i18nc("@option:check", "Allow local files to access remote URLs")
            checked: cfg_allowRemoteAccess
            onToggled: cfg_allowRemoteAccess = checked
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18nc("@label:checkbox", "Certificate Errors:")
            text: i18nc("@option:check", "Ignore SSL/TLS certificate errors")
            checked: cfg_ignoreCertificateErrors
            onToggled: cfg_ignoreCertificateErrors = checked
        }
    }
}
