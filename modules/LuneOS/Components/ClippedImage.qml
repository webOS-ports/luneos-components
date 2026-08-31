import QtQuick 2.0

Item {
    id: clippingItem

    // url of the original image
    property alias source: clippedImage.source
    // size of the original image. Leave it unset to take the size the image
    // itself reports: an app whose artwork changes with the theme or the
    // screen density cannot state one size that holds for all of them, and
    // getting it wrong stretches the patch rather than failing outright.
    property size imageSize
    readonly property size effectiveImageSize:
        (imageSize.width > 0 && imageSize.height > 0)
            ? imageSize
            : Qt.size(clippedImage.sourceSize.width, clippedImage.sourceSize.height)
    // size of the grid (number of horizontal patches, number of vertical patches)
    property size patchGridSize
    // current patch coordinates. Numbering begins at 0.
    property point patch
    // constrain the width of the resulting patch image.
    // If zero, the patch image will be scaled w.r.t. the original image proportions and wantedHeight
    property real wantedWidth: 0
    // constrain the height of the resulting patch image.
    // If zero, the patch image will be scaled w.r.t. the original image proportions and wantedWidth
    property real wantedHeight: 0

    // use states for binding properties, so that we don't end having binding loops
    states: [
        State {
            when: wantedWidth > 0 && wantedHeight > 0
            PropertyChanges {
                target: clippingItem
                width: wantedWidth
                height: wantedHeight
            }
        },
        State {
            when: wantedWidth <= 0 && wantedHeight <= 0
            PropertyChanges {
                target: clippingItem
                width: effectiveImageSize.width/patchGridSize.width
                height: effectiveImageSize.height/patchGridSize.height
            }
        },
        State {
            when: wantedWidth > 0 && wantedHeight <= 0
            PropertyChanges {
                target: clippingItem
                width: wantedWidth
                height: width * (effectiveImageSize.height/effectiveImageSize.width) / patchGridSize.height
            }
        },
        State {
            when: wantedWidth <= 0 && wantedHeight > 0
            PropertyChanges {
                target: clippingItem
                width: height * (effectiveImageSize.width/effectiveImageSize.height) / patchGridSize.width
                height: wantedHeight
            }
        }
    ]

    QtObject {
        id: internal
        property size patchSize: Qt.size(effectiveImageSize.width/patchGridSize.width, effectiveImageSize.height/patchGridSize.height);
        property real scalingX: clippingItem.width / patchSize.width;
        property real scalingY: clippingItem.height / patchSize.height;
    }

    clip: true

    Image {
        id: clippedImage

        width: clippingItem.effectiveImageSize.width * internal.scalingX
        height: clippingItem.effectiveImageSize.height * internal.scalingY

        x: -1 * patch.x * internal.patchSize.width * internal.scalingX
        y: -1 * patch.y * internal.patchSize.height * internal.scalingY

        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        fillMode: Image.Stretch
    }
}
