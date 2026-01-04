import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    property int cfg_scale
    property bool cfg_showScrollBars
    property bool cfg_forceTransparent
    property alias cfg_background: radioGroup.bgType

    Kirigami.FormLayout {
        id: root
        Layout.fillWidth: true

        function formatPercentageText(value) {
            return i18nc(
                "Percentage value example, used for formatting brightness levels in the power management settings",
                "10%"
            ).replace("10", value);
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: i18nc("@title:group", "Background Style")
        }
        QQC2.ButtonGroup {
            id: radioGroup
            property int bgType
            onClicked: bgType = button.bgType
        }
        Component.onCompleted: {
            for (const [idx, btn] of radioGroup.buttons.entries()) {
                if (btn.bgType === cfg_background) {
                    radioGroup.checkedButton = btn;
                    break;
                }
            }
        }
        RowLayout {
            id: bgStandardRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:radiobutton", "Standard")
            QQC2.RadioButton {
                id: bgStandardRadioButton
                readonly property int bgType: PlasmaCore.Types.StandardBackground
                QQC2.ButtonGroup.group: radioGroup
            }
        }
        RowLayout {
            id: bgTranslucentRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:radiobutton", "Translucent")
            QQC2.RadioButton {
                id: bgTranslucentRadioButton
                readonly property int bgType: PlasmaCore.Types.TranslucentBackground
                QQC2.ButtonGroup.group: radioGroup
            }
        }
        RowLayout {
            id: bgShadowRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:radiobutton", "Shadow")
            QQC2.RadioButton {
                id: bgShadowRadioButton
                readonly property int bgType: PlasmaCore.Types.ShadowBackground
                QQC2.ButtonGroup.group: radioGroup
            }
        }
        RowLayout {
            id: bgTransparentRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:radiobutton", "Transparent")
            QQC2.RadioButton {
                id: bgTransparentRadioButton
                readonly property int bgType: PlasmaCore.Types.NoBackground
                QQC2.ButtonGroup.group: radioGroup
            }
        }
        RowLayout {
            id: scaleRow
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nc("@label:slider", "Scale:")

            QQC2.Slider {
                id: scaleSlider
                Layout.fillWidth: true
                stepSize: 5
                from: 25
                to: 500
                value: cfg_scale
                onMoved: { cfg_scale = value; }
            }
            QQC2.Label {
                text: root.formatPercentageText(scaleSlider.value)
                Layout.preferredWidth: scalePercentageMetrics.width
            }
            TextMetrics {
                id: scalePercentageMetrics
                text: root.formatPercentageText(100)
            }
        }
        
        QQC2.CheckBox {
            id: showScrollBarsCheckBox
            Kirigami.FormData.label: i18nc("@label:checkbox", "Scrollbars:")
            text: i18nc("@option:check", "Show scrollbars")
            checked: cfg_showScrollBars
            onToggled: cfg_showScrollBars = checked
        }

        QQC2.CheckBox {
            Kirigami.FormData.label: i18nc("@label:checkbox", "Transparency:")
            text: i18nc("@option:check", "Force transparent background")
            checked: cfg_forceTransparent
            onToggled: cfg_forceTransparent = checked
        }
    }
}
