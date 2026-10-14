import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    implicitHeight: Theme.barHeight - 6
    implicitWidth: rowLayout.implicitWidth

    property int cpuUsage: 0
    property int cpuTemp: 0
    property int memUsage: 0
    property int diskUsage: 0

    // Fetch stats and temp via Process
    Process {
        id: statsProcess
        command: [
            "bash", "-c",
            "read -r _ u n s i io irq sirq st _ < /proc/stat; sleep 0.15; read -r _ u2 n2 s2 i2 io2 irq2 sirq2 st2 _ < /proc/stat; idle=$(( (i2+io2) - (i+io) )); total=$(( (u2+n2+s2+i2+io2+irq2+sirq2+st2) - (u+n+s+i+io+irq+sirq+st) )); cpu=$(( total > 0 ? 100 * (total - idle) / total : 0 )); temp=0; for h in /sys/class/hwmon/hwmon*; do name=$(cat \"$h/name\" 2>/dev/null); if [ \"$name\" = \"k10temp\" ] || [ \"$name\" = \"coretemp\" ] || [ \"$name\" = \"cpu_thermal\" ]; then if [ -f \"$h/temp1_input\" ]; then temp=$(( $(cat \"$h/temp1_input\") / 1000 )); break; fi; fi; done; if [ \"$temp\" -eq 0 ]; then for tz in /sys/class/thermal/thermal_zone*/temp; do if [ -f \"$tz\" ]; then temp=$(( $(cat \"$tz\") / 1000 )); break; fi; done; fi; mem=$(free -m | awk '/Mem:/ {printf \"%d\", ($3/$2)*100}'); disk=$(df / | awk 'NR==2 {print $5}' | tr -d '%'); echo \"$cpu $temp $mem $disk\""
        ]
        
        stdout: SplitParser {
            onRead: data => {
                var parts = data.trim().split(/\s+/);
                if (parts.length >= 4) {
                    root.cpuUsage = parseInt(parts[0]) || 0;
                    root.cpuTemp = parseInt(parts[1]) || 0;
                    root.memUsage = parseInt(parts[2]) || 0;
                    root.diskUsage = parseInt(parts[3]) || 0;
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!statsProcess.running) {
                statsProcess.running = true;
            }
        }
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 5

        // CPU & Temp Pill
        Rectangle {
            implicitHeight: root.implicitHeight
            implicitWidth: cpuContent.implicitWidth + 12
            radius: Theme.pillRadius
            color: Theme.moduleBg
            border.color: (root.cpuUsage > 85 || root.cpuTemp > 80) ? Theme.accentDanger : ((root.cpuUsage > 60 || root.cpuTemp > 70) ? Theme.accentWarning : Theme.moduleBorder)
            border.width: 1

            RowLayout {
                id: cpuContent
                anchors.centerIn: parent
                spacing: 4

                // CPU Load
                RowLayout {
                    spacing: 3
                    Text {
                        text: ""
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.iconSize
                        color: root.cpuUsage > 85 ? Theme.accentDanger : (root.cpuUsage > 60 ? Theme.accentWarning : Theme.accentCyan)
                    }

                    Text {
                        text: root.cpuUsage + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        color: Theme.textPrimary
                    }
                }

                // Separator Dot
                Rectangle {
                    implicitWidth: 3
                    implicitHeight: 3
                    radius: 1.5
                    color: Theme.textMuted
                    visible: root.cpuTemp > 0
                }

                // CPU Temperature
                RowLayout {
                    spacing: 2
                    visible: root.cpuTemp > 0

                    Text {
                        text: "󰔏"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        color: root.cpuTemp > 80 ? Theme.accentDanger : (root.cpuTemp > 70 ? Theme.accentWarning : Theme.accentCyan)
                    }

                    Text {
                        text: root.cpuTemp + "°C"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        color: root.cpuTemp > 80 ? Theme.accentDanger : (root.cpuTemp > 70 ? Theme.accentWarning : Theme.textSecondary)
                    }
                }
            }
        }

        // Memory Pill
        Rectangle {
            implicitHeight: root.implicitHeight
            implicitWidth: memContent.implicitWidth + 12
            radius: Theme.pillRadius
            color: Theme.moduleBg
            border.color: root.memUsage > 85 ? Theme.accentDanger : (root.memUsage > 70 ? Theme.accentWarning : Theme.moduleBorder)
            border.width: 1

            RowLayout {
                id: memContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰘚"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.iconSize
                    color: root.memUsage > 85 ? Theme.accentDanger : (root.memUsage > 70 ? Theme.accentWarning : Theme.accentOrange)
                }

                Text {
                    text: root.memUsage + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    color: Theme.textPrimary
                }
            }
        }

        // Storage / Disk Pill
        Rectangle {
            implicitHeight: root.implicitHeight
            implicitWidth: diskContent.implicitWidth + 12
            radius: Theme.pillRadius
            color: Theme.moduleBg
            border.color: root.diskUsage > 90 ? Theme.accentDanger : Theme.moduleBorder
            border.width: 1

            RowLayout {
                id: diskContent
                anchors.centerIn: parent
                spacing: 4

                Text {
                    text: "󰋊"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.iconSize
                    color: root.diskUsage > 90 ? Theme.accentDanger : Theme.accentSecondary
                }

                Text {
                    text: root.diskUsage + "%"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    color: Theme.textPrimary
                }
            }
        }
    }
}
