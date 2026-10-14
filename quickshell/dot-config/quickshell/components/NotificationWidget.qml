import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    property int notifCount: 0
    property bool dndActive: false

    implicitHeight: Theme.barHeight - 6
    implicitWidth: notifRow.implicitWidth + 12
    radius: Theme.pillRadius
    color: notifMouse.containsMouse ? Theme.moduleBgHover : Theme.moduleBg
    border.color: notifCount > 0 ? Theme.accentWarning : Theme.moduleBorder
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Process {
        id: countProc
        command: [
            "bash", "-c",
            "if command -v swaync-client >/dev/null 2>&1; then count=$(swaync-client -c 2>/dev/null || echo 0); dnd=$(swaync-client -D 2>/dev/null || echo false); echo \"$count $dnd\"; else echo \"0 false\"; fi"
        ]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/);
                if (parts.length >= 1) {
                    root.notifCount = parseInt(parts[0]) || 0;
                }
                if (parts.length >= 2) {
                    root.dndActive = (parts[1] === "true");
                }
            }
        }
    }

    Process {
        id: toggleProc
        command: ["swaync-client", "-t"]
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!countProc.running) {
                countProc.running = true;
            }
        }
    }

    RowLayout {
        id: notifRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: bellIcon
            text: root.dndActive ? "󰂛" : (root.notifCount > 0 ? "󰂞" : "󰂚")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.iconSize
            color: root.dndActive ? Theme.textMuted : (root.notifCount > 0 ? Theme.accentWarning : Theme.textSecondary)
        }

        // Notification count badge
        Rectangle {
            visible: root.notifCount > 0
            implicitWidth: Math.max(14, countText.implicitWidth + 5)
            implicitHeight: 14
            radius: 7
            color: Theme.accentWarning

            Text {
                id: countText
                anchors.centerIn: parent
                text: root.notifCount > 99 ? "99+" : root.notifCount.toString()
                font.family: Theme.fontFamily
                font.pixelSize: 8
                font.bold: true
                color: "#11111b"
            }
        }
    }

    MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            toggleProc.running = true;
            countProc.running = true;
        }
    }
}
