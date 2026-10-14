import QtQuick
import QtQuick.Layouts
import Quickshell
import ".."

Rectangle {
    id: root

    property var parentWindow: null
    property bool showCalendar: false

    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    readonly property var monthNames: [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ]
    readonly property var dayHeaders: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

    implicitHeight: Theme.barHeight - 6
    implicitWidth: timeRow.implicitWidth + 14
    radius: Theme.pillRadius
    color: showCalendar ? Theme.moduleBgHover : (clockMouse.containsMouse ? Theme.moduleBgHover : Theme.moduleBg)
    border.color: showCalendar ? Theme.accentPrimary : (clockMouse.containsMouse ? Theme.accentSecondary : Theme.moduleBorder)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    readonly property string dateStr: Qt.formatDateTime(clock.date, "ddd, d MMM")
    readonly property string timeStr: Qt.formatDateTime(clock.date, "hh:mm")

    RowLayout {
        id: timeRow
        anchors.centerIn: parent
        spacing: 6

        // Date
        RowLayout {
            spacing: 4
            Text {
                text: "󰃭"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
                color: Theme.accentSecondary
            }
            Text {
                text: root.dateStr
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
                color: Theme.textSecondary
            }
        }

        // Separator dot
        Rectangle {
            implicitWidth: 3
            implicitHeight: 3
            radius: 1.5
            color: Theme.textMuted
        }

        // Time
        RowLayout {
            spacing: 4
            Text {
                text: "󰥔"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
                color: Theme.accentPrimary
            }
            Text {
                text: root.timeStr
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontNormal
                font.bold: true
                color: Theme.textPrimary
            }
        }
    }

    MouseArea {
        id: clockMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.showCalendar = !root.showCalendar;
            if (root.showCalendar) {
                var now = new Date();
                root.viewYear = now.getFullYear();
                root.viewMonth = now.getMonth();
            }
        }
    }

    // Calendar Helper Functions
    function getDaysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function getFirstDayOfWeek(year, month) {
        var day = new Date(year, month, 1).getDay();
        return (day + 6) % 7; // Monday = 0, Sunday = 6
    }

    function buildDaysModel() {
        var days = [];
        var firstDay = getFirstDayOfWeek(root.viewYear, root.viewMonth);
        var currentDays = getDaysInMonth(root.viewYear, root.viewMonth);
        var prevDays = getDaysInMonth(root.viewYear, root.viewMonth - 1);
        var today = new Date();

        // Previous month padding
        for (var p = firstDay - 1; p >= 0; p--) {
            days.push({
                num: prevDays - p,
                isCurrent: false,
                isToday: false
            });
        }

        // Current month days
        for (var d = 1; d <= currentDays; d++) {
            var isToday = (today.getFullYear() === root.viewYear && today.getMonth() === root.viewMonth && today.getDate() === d);
            days.push({
                num: d,
                isCurrent: true,
                isToday: isToday
            });
        }

        // Next month padding to complete 35 or 42 grid
        var total = days.length > 35 ? 42 : 35;
        var nextDay = 1;
        while (days.length < total) {
            days.push({
                num: nextDay++,
                isCurrent: false,
                isToday: false
            });
        }

        return days;
    }

    // Calendar Dropdown Window
    PopupWindow {
        id: calPopup
        anchor.window: root.parentWindow
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6
        visible: root.showCalendar && root.parentWindow !== null
        color: "transparent"

        implicitWidth: 280
        implicitHeight: 300

        Rectangle {
            id: popupCard
            anchors.fill: parent
            radius: Theme.pillRadius + 4
            color: "#181825"
            border.color: Theme.moduleBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                // Header with Month, Year and Navigation
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.monthNames[root.viewMonth] + " " + root.viewYear
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontNormal
                        font.bold: true
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }

                    // Prev Month Button
                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 5
                        color: prevM.containsMouse ? Theme.moduleBgHover : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰒮"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textSecondary
                        }
                        MouseArea {
                            id: prevM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.viewMonth === 0) {
                                    root.viewMonth = 11;
                                    root.viewYear--;
                                } else {
                                    root.viewMonth--;
                                }
                            }
                        }
                    }

                    // Reset to Today Button
                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 5
                        color: todayM.containsMouse ? Theme.moduleBgHover : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰃭"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.accentPrimary
                        }
                        MouseArea {
                            id: todayM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var now = new Date();
                                root.viewYear = now.getFullYear();
                                root.viewMonth = now.getMonth();
                            }
                        }
                    }

                    // Next Month Button
                    Rectangle {
                        implicitWidth: 22
                        implicitHeight: 22
                        radius: 5
                        color: nextM.containsMouse ? Theme.moduleBgHover : "transparent"
                        Text {
                            anchors.centerIn: parent
                            text: "󰒭"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.textSecondary
                        }
                        MouseArea {
                            id: nextM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.viewMonth === 11) {
                                    root.viewMonth = 0;
                                    root.viewYear++;
                                } else {
                                    root.viewMonth++;
                                }
                            }
                        }
                    }
                }

                // Weekday Headers
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Repeater {
                        model: root.dayHeaders
                        Item {
                            Layout.fillWidth: true
                            implicitHeight: 18
                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                color: Theme.accentSecondary
                            }
                        }
                    }
                }

                // Divider line
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.moduleBorder
                }

                // Days Grid
                GridLayout {
                    id: daysGrid
                    Layout.fillWidth: true
                    columns: 7
                    columnSpacing: 2
                    rowSpacing: 3

                    Repeater {
                        model: root.buildDaysModel()

                        Rectangle {
                            id: dayCell
                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 26
                            radius: 13

                            color: modelData.isToday ? Theme.accentPrimary : (cellMouse.containsMouse ? Theme.moduleBgHover : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: dayCell.modelData.num.toString()
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: dayCell.modelData.isToday
                                color: dayCell.modelData.isToday ? "#11111b" : (dayCell.modelData.isCurrent ? Theme.textPrimary : Theme.textMuted)
                            }

                            MouseArea {
                                id: cellMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                // Footer showing selected/current full date
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 24
                    radius: 5
                    color: Theme.moduleBg

                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        color: Theme.textSecondary
                    }
                }
            }
        }
    }
}
