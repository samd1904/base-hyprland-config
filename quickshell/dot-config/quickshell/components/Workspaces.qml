import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import ".."

Item {
    id: root
    implicitHeight: Theme.barHeight - 6
    implicitWidth: workspaceRow.implicitWidth

    readonly property var workspaceList: {
        var ids = [1, 2, 3, 4, 5];
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            var activeWs = Hyprland.workspaces.values;
            for (var i = 0; i < activeWs.length; i++) {
                var wid = activeWs[i].id;
                if (wid > 0 && ids.indexOf(wid) === -1) {
                    ids.push(wid);
                }
            }
        }
        ids.sort((a, b) => a - b);
        return ids;
    }

    RowLayout {
        id: workspaceRow
        anchors.fill: parent
        spacing: 4

        Repeater {
            model: root.workspaceList

            Rectangle {
                id: wsButton
                required property int modelData
                
                readonly property int wsId: modelData
                readonly property bool isFocused: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                readonly property bool isOccupied: {
                    if (!Hyprland.workspaces || !Hyprland.workspaces.values) return false;
                    return Hyprland.workspaces.values.some(w => w.id === wsId);
                }
                readonly property bool isHovered: mouseArea.containsMouse

                implicitWidth: isFocused ? 24 : (isHovered ? 22 : 18)
                implicitHeight: root.implicitHeight
                radius: Theme.pillRadius - 1

                color: isFocused ? Theme.accentPrimary : (isHovered ? Theme.moduleBgHover : Theme.moduleBg)
                border.color: isFocused ? Theme.accentPrimary : (isOccupied ? Theme.accentSecondary : Theme.moduleBorder)
                border.width: 1

                Behavior on implicitWidth {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Text {
                    anchors.centerIn: parent
                    text: wsButton.wsId.toString()
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    font.bold: wsButton.isFocused
                    color: wsButton.isFocused ? "#11111b" : (wsButton.isOccupied ? Theme.textPrimary : Theme.textMuted)
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsButton.wsId + " })");
                    }
                }
            }
        }
    }
}
