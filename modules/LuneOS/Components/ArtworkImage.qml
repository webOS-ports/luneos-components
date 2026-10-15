import QtQuick

/*
 * An Image of SVG artwork that is sharp at any size and quick to load: the SVG
 * is drawn once at the size the item is shown, on a worker thread, and kept as
 * PNG for the next time (image://artwork, see the plugin's ArtworkCache).
 *
 *     ArtworkImage { svg: Qt.resolvedUrl("images/shutter.svg"); width: Units.gu(10); height: width }
 *
 * Give "svg" as an absolute URL: Qt.resolvedUrl() in the file the artwork sits
 * beside. Qt 6 does not resolve a relative url where it is assigned, so a bare
 * "images/shutter.svg" would mean nothing here; it is refused, with a warning.
 */
Image {
    id: artworkImage

    /// The SVG, as an absolute file: URL (Qt.resolvedUrl()) or path.
    property url svg

    // The SVG's local path: a file: URL's prefix dropped and its escapes undone.
    readonly property string _path: decodeURIComponent(svg.toString().replace(/^file:\/\//, ""))

    source: _path.charAt(0) === "/" ? "image://artwork/" + encodeURIComponent(_path) : ""
    on_PathChanged: if (_path !== "" && _path.charAt(0) !== "/")
                        console.warn("ArtworkImage: give svg as Qt.resolvedUrl(\"" + _path + "\"), not a relative path")
    sourceSize: Qt.size(Math.ceil(width), Math.ceil(height))
    // Keeps showing the old picture until a new one is ready, instead of a gap.
    retainWhileLoading: true
}
