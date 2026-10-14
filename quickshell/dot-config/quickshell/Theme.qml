pragma Singleton
import QtQuick

QtObject {
    // Backgrounds & Surface colors
    readonly property color barBg: "#a611121d"
    readonly property color barBorder: "#2a2b3d"
    readonly property color moduleBg: "#1e1e2e"
    readonly property color moduleBgHover: "#28293d"
    readonly property color moduleBorder: "#313244"
    
    // Text colors
    readonly property color textPrimary: "#cdd6f4"
    readonly property color textSecondary: "#a6adc8"
    readonly property color textMuted: "#6c7086"
    
    // Accent colors
    readonly property color accentPrimary: "#89b4fa"      // Catppuccin Blue
    readonly property color accentSecondary: "#cba6f7"    // Mauve
    readonly property color accentSuccess: "#a6e3a1"      // Green
    readonly property color accentWarning: "#f9e2af"      // Yellow
    readonly property color accentDanger: "#f38ba8"       // Red
    readonly property color accentCyan: "#89dceb"         // Sky
    readonly property color accentOrange: "#fab387"       // Peach
    
    // Spotify Signature Green
    readonly property color spotifyGreen: "#1db954"
    readonly property color spotifyGreenLight: "#1ed760"
    readonly property color spotifyGreenDark: "#121212"
    readonly property color spotifyBg: "#14291e"
    readonly property color spotifyBorder: "#1db954"
    
    // Fonts (Slightly increased for readability)
    readonly property string fontFamily: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property int fontNormal: 13
    readonly property int fontSmall: 12
    readonly property int fontLarge: 14
    readonly property int iconSize: 14
    
    // Sizing
    readonly property int barHeight: 34
    readonly property int pillRadius: 7
    readonly property int pillPadding: 8
}
