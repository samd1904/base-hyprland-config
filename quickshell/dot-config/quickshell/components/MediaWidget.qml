import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: root

    // Find active or playing player, filtering out proxy daemon (playerctld)
    readonly property var activePlayer: {
        if (!Mpris.players || !Mpris.players.values || Mpris.players.values.length === 0) return null;
        var players = Mpris.players.values;
        var validPlayers = players.filter(p => !((p.dbusName || "").includes("playerctld")));
        var candidateList = validPlayers.length > 0 ? validPlayers : players;
        
        // Prioritize actively playing player
        for (var i = 0; i < candidateList.length; i++) {
            if (candidateList[i].playbackState === MprisPlaybackState.Playing || candidateList[i].isPlaying) {
                return candidateList[i];
            }
        }
        return candidateList[0];
    }

    readonly property bool hasMedia: activePlayer !== null
    readonly property bool isPlaying: activePlayer ? (activePlayer.playbackState === MprisPlaybackState.Playing || activePlayer.isPlaying) : false
    
    // Check if player is Spotify
    readonly property bool isSpotify: {
        if (!activePlayer) return false;
        var id = (activePlayer.identity || "").toLowerCase();
        var bus = (activePlayer.dbusName || "").toLowerCase();
        var desktop = (activePlayer.desktopEntry || "").toLowerCase();
        var trackId = "";
        if (activePlayer.metadata && activePlayer.metadata["mpris:trackid"]) {
            trackId = activePlayer.metadata["mpris:trackid"].toString().toLowerCase();
        }
        return id.includes("spotify") || bus.includes("spotify") || desktop.includes("spotify") || trackId.includes("spotify");
    }

    visible: hasMedia
    implicitHeight: Theme.barHeight - 6
    implicitWidth: contentRow.implicitWidth + 22
    radius: Theme.pillRadius

    // Spotify green coloring when player is Spotify
    color: isSpotify ? (isPlaying ? "#13351f" : "#0f2316") : (isPlaying ? Theme.moduleBgHover : Theme.moduleBg)
    border.color: isSpotify ? Theme.spotifyGreen : (isPlaying ? Theme.accentSecondary : Theme.moduleBorder)
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 200 }
    }
    Behavior on border.color {
        ColorAnimation { duration: 200 }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        // Music / Spotify Icon
        Text {
            text: root.isSpotify ? "󰓇" : (root.isPlaying ? "󰝚" : "󰝛")
            font.family: Theme.fontFamily
            font.pixelSize: Theme.iconSize
            color: root.isSpotify ? Theme.spotifyGreen : (root.isPlaying ? Theme.accentSecondary : Theme.textMuted)
        }

        // Song Title & Artist
        ColumnLayout {
            spacing: 0
            Layout.maximumWidth: 150
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: titleText
                text: {
                    if (!root.activePlayer) return "No Media";
                    var t = root.activePlayer.trackTitle || "";
                    return t.length > 0 ? t : "Unknown Title";
                }
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: root.isSpotify ? "#ffffff" : Theme.textPrimary
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                id: artistText
                text: {
                    if (!root.activePlayer) return "";
                    var a = root.activePlayer.trackArtist || "";
                    return a.length > 0 ? a : (root.activePlayer.identity || "Media Player");
                }
                font.family: Theme.fontFamily
                font.pixelSize: 9
                color: root.isSpotify ? Theme.spotifyGreenLight : Theme.textSecondary
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text.length > 0
            }
        }

        // Controls: Prev
        Rectangle {
            implicitWidth: 18
            implicitHeight: 18
            radius: 9
            color: prevMouse.containsMouse ? (root.isSpotify ? "#1db954" : Theme.moduleBorder) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰒮"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: prevMouse.containsMouse ? "#000000" : (root.isSpotify ? Theme.spotifyGreenLight : Theme.textSecondary)
            }

            MouseArea {
                id: prevMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer && root.activePlayer.canGoPrevious) {
                        root.activePlayer.previous();
                    }
                }
            }
        }

        // Controls: Play / Pause
        Rectangle {
            implicitWidth: 18
            implicitHeight: 18
            radius: 9
            color: root.isSpotify ? Theme.spotifyGreen : (playMouse.containsMouse ? Theme.accentSecondary : Theme.moduleBorder)

            Text {
                anchors.centerIn: parent
                text: root.isPlaying ? "󰏤" : "󰐊"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: root.isSpotify ? "#000000" : (playMouse.containsMouse ? "#11111b" : Theme.textPrimary)
            }

            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer && root.activePlayer.canTogglePlaying) {
                        root.activePlayer.togglePlaying();
                    }
                }
            }
        }

        // Controls: Next
        Rectangle {
            implicitWidth: 18
            implicitHeight: 18
            radius: 9
            color: nextMouse.containsMouse ? (root.isSpotify ? "#1db954" : Theme.moduleBorder) : "transparent"

            Text {
                anchors.centerIn: parent
                text: "󰒭"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: nextMouse.containsMouse ? "#000000" : (root.isSpotify ? Theme.spotifyGreenLight : Theme.textSecondary)
            }

            MouseArea {
                id: nextMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.activePlayer && root.activePlayer.canGoNext) {
                        root.activePlayer.next();
                    }
                }
            }
        }
    }
}
