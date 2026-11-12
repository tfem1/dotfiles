pragma ComponentBehavior: Bound
import QtQuick
import "../theme"
import "library.js" as Library

// The wallpapers as a row of slanted cards: the current one large in the
// middle, the others narrower and shorter the farther they are.
// `model` is [{ path, name, category, thumb }] (thumb: a small copy, or "").
ListView {
    id: carousel

    property string activePath: ""
    property int bigWidth: 600
    property int smallWidth: 150
    signal picked(int index)

    orientation: ListView.Horizontal
    spacing: 8
    clip: false
    highlightRangeMode: ListView.StrictlyEnforceRange
    preferredHighlightBegin: (width - bigWidth) / 2
    preferredHighlightEnd: (width + bigWidth) / 2
    highlightMoveDuration: Theme.duration * 2
    cacheBuffer: smallWidth * 4
    boundsBehavior: Flickable.StopAtBounds

    // The wheel steps one wallpaper at a time.
    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y < 0 || event.angleDelta.x < 0)
                carousel.incrementCurrentIndex();
            else
                carousel.decrementCurrentIndex();
        }
    }

    // ListView places its delegates at the top: the card is centered
    // inside a delegate as tall as the view.
    delegate: Item {
        id: slot

        required property var modelData
        required property int index
        readonly property int distance: Math.abs(index - carousel.currentIndex)

        width: distance === 0 ? carousel.bigWidth : carousel.smallWidth
        height: carousel.height
        Behavior on width { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }

        SlantedCard {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: carousel.height * (slot.distance === 0 ? 1 : Math.max(0.5, 0.86 - 0.07 * (slot.distance - 1)))
            opacity: slot.distance > 5 ? 0.4 : 1
            source: Library.fileUrl(slot.modelData.thumb || slot.modelData.path)
            active: slot.modelData.path === carousel.activePath
            onClicked: {
                if (slot.distance === 0)
                    carousel.picked(slot.index);
                else
                    carousel.currentIndex = slot.index;
            }

            Behavior on height { NumberAnimation { duration: Theme.duration; easing.type: Easing.OutCubic } }
        }
    }
}
