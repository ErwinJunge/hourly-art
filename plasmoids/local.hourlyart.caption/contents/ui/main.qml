import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string command: "cat \"$HOME/.cache/hourly-art/current.txt\""
    property string title: ""
    property string credit: ""

    preferredRepresentation: fullRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground

    P5Support.DataSource {
        id: reader
        engine: "executable"
        onNewData: (source, data) => {
            const text = (data.stdout || "").trim()
            const sep = text.indexOf(" — ")
            root.title = sep >= 0 ? text.slice(0, sep) : text
            root.credit = sep >= 0 ? text.slice(sep + 3) : ""
            disconnectSource(source)
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: reader.connectSource(root.command)
    }

    fullRepresentation: Item {
        Layout.minimumWidth: Kirigami.Units.gridUnit * 10
        Layout.minimumHeight: Kirigami.Units.gridUnit * 3

        Rectangle {
            visible: root.title !== ""
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            width: Math.min(parent.width, column.implicitWidth + Kirigami.Units.largeSpacing * 2)
            height: column.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: Kirigami.Units.cornerRadius
            color: Qt.rgba(0, 0, 0, 0.55)

            ColumnLayout {
                id: column
                anchors.fill: parent
                anchors.margins: Kirigami.Units.largeSpacing
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: "white"
                    font.italic: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.3
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.credit !== ""
                    text: root.credit
                    color: Qt.rgba(1, 1, 1, 0.8)
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize
                    elide: Text.ElideRight
                }
            }
        }
    }
}
