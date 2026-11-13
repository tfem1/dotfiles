import QtQuick
import "../theme"
import "../components"

// A slider for a whole number or a step of `step`, with its value shown.
Row {
    id: setting

    property real low: 0
    property real high: 1
    property real step: 1
    property real current: low
    property string unit: ""
    signal picked(real value)

    spacing: 12

    Slider {
        anchors.verticalCenter: parent.verticalCenter
        width: 220
        value: (setting.current - setting.low) / (setting.high - setting.low)
        onMoved: fraction => setting.picked(Math.round((setting.low + fraction * (setting.high - setting.low))
                                                       / setting.step) * setting.step)
    }
    Label {
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        text: setting.unit === "%" ? Math.round(setting.current * 100) + " %" : setting.current + setting.unit
        horizontalAlignment: Text.AlignRight
    }
}
