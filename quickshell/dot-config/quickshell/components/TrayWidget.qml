import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import ".."

Rectangle {
    id: root

    property var parentWindow: null

    // System tray item count
    readonly property int count: SystemTray.items.values.length
    visible: count > 0

    implicitHeight: Theme.barHeight - 6
    implicitWidth: visible ? (trayRow.implicitWidth + 14) : 0
    radius: Theme.pillRadius
    color: Theme.moduleBg
    border.color: Theme.moduleBorder
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Active tooltip tracking
    property var activeHoverItem: null
    property string activeTooltipTitle: ""
    property string activeTooltipDesc: ""

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayDelegate
                required property var modelData

                implicitWidth: 22
                implicitHeight: 22
                radius: 5
                color: itemMouse.containsMouse ? Theme.moduleBgHover : "transparent"
                border.color: itemMouse.containsMouse ? Theme.accentPrimary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                // Associated DBus context menu
                QsMenuAnchor {
                    id: menuAnchor
                    anchor.window: root.parentWindow
                    anchor.item: trayDelegate
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                    anchor.margins.top: 4
                    menu: trayDelegate.modelData.menu
                }

                // Icon using Quickshell.Widgets.IconImage
                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    implicitSize: 16
                    source: trayDelegate.modelData.icon || ""
                    asynchronous: true
                }

                // Fallback text if icon fails to load or is empty
                Text {
                    anchors.centerIn: parent
                    visible: (trayIcon.status !== Image.Ready && trayIcon.status !== Image.Loading) || !trayDelegate.modelData.icon
                    text: {
                        if (trayDelegate.modelData.title && trayDelegate.modelData.title.length > 0) {
                            return trayDelegate.modelData.title.charAt(0).toUpperCase();
                        }
                        if (trayDelegate.modelData.id && trayDelegate.modelData.id.length > 0) {
                            return trayDelegate.modelData.id.charAt(0).toUpperCase();
                        }
                        return "󰏖";
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    color: Theme.accentPrimary
                }

                // Attention badge if app status is NeedsAttention
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.topMargin: 2
                    anchors.rightMargin: 2
                    width: 5
                    height: 5
                    radius: 2.5
                    color: Theme.accentWarning
                    visible: trayDelegate.modelData.status === Status.NeedsAttention
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onEntered: {
                        root.activeHoverItem = trayDelegate;
                        root.activeTooltipTitle = trayDelegate.modelData.tooltipTitle || trayDelegate.modelData.title || trayDelegate.modelData.id || "";
                        root.activeTooltipDesc = trayDelegate.modelData.tooltipDescription || "";
                    }

                    onExited: {
                        if (root.activeHoverItem === trayDelegate) {
                            root.activeHoverItem = null;
                            root.activeTooltipTitle = "";
                            root.activeTooltipDesc = "";
                        }
                    }

                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            if (menuAnchor.menu) {
                                if (menuAnchor.visible) {
                                    menuAnchor.close();
                                } else {
                                    menuAnchor.open();
                                }
                            } else if (trayDelegate.modelData.display) {
                                var coords = mapToItem(null, mouse.x, mouse.y);
                                trayDelegate.modelData.display(root.parentWindow, coords.x, coords.y);
                            }
                        } else if (mouse.button === Qt.LeftButton) {
                            if (trayDelegate.modelData.onlyMenu) {
                                if (menuAnchor.menu) {
                                    if (menuAnchor.visible) {
                                        menuAnchor.close();
                                    } else {
                                        menuAnchor.open();
                                    }
                                } else if (trayDelegate.modelData.display) {
                                    var coords = mapToItem(null, mouse.x, mouse.y);
                                    trayDelegate.modelData.display(root.parentWindow, coords.x, coords.y);
                                }
                            } else {
                                trayDelegate.modelData.activate();
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayDelegate.modelData.secondaryActivate();
                        }
                    }

                    onWheel: wheel => {
                        trayDelegate.modelData.scroll(wheel.angleDelta.y, false);
                    }
                }
            }
        }
    }

    // Shared Tooltip Popup anchored to active hovered tray item
    PopupWindow {
        id: tooltipPopup
        anchor.window: root.parentWindow
        anchor.item: root.activeHoverItem || root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6
        visible: root.activeHoverItem !== null && (root.activeTooltipTitle !== "" || root.activeTooltipDesc !== "") && root.parentWindow !== null
        color: "transparent"

        implicitWidth: tooltipCard.implicitWidth
        implicitHeight: tooltipCard.implicitHeight

        Rectangle {
            id: tooltipCard
            implicitWidth: tooltipCol.implicitWidth + 16
            implicitHeight: tooltipCol.implicitHeight + 12
            radius: Theme.pillRadius
            color: "#181825"
            border.color: Theme.moduleBorder
            border.width: 1

            ColumnLayout {
                id: tooltipCol
                anchors.centerIn: parent
                spacing: 2

                Text {
                    visible: root.activeTooltipTitle !== ""
                    text: root.activeTooltipTitle
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: true
                    color: Theme.textPrimary
                }

                Text {
                    visible: root.activeTooltipDesc !== ""
                    text: root.activeTooltipDesc
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall - 1
                    color: Theme.textSecondary
                }
            }
        }
    }
}
