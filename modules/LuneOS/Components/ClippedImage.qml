import QtQuick 2.0

Item {
    id: clippingItem

    // url of the original image
    property alias source: clippedImage.source
    // size of the original image
    property size imageSize
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
                width: imageSize.width/patchGridSize.width
                height: imageSize.height/patchGridSize.height
            }
        },
        State {
            when: wantedWidth > 0 && wantedHeight <= 0
            PropertyChanges {
                target: clippingItem
                width: wantedWidth
                height: width * (imageSize.height/imageSize.width) / patchGridSize.height
            }
        },
        State {
            when: wantedWidth <= 0 && wantedHeight > 0
            PropertyChanges {
                target: clippingItem
                width: height * (imageSize.width/imageSize.height) / patchGridSize.width
                height: wantedHeight
            }
        }
    ]

    QtObject {
        id: internal
        property size patchSize: Qt.size(imageSize.width/patchGridSize.width, imageSize.height/patchGridSize.height);
        property real scalingX: clippingItem.width / patchSize.width;
        property real scalingY: clippingItem.height / patchSize.height;
    }

    clip: true

    Image {
        id: clippedImage

        width: clippingItem.imageSize.width * internal.scalingX
        height: clippingItem.imageSize.height * internal.scalingY

        x: -1 * patch.x * internal.patchSize.width * internal.scalingX
        y: -1 * patch.y * internal.patchSize.height * internal.scalingY

        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        fillMode: Image.Stretch
    }
}
