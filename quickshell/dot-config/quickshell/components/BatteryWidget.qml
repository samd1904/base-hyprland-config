import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    property int capacity: 100
    property string status: "Full"
    property bool isAcOnline: true
    property bool hasBattery: true

    visible: hasBattery
    implicitHeight: Theme.barHeight - 6
    implicitWidth: batRow.implicitWidth + 14
    radius: Theme.pillRadius
    color: batMouse.containsMouse ? Theme.moduleBgHover : Theme.moduleBg
    border.color: (capacity <= 15 && !isAcOnline) ? Theme.accentDanger : (batMouse.containsMouse ? Theme.accentSecondary : Theme.moduleBorder)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    readonly property bool isCharging: status === "Charging" || (isAcOnline && capacity < 100 && status !== "Discharging")
    readonly property bool isFull: status === "Full" || capacity >= 100

    readonly property color batteryColor: {
        if (isCharging || (isFull && isAcOnline)) return Theme.accentSuccess;
        if (capacity <= 15) return Theme.accentDanger;
        if (capacity <= 30) return Theme.accentWarning;
        return Theme.accentCyan;
    }

    readonly property string batteryIcon: {
        if (isCharging) return "󰂄";
        if (isFull && isAcOnline) return "󰂅";
        if (capacity >= 95) return "󰁹";
        if (capacity >= 85) return "󰂂";
        if (capacity >= 75) return "󰂁";
        if (capacity >= 65) return "󰂀";
        if (capacity >= 55) return "󰁿";
        if (capacity >= 45) return "󰁾";
        if (capacity >= 35) return "󰁽";
        if (capacity >= 25) return "󰁼";
        if (capacity >= 15) return "󰁻";
        return "󰁺";
    }

    Process {
        id: batProcess
        command: [
            "bash", "-c",
            "cap=100; stat='Full'; ac=1; has_bat=0; for b in /sys/class/power_supply/BAT*; do if [ -d \"$b\" ] && [ -f \"$b/capacity\" ]; then cap=$(cat \"$b/capacity\" 2>/dev/null || echo 100); stat=$(cat \"$b/status\" 2>/dev/null || echo 'Unknown'); has_bat=1; break; fi; done; for a in /sys/class/power_supply/AC* /sys/class/power_supply/ADP*; do if [ -d \"$a\" ] && [ -f \"$a/online\" ]; then ac=$(cat \"$a/online\" 2>/dev/null || echo 0); break; fi; done; echo \"$has_bat $cap $stat $ac\""
        ]

        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/);
                if (parts.length >= 4) {
                    root.hasBattery = parts[0] === "1";
                    root.capacity = parseInt(parts[1]) || 0;
                    root.status = parts[2];
                    root.isAcOnline = parts[3] === "1";
                }
            }
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!batProcess.running) {
                batProcess.running = true;
            }
        }
    }

    RowLayout {
        id: batRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            id: iconText
            text: root.batteryIcon
            font.family: Theme.fontFamily
            font.pixelSize: Theme.iconSize
            color: root.batteryColor
        }

        Text {
            id: labelText
            text: root.capacity + "%"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            font.bold: true
            color: Theme.textPrimary
        }
    }

    MouseArea {
        id: batMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}
