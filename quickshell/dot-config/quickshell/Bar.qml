import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "./components"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window
            required property var modelData

            screen: modelData
            implicitHeight: Theme.barHeight + 4
            color: "transparent"

            anchors {
                top: true
                left: true
                right: true
            }

            margins {
                top: 3
                left: 4
                right: 4
            }

            Rectangle {
                id: barContainer
                anchors.fill: parent
                radius: Theme.pillRadius + 2
                color: Theme.barBg
                border.color: Theme.barBorder
                border.width: 1

                // Left Items: Workspaces & Media
                RowLayout {
                    id: leftSection
                    anchors.left: parent.left
                    anchors.leftMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Workspaces {}
                    TrayWidget {
                        parentWindow: window
                    }
                    MediaWidget {}
                }

                // Center Items: Clock & Date (with Calendar dropdown)
                ClockWidget {
                    id: centerSection
                    parentWindow: window
                    anchors.centerIn: parent
                }

                // Right Items: Tray, SysMonitor, Battery, Network (with Wi-Fi selector), Notifications
                RowLayout {
                    id: rightSection
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                   
                    SysMonitor {}
                    BatteryWidget {}
                    NetworkWidget {
                        parentWindow: window
                    }
                    NotificationWidget {}
                }
            }
        }
    }
}
