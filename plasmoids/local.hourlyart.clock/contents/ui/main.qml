import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property date now: new Date()

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 6
        Layout.minimumHeight: Kirigami.Units.gridUnit * 4

        Rectangle {
            // Same box as the artwork caption, mirrored to the bottom-right corner
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: column.implicitWidth + Kirigami.Units.largeSpacing * 2
            height: column.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(0, 0, 0, 0.55)

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: 0

                Text {
                    Layout.alignment: Qt.AlignRight
                    text: Qt.formatTime(root.now, Qt.locale().timeFormat(Locale.ShortFormat))
                    color: "white"
                    font.pixelSize: 72
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: Qt.formatDate(root.now, Qt.locale().dateFormat(Locale.ShortFormat))
                    color: Qt.rgba(1, 1, 1, 0.8)
                    font.pixelSize: 36
                }
            }
        }
    }
}
