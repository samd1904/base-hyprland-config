import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: root

    property var parentWindow: null
    property bool showNetworks: false
    property bool isScanning: false
    property bool isConnecting: false
    property string connectingSsid: ""
    property string expandedSsid: ""
    property string passwordInput: ""
    property bool showPassword: false
    property string connectionError: ""

    property bool ethConnected: false
    property string ethName: ""
    property string ethDev: ""
    property string ethIp: ""
    property string ethState: "disconnected"

    property bool wifiConnected: false
    property string wifiName: ""
    property string wifiDev: ""
    property string wifiIp: ""
    property string wifiState: "disconnected"

    property bool isConnected: ethConnected || wifiConnected

    property var wifiNetworks: []

    implicitHeight: Theme.barHeight - 6
    implicitWidth: netRow.implicitWidth + 14
    radius: Theme.pillRadius
    color: showNetworks ? Theme.moduleBgHover : (netMouse.containsMouse ? Theme.moduleBgHover : Theme.moduleBg)
    border.color: showNetworks ? Theme.accentPrimary : (isConnected ? (netMouse.containsMouse ? Theme.accentSecondary : Theme.moduleBorder) : Theme.accentDanger)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // Active connection check process for both Ethernet and Wi-Fi
    Process {
        id: netProcess
        command: [
            "bash", "-c",
            "eth_line=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null | grep -E '^[^:]+:ethernet:' | grep -v '^veth' | head -n1); wifi_line=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION dev 2>/dev/null | grep -E '^[^:]+:wifi:' | head -n1); eth_dev=$(echo \"$eth_line\" | cut -d: -f1); eth_state=$(echo \"$eth_line\" | cut -d: -f3); eth_con=$(echo \"$eth_line\" | cut -d: -f4); eth_ip=''; if [ \"$eth_state\" = 'connected' ] && [ -n \"$eth_dev\" ]; then eth_ip=$(ip -4 addr show dev \"$eth_dev\" 2>/dev/null | grep -oP 'inet \\K[\\d.]+' | head -n1); fi; wifi_dev=$(echo \"$wifi_line\" | cut -d: -f1); wifi_state=$(echo \"$wifi_line\" | cut -d: -f3); wifi_con=$(echo \"$wifi_line\" | cut -d: -f4); wifi_ip=''; if [ \"$wifi_state\" = 'connected' ] && [ -n \"$wifi_dev\" ]; then wifi_ip=$(ip -4 addr show dev \"$wifi_dev\" 2>/dev/null | grep -oP 'inet \\K[\\d.]+' | head -n1); fi; echo \"ETH:$eth_dev:$eth_state:$eth_con:$eth_ip\"; echo \"WIFI:$wifi_dev:$wifi_state:$wifi_con:$wifi_ip\""
        ]

        stdout: SplitParser {
            onRead: data => {
                var line = data.trim();
                if (line.startsWith("ETH:")) {
                    var ep = line.substring(4).split(":");
                    root.ethDev = ep[0] || "";
                    root.ethState = ep[1] || "disconnected";
                    root.ethConnected = root.ethState === "connected";
                    root.ethName = ep[2] || (root.ethConnected ? "Wired" : "");
                    root.ethIp = ep[3] || "";
                } else if (line.startsWith("WIFI:")) {
                    var wp = line.substring(5).split(":");
                    root.wifiDev = wp[0] || "";
                    root.wifiState = wp[1] || "disconnected";
                    root.wifiConnected = root.wifiState === "connected";
                    root.wifiName = wp[2] || "";
                    root.wifiIp = wp[3] || "";
                }
            }
        }
    }

    // WiFi list scan and saved connections process
    Process {
        id: wifiListProcess
        command: [
            "bash", "-c",
            "nmcli -t -f NAME,TYPE con show | awk -F: '$2==\"802-11-wireless\" {print $1}'; echo '---WIFI_LIST---'; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null"
        ]

        stdout: StdioCollector {
            id: wifiCollector
        }

        onExited: {
            root.isScanning = false;
            var text = wifiCollector.text || "";
            var sections = text.trim().split("---WIFI_LIST---");
            var savedRaw = sections.length > 0 ? sections[0].trim().split("\n") : [];
            var wifiRaw = sections.length > 1 ? sections[1].trim().split("\n") : [];

            var savedMap = {};
            for (var s = 0; s < savedRaw.length; s++) {
                var sName = savedRaw[s].trim();
                if (sName) savedMap[sName] = true;
            }

            var list = [];
            var seen = {};

            for (var i = 0; i < wifiRaw.length; i++) {
                var line = wifiRaw[i];
                if (!line) continue;
                var parts = line.split(":");
                if (parts.length < 4) continue;
                var inUse = parts[0].trim() === "*";
                var ssid = parts[1].trim();
                if (!ssid) continue;
                var signal = parseInt(parts[2]) || 0;
                var sec = parts[3].trim();
                var isSaved = Boolean(savedMap[ssid]);

                if (seen[ssid]) {
                    if (inUse) seen[ssid].inUse = true;
                    if (signal > seen[ssid].signal) seen[ssid].signal = signal;
                    continue;
                }

                var item = {
                    ssid: ssid,
                    inUse: inUse,
                    signal: signal,
                    secured: sec.length > 0 && sec !== "--",
                    isSaved: isSaved
                };
                seen[ssid] = item;
                list.push(item);
            }

            list.sort((a, b) => {
                if (a.inUse) return -1;
                if (b.inUse) return 1;
                return b.signal - a.signal;
            });

            root.wifiNetworks = list;
        }
    }

    // Connect to wifi process with 2>&1 stderr capture
    Process {
        id: connectProcess
        property string targetSsid: ""
        property string targetPassword: ""

        command: [
            "bash", "-c",
            'ssid="$1"; pass="$2"; if [ -n "$pass" ]; then nmcli dev wifi connect "$ssid" password "$pass" 2>&1; else nmcli con up id "$ssid" 2>&1 || nmcli dev wifi connect "$ssid" 2>&1; fi',
            "_",
            targetSsid,
            targetPassword
        ]

        stdout: StdioCollector {
            id: connectCollector
        }

        onExited: (exitCode, exitStatus) => {
            root.isConnecting = false;
            var out = (connectCollector.text || "").trim();
            var failedSsid = root.connectingSsid;
            root.connectingSsid = "";

            if (exitCode === 0) {
                root.expandedSsid = "";
                root.passwordInput = "";
                root.connectionError = "";
                netProcess.running = true;
                root.isScanning = true;
                wifiListProcess.running = true;
            } else {
                if (out.indexOf("Secrets were required") !== -1 ||
                    out.indexOf("Passwords or encryption keys are required") !== -1 ||
                    out.indexOf("password") !== -1 ||
                    out.indexOf("802-11-wireless-security") !== -1) {
                    root.expandedSsid = failedSsid;
                    root.connectionError = "Password required to connect";
                } else if (out.indexOf("No network with SSID") !== -1) {
                    root.connectionError = "Network not in range";
                } else {
                    root.connectionError = out.length > 0 ? (out.length > 40 ? out.substring(0, 37) + "..." : out) : "Connection failed";
                }
            }
        }
    }

    // Disconnect process with dynamic wifi interface lookup
    Process {
        id: disconnectProcess
        property string targetSsid: ""
        property string targetDev: ""

        command: [
            "bash", "-c",
            'ssid="$1"; wdev="$2"; if [ -z "$wdev" ]; then wdev=$(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | awk -F: \'$2=="wifi"{print $1; exit}\'); fi; [ -n "$ssid" ] && nmcli con down id "$ssid" 2>/dev/null; [ -n "$wdev" ] && nmcli dev disconnect "$wdev" 2>/dev/null',
            "_",
            targetSsid,
            targetDev
        ]
        onExited: {
            netProcess.running = true;
            root.isScanning = true;
            wifiListProcess.running = true;
        }
    }

    function triggerConnect(ssid, password) {
        if (connectProcess.running) {
            connectProcess.terminate();
        }
        root.isConnecting = true;
        root.connectingSsid = ssid;
        root.connectionError = "";
        connectProcess.targetSsid = ssid;
        connectProcess.targetPassword = password || "";
        connectProcess.running = true;
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!netProcess.running) {
                netProcess.running = true;
            }
        }
    }

    RowLayout {
        id: netRow
        anchors.centerIn: parent
        spacing: 5

        // Ethernet Indicator (visible if ethConnected)
        RowLayout {
            spacing: 3
            visible: root.ethConnected

            Text {
                text: "󰈀"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
                color: Theme.accentCyan
            }

            // Only show Ethernet label if Wi-Fi is NOT connected
            Text {
                visible: !root.wifiConnected
                text: "Ethernet"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
                color: Theme.textPrimary
            }
        }

        // Dot separator if BOTH ethernet and wifi are connected
        Text {
            visible: root.ethConnected && root.wifiConnected
            text: "·"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSmall
            color: Theme.textMuted
        }

        // Wi-Fi Indicator (visible if wifiConnected or if nothing is connected)
        RowLayout {
            spacing: 4
            visible: root.wifiConnected || !root.ethConnected

            Text {
                text: root.wifiConnected ? "󰤨" : (!root.ethConnected ? "󰤭" : "")
                visible: text !== ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
                color: root.wifiConnected ? Theme.accentCyan : Theme.accentDanger
            }

            Text {
                text: {
                    if (root.wifiConnected) {
                        return root.wifiName.length > 12 ? root.wifiName.substring(0, 10) + ".." : root.wifiName;
                    }
                    if (!root.ethConnected) {
                        return "Offline";
                    }
                    return "";
                }
                visible: text !== ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSmall
                font.bold: true
                color: root.wifiConnected ? Theme.textPrimary : Theme.accentDanger
            }
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.showNetworks = !root.showNetworks;
            if (root.showNetworks) {
                root.isScanning = true;
                root.connectionError = "";
                wifiListProcess.running = true;
            }
        }
    }

    // Network Selector Popup
    PopupWindow {
        id: netPopup
        anchor.window: root.parentWindow
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.margins.top: 6
        visible: root.showNetworks && root.parentWindow !== null
        color: "transparent"

        implicitWidth: 320
        implicitHeight: 410

        Rectangle {
            id: netCard
            anchors.fill: parent
            radius: Theme.pillRadius + 4
            color: "#181825"
            border.color: Theme.moduleBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 7

                // Header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Network Connections"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontNormal
                        font.bold: true
                        color: Theme.textPrimary
                        Layout.fillWidth: true
                    }

                    // Refresh Button with spinner
                    Rectangle {
                        implicitWidth: 24
                        implicitHeight: 24
                        radius: 5
                        color: refreshM.containsMouse ? Theme.moduleBgHover : "transparent"

                        Text {
                            id: refreshIcon
                            anchors.centerIn: parent
                            text: "󰑐"
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            color: root.isScanning ? Theme.accentCyan : Theme.accentPrimary

                            RotationAnimation on rotation {
                                running: root.isScanning
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 800
                            }
                        }

                        MouseArea {
                            id: refreshM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                netProcess.running = true;
                                root.isScanning = true;
                                root.connectionError = "";
                                wifiListProcess.running = true;
                            }
                        }
                    }
                }

                // Ethernet Status Card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 42
                    radius: 6
                    color: root.ethConnected ? "#14242e" : Theme.moduleBg
                    border.color: root.ethConnected ? Theme.accentCyan : Theme.moduleBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            text: "󰈀"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.iconSize
                            color: root.ethConnected ? Theme.accentCyan : Theme.textMuted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: root.ethConnected ? (root.ethName || "Wired Connection") : "Ethernet"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSmall
                                font.bold: true
                                color: Theme.textPrimary
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }

                            Text {
                                text: root.ethConnected
                                    ? (root.ethIp ? root.ethIp + (root.ethDev ? " · " + root.ethDev : "") : (root.ethDev || "Connected"))
                                    : (root.ethDev ? "Disconnected (" + root.ethDev + ")" : "Not plugged in")
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: root.ethConnected ? Theme.textSecondary : Theme.textMuted
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Ethernet Status Badge
                        Rectangle {
                            implicitHeight: 20
                            implicitWidth: ethBadgeText.implicitWidth + 12
                            radius: 4
                            color: root.ethConnected ? "#183626" : "#242533"
                            border.color: root.ethConnected ? Theme.accentSuccess : Theme.moduleBorder
                            border.width: 1

                            Text {
                                id: ethBadgeText
                                anchors.centerIn: parent
                                text: root.ethConnected ? "󰄬 Connected" : "Inactive"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.bold: true
                                color: root.ethConnected ? Theme.accentSuccess : Theme.textMuted
                            }
                        }
                    }
                }

                // Connecting Status Banner
                Rectangle {
                    visible: root.isConnecting
                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 5
                    color: "#2a2614"
                    border.color: Theme.accentWarning
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰑐"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            color: Theme.accentWarning

                            RotationAnimation on rotation {
                                running: root.isConnecting
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 800
                            }
                        }

                        Text {
                            text: "Connecting to " + root.connectingSsid + "..."
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSmall
                            font.bold: true
                            color: Theme.accentWarning
                            elide: Text.ElideRight
                            Layout.maximumWidth: 240
                        }
                    }
                }

                // Wi-Fi Section Header
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2

                    Text {
                        text: "Wi-Fi Networks"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSmall
                        font.bold: true
                        color: Theme.textSecondary
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.wifiNetworks.length > 0
                        text: root.wifiNetworks.length + " found"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.textMuted
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.moduleBorder
                }

                // Empty / Scanning state indicator
                Text {
                    visible: root.wifiNetworks.length === 0
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 15
                    Layout.bottomMargin: 15
                    text: root.isScanning ? "Scanning for networks..." : "No Wi-Fi networks found"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSmall
                    color: Theme.textMuted
                }

                // Networks List
                ListView {
                    id: wifiListView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: root.wifiNetworks

                    delegate: Rectangle {
                        id: netItem
                        required property var modelData

                        readonly property bool isThisExpanded: root.expandedSsid === modelData.ssid
                        readonly property bool isThisConnecting: root.isConnecting && root.connectingSsid === modelData.ssid

                        width: wifiListView.width
                        implicitHeight: isThisExpanded ? 84 : 36
                        radius: 6
                        color: modelData.inUse ? "#1a3224" : (isThisConnecting ? "#242516" : (isThisExpanded ? Theme.moduleBgHover : (itemMouse.containsMouse ? Theme.moduleBgHover : Theme.moduleBg)))
                        border.color: modelData.inUse ? Theme.accentSuccess : (isThisConnecting ? Theme.accentWarning : (isThisExpanded ? Theme.accentPrimary : (itemMouse.containsMouse ? Theme.accentSecondary : Theme.moduleBorder)))
                        border.width: 1

                        Behavior on implicitHeight {
                            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6
                            spacing: 5

                            // Top Info Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                // Signal icon
                                Text {
                                    text: {
                                        var sig = netItem.modelData.signal;
                                        if (sig >= 75) return "󰤨";
                                        if (sig >= 50) return "󰤥";
                                        if (sig >= 25) return "󰤢";
                                        return "󰤟";
                                    }
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    color: netItem.modelData.inUse ? Theme.accentSuccess : Theme.accentCyan
                                }

                                // SSID name
                                Text {
                                    text: netItem.modelData.ssid
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSmall
                                    font.bold: netItem.modelData.inUse
                                    color: netItem.modelData.inUse ? "#ffffff" : Theme.textPrimary
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                // Saved badge
                                Text {
                                    text: "Saved"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    color: Theme.accentSecondary
                                    visible: netItem.modelData.isSaved && !netItem.modelData.inUse && !netItem.isThisConnecting
                                }

                                // Lock icon
                                Text {
                                    text: "󰌾"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.textMuted
                                    visible: netItem.modelData.secured && !netItem.modelData.inUse
                                }

                                // Connecting badge
                                Text {
                                    text: "Connecting..."
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.accentWarning
                                    visible: netItem.isThisConnecting
                                }

                                // Connected badge
                                Text {
                                    text: "󰄬 Connected"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.bold: true
                                    color: Theme.accentSuccess
                                    visible: netItem.modelData.inUse && !netItem.isThisConnecting
                                }

                                // Disconnect Button for inUse
                                Rectangle {
                                    visible: netItem.modelData.inUse
                                    implicitWidth: 20
                                    implicitHeight: 20
                                    radius: 4
                                    color: disMouse.containsMouse ? Theme.accentDanger : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: disMouse.containsMouse ? "#ffffff" : Theme.accentDanger
                                    }

                                    MouseArea {
                                        id: disMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            disconnectProcess.targetSsid = netItem.modelData.ssid;
                                            disconnectProcess.targetDev = root.wifiDev;
                                            disconnectProcess.running = true;
                                        }
                                    }
                                }

                                // Cancel expansion button
                                Rectangle {
                                    visible: netItem.isThisExpanded
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: 4
                                    color: cancelM.containsMouse ? Theme.moduleBorder : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰅖"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.textMuted
                                    }

                                    MouseArea {
                                        id: cancelM
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.expandedSsid = "";
                                            root.passwordInput = "";
                                            root.connectionError = "";
                                        }
                                    }
                                }
                            }

                            // Error message if connection failed
                            Text {
                                visible: netItem.isThisExpanded && root.connectionError.length > 0
                                text: root.connectionError
                                font.family: Theme.fontFamily
                                font.pixelSize: 8
                                color: Theme.accentDanger
                            }

                            // Inline Password Entry Row
                            RowLayout {
                                visible: netItem.isThisExpanded
                                Layout.fillWidth: true
                                spacing: 5

                                // Password input container
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 26
                                    radius: 5
                                    color: "#11111b"
                                    border.color: passInput.activeFocus ? Theme.accentPrimary : Theme.moduleBorder
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 6
                                        anchors.rightMargin: 4
                                        spacing: 4

                                        TextInput {
                                            id: passInput
                                            Layout.fillWidth: true
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSmall
                                            color: Theme.textPrimary
                                            echoMode: root.showPassword ? TextInput.Normal : TextInput.Password
                                            clip: true
                                            text: root.passwordInput
                                            onTextChanged: {
                                                root.passwordInput = text;
                                                root.connectionError = "";
                                            }
                                            onAccepted: {
                                                if (text.length > 0) {
                                                    root.triggerConnect(netItem.modelData.ssid, text);
                                                }
                                            }

                                            Text {
                                                anchors.fill: parent
                                                text: "Enter password..."
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSmall
                                                color: Theme.textMuted
                                                visible: passInput.text.length === 0
                                            }
                                        }

                                        // Eye button to toggle password visibility
                                        Rectangle {
                                            implicitWidth: 18
                                            implicitHeight: 18
                                            color: "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: root.showPassword ? "󰈈" : "󰈉"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 10
                                                color: Theme.textMuted
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.showPassword = !root.showPassword
                                            }
                                        }
                                    }
                                }

                                // Connect Button
                                Rectangle {
                                    implicitWidth: 58
                                    implicitHeight: 26
                                    radius: 5
                                    color: root.isConnecting ? Theme.moduleBorder : (connBtnMouse.containsMouse ? Theme.accentSecondary : Theme.accentPrimary)

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.isConnecting ? "..." : "Connect"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSmall
                                        font.bold: true
                                        color: "#11111b"
                                    }

                                    MouseArea {
                                        id: connBtnMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (passInput.text.length > 0) {
                                                root.triggerConnect(netItem.modelData.ssid, passInput.text);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Click to connect or expand
                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            enabled: !netItem.isThisExpanded && !root.isConnecting
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (netItem.modelData.inUse) {
                                    return;
                                }

                                // If network is saved or open, attempt direct connection:
                                if (netItem.modelData.isSaved || !netItem.modelData.secured) {
                                    root.triggerConnect(netItem.modelData.ssid, "");
                                } else {
                                    // Expand inline password prompt
                                    root.expandedSsid = netItem.modelData.ssid;
                                    root.passwordInput = "";
                                    root.connectionError = "";
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
