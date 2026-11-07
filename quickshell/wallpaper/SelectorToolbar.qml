pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "../components"
import "colors.js" as Colors

// The toolbar above the wallpapers: what is shown, grid or carousel, recent
// picks, a random pick, the color filters and the search.
Rectangle {
    id: bar

    property string label: ""
    property bool grid: false
    property bool recent: false
    property string hue: ""   // color filter, "" for none
    property bool searching: false
    property alias query: field.text
    signal randomPicked
    signal searchDone
    signal browse(int step)

    function focusSearch() {
        searching = true;
        field.forceActiveFocus();
    }

    // The search stays applied (the label shows it); Escape clears it.
    function closeSearch() {
        searching = false;
        searchDone();
    }

    // Every swatch comes from the palette; pink is mixed from its purple.
    function swatch(name) {
        const pink = Qt.hsla(0.92, Theme.purple.hslSaturation, Theme.purple.hslLightness, 1);
        return { red: Theme.red, orange: Theme.orange, yellow: Theme.yellow, green: Theme.green,
                 blue: Theme.blue, purple: Theme.purple, pink: pink, gray: Theme.subtle }[name];
    }

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 48
    radius: 14
    color: Theme.panel

    // Keeps clicks on the toolbar from closing the selector.
    MouseArea {
        anchors.fill: parent
    }

    component Button: Rectangle {
        id: button
        property string icon: ""
        property bool on: false
        signal clicked
        width: 34
        height: 34
        radius: 9
        color: on ? Qt.alpha(Theme.accent, 0.25) : hover.hovered ? Theme.surface : Theme.bgAlt
        Icon {
            anchors.centerIn: parent
            name: button.icon
            color: button.on ? Theme.accent : Theme.fg
            size: 18
        }
        HoverHandler { id: hover }
        TapHandler { onTapped: button.clicked() }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 7

        Rectangle {
            width: Math.max(72, title.implicitWidth + 20)
            height: 34
            radius: 9
            color: Theme.bgAlt
            visible: !bar.searching
            Label {
                id: title
                anchors.centerIn: parent
                text: bar.label
                mono: true
                small: true
                color: Theme.fgBright
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            width: 220
            height: 34
            radius: 9
            color: Theme.surface
            visible: bar.searching
            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.fg
                selectionColor: Theme.accent
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontPixels
                Keys.onEscapePressed: {
                    text = "";
                    bar.searching = false;
                    bar.searchDone();
                }
                Keys.onReturnPressed: bar.closeSearch()
                Keys.onDownPressed: bar.closeSearch()
                // Left and right browse the wallpapers, even while searching.
                Keys.onLeftPressed: bar.browse(-1)
                Keys.onRightPressed: bar.browse(1)
            }
        }

        Button { icon: bar.grid ? "view_carousel" : "grid_view"; onClicked: bar.grid = !bar.grid }
        Button { icon: "history"; on: bar.recent; onClicked: bar.recent = !bar.recent }
        Button { icon: "shuffle"; onClicked: bar.randomPicked() }

        Repeater {
            model: Colors.CLASSES

            Rectangle {
                id: chip
                required property string modelData
                width: 34
                height: 34
                radius: 9
                color: bar.swatch(modelData)
                border.width: bar.hue === modelData ? 2 : 0
                border.color: Theme.fgBright
                TapHandler { onTapped: bar.hue = bar.hue === chip.modelData ? "" : chip.modelData }
            }
        }

        Button { icon: "search"; on: bar.searching; onClicked: bar.searching ? bar.closeSearch() : bar.focusSearch() }
    }
}
