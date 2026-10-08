// Photos: the library, grouped by day, each row justified to the window like a contact sheet.
import QtQuick
import QtCore
import Qt.labs.folderlistmodel
import QtQuick.Dialogs
import "../components"

Item {
    id: app
    property var win
    function start(opts) {}
    // real photographs (CC0 / public domain, see assets/CREDITS), with their aspect ratios
    readonly property var days: !Os.demo ? [] : [
        { title: "Today", photos: [["launch-dusk", 1.5], ["espresso", 1.5], ["chelsea", 1.503]] },
        { title: "September 28", photos: [["deep-field", 1.147], ["brick", 1], ["gravel", 1]] }
    ]
    Row {
        x: 92; y: 15; spacing: 10
        Text { id: lib; text: "Library"; color: Theme.text; font.family: Theme.font; font.pixelSize: 15; font.weight: Font.Bold }
        Text { text: (Os.demo ? 6 : pics.count) + " photo" + ((Os.demo ? 6 : pics.count) === 1 ? "" : "s"); color: Theme.text3; font.family: Theme.font; font.pixelSize: 13; anchors.baseline: lib.baseline }
    }
    SearchPill { anchors.right: parent.right; anchors.rightMargin: 12; y: 12 }
    // a real install shows what's in ~/Pictures, newest first, as square crops
    FolderListModel {
        id: pics
        folder: Os.demo ? "" : Os.settings.photosFolder || StandardPaths.writableLocation(StandardPaths.PicturesLocation)
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.JPG", "*.JPEG", "*.PNG", "*.heic"]
        showDirs: false; sortField: FolderListModel.Time
    }
    GridView {
        id: grid
        visible: !Os.demo && pics.count > 0
        x: 14; y: 52; width: parent.width - 28; height: parent.height - y
        readonly property int cols: Math.max(3, Math.floor(width / 180))
        cellWidth: width / cols; cellHeight: cellWidth
        clip: true; boundsBehavior: Flickable.StopAtBounds
        model: pics
        delegate: Image {
            required property url fileUrl
            required property string fileName
            property string aiName: "Photo " + fileName; property string aiRole: "image"
            width: grid.cellWidth - 4; height: grid.cellHeight - 4
            source: fileUrl; sourceSize: Qt.size(360, 360)
            fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
            MouseArea { anchors.fill: parent; onDoubleClicked: Qt.openUrlExternally(parent.fileUrl) }
        }
    }
    EmptyState { visible: !Os.demo && pics.count === 0; glyph: "image"; title: "No photos yet"; hint: "Pictures in your Pictures folder show up here."
                 action: "Choose a folder…"; onActed: chooser.open() }
    FolderDialog { id: chooser; title: "Show photos from"; currentFolder: pics.folder; onAccepted: Os.settings.photosFolder = String(selectedFolder) }
    Flickable {
        id: fl
        x: 14; y: 52; width: parent.width - 28; height: parent.height - y
        contentHeight: col.height + 14
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: col
            width: fl.width
            spacing: 6
            Repeater {
                model: app.days
                Column {
                    id: day
                    required property var modelData
                    readonly property real sum: modelData.photos.reduce(function (s, p) { return s + p[1]; }, 0)
                    readonly property real rowH: Math.min(260, (col.width - 4 * (modelData.photos.length - 1)) / sum)
                    width: col.width; spacing: 8
                    Text { text: day.modelData.title; color: Theme.text; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.DemiBold; topPadding: 6 }
                    Row {
                        spacing: 4
                        Repeater {
                            model: day.modelData.photos
                            Image {
                                required property var modelData
                                property string aiName: "Photo " + modelData[0]
                                property string aiRole: "image"
                                width: Math.round(day.rowH * modelData[1]); height: Math.round(day.rowH)
                                source: "../assets/photos/" + modelData[0] + ".jpg"
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true; smooth: true; mipmap: true
                            }
                        }
                    }
                }
            }
        }
    }
}
