import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import QtMultimedia
import "./qml/pages"

// Import components with fully qualified name
import "qml/components" as Components

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 800
    height: 480
    title: "NeuroDrive Dashboard"

    // Dark mode toggle property
    property bool darkMode: true  // Set to true for default dark mode

    // Global properties with dark mode support
    property color accentColor: "#0066CC"  // Darker blue
    property color secondaryColor: "#FF6B35"  // Warmer orange accent
    property color backgroundColor: darkMode ? "#121212" : "#F5F5F5"  // Background color
    property color surfaceColor: darkMode ? "#1E1E1E" : "#FFFFFF"  // Surface color
    property color textColor: darkMode ? "#E0E0E0" : "#212121"  // Text color
    property color subtleColor: darkMode ? "#333333" : "#E0E0E0"  // Subtle border color
    property color shadowColor: darkMode ? "#111111" : "#DDDDDD"  // Shadow color

    Component.onCompleted: {
        // Verify and set the correct script paths
        processManager.setTrafficSignPath("/home/abdelrhman/Documents/traffic_signs_detection_3/main.py")
        processManager.setDrowsinessPath("/home/abdelrhman/Documents/drowsiness_detection_f3/main.py")
        
        console.log("Script paths set:")
        console.log("Traffic Sign:", processManager.getTrafficSignPath())
        console.log("Drowsiness:", processManager.getDrowsinessPath())
    }

    // Main window background
    Rectangle {
        anchors.fill: parent
        color: backgroundColor
        
        // Background grid pattern
        Grid {
            anchors.fill: parent
            spacing: 40
            columns: 20
            rows: 12
            visible: !darkMode  // Hide grid in dark mode
            
            Repeater {
                model: 240
                Rectangle {
                    width: 1
                    height: 1
                    color: "#DDDDDD"
                }
            }
        }
    }

    // StackView for navigation
    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: loginPageComponent
        
        // Add pop transition settings
        popEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
            }
        }
        popExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
            }
        }
        pushEnter: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 200
            }
        }
        pushExit: Transition {
            PropertyAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 200
            }
        }
    }

    // Login Page Component
    Component {
        id: loginPageComponent
        LoginPage {
            onLoginSuccessful: {
                stackView.push(dashboardPage)
            }
            onLoginFailed: function(errorMessage) {
                console.log("Login failed:", errorMessage)
            }
        }
    }

    // Dashboard Page
    Component {
        id: dashboardPage
        Page {
            width: parent ? parent.width : 800
            height: parent ? parent.height : 480
            
            background: Rectangle {
                color: backgroundColor
            }
            
            // Header with car info
            Rectangle {
                id: header
                width: parent.width
                height: 60
                color: surfaceColor
                anchors.top: parent.top
                border.width: 1
                border.color: shadowColor
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 20
                    
                    Text {
                        text: "NEURODRIVE"
                        font.pixelSize: 24
                        font.bold: true
                        color: accentColor
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: Qt.formatDateTime(new Date(), "hh:mm")
                        font.pixelSize: 20
                        color: textColor
                    }
                    
                    Text {
                        text: "23°C"
                        font.pixelSize: 20
                        color: textColor
                    }
                }
            }
            
            // Main content area with speedometer and features
            Item {
                anchors.top: header.bottom
                anchors.bottom: footer.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                
                // Left side - Speedometer
                Item {
                    id: speedometer
                    width: parent.width * 0.4
                    height: width
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    
                    // Outer circle
                    Shape {
                        anchors.fill: parent
                        
                        ShapePath {
                            strokeWidth: 10
                            strokeColor: subtleColor
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            
                            PathAngleArc {
                                centerX: speedometer.width / 2
                                centerY: speedometer.height / 2
                                radiusX: speedometer.width / 2 - 20
                                radiusY: speedometer.height / 2 - 20
                                startAngle: -210
                                sweepAngle: 240
                            }
                        }
                        
                        // Speed indicator
                        ShapePath {
                            strokeWidth: 10
                            strokeColor: accentColor
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            
                            PathAngleArc {
                                centerX: speedometer.width / 2
                                centerY: speedometer.height / 2
                                radiusX: speedometer.width / 2 - 20
                                radiusY: speedometer.height / 2 - 20
                                startAngle: -210
                                sweepAngle: 120 // Half of the gauge
                            }
                        }
                    }
                    
                    // Center circle
                    Rectangle {
                        width: 120
                        height: width
                        radius: width/2
                        color: surfaceColor
                        border.width: 1
                        border.color: subtleColor
                        anchors.centerIn: parent
                    }
                    
                    // Speed text
                    Column {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            text: "75"
                            font.pixelSize: 48
                            font.bold: true
                            color: textColor
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "km/h"
                            font.pixelSize: 16
                            color: Qt.lighter(textColor, 1.4)
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                
                // Right side - Feature buttons
                GridLayout {
                    anchors.left: speedometer.right
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 20
                    columns: 2
                    rowSpacing: 15
                    columnSpacing: 15
                    
                    DashboardButton {
                        Layout.fillWidth: true
                        buttonText: "Front Camera"
                        iconText: "🛣️"
                        onClicked: stackView.push(frontCameraPage)
                    }
                    
                    DashboardButton {
                        Layout.fillWidth: true
                        buttonText: "Cabin Camera"
                        iconText: "👁️"
                        onClicked: stackView.push(cabinCameraPage)
                    }
                    
                    DashboardButton {
                        Layout.fillWidth: true
                        buttonText: "Mate Drive"
                        iconText: "🎤"
                        onClicked: speechPopup.open()
                    }
                    
                    DashboardButton {
                        Layout.fillWidth: true
                        buttonText: "Settings"
                        iconText: "⚙️"
                        onClicked: settingsPopup.open()
                    }
                    
                    DashboardButton {
                        Layout.fillWidth: true
                        buttonText: "Debug Test"
                        iconText: "🔍"
                        onClicked: debugPopup.open()
                    }
                }
            }
            
            // Footer with status indicators
            Rectangle {
                id: footer
                width: parent.width
                height: 50
                color: surfaceColor
                anchors.bottom: parent.bottom
                border.width: 1
                border.color: shadowColor
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 15
                    
                    StatusIndicator {
                        icon: "⚡"
                        text: "Battery: 80%"
                    }
                    
                    StatusIndicator {
                        icon: "🛰️"
                        text: "GPS: Active"
                    }
                    
                    StatusIndicator {
                        icon: "📶"
                        text: "Network: Connected"
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: "v1.0"
                        color: "#888888"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    // Front Camera Page
    Component {
        id: frontCameraPage
        Page {
            width: parent ? parent.width : 800
            height: parent ? parent.height : 480
            
            background: Rectangle {
                color: backgroundColor
            }

            Rectangle {
                id: cameraView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: controlPanel.top
                anchors.margins: 15
                color: "#000000"
                border.color: accentColor
                border.width: 2
                radius: 8
                
                // Status overlay to show which AI model is active
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    height: activeModelText.implicitHeight + 10
                    width: activeModelText.implicitWidth + 20
                    color: processManager.isRunning ? accentColor : "transparent"
                    radius: 4
                    visible: processManager.activeModel > 0
                    opacity: 0.8
                    
                    Text {
                        id: activeModelText
                        anchors.centerIn: parent
                        text: {
                            switch (processManager.activeModel) {
                                case 1: return "Traffic Sign Recognition Active";
                                case 2: return "Drowsiness Detection Active";
                                case 3: return "Combined Model Active";
                                default: return "";
                            }
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
                
                Video {
                    id: frontCameraVideo
                    anchors.fill: parent
                    anchors.margins: 10
                    source: ""
                    autoPlay: true
                    loops: -1
                    fillMode: VideoOutput.PreserveAspectFit
                    
                    property int retryCount: 0
                    property int maxRetries: 10
                    property string videoPath: "/home/abdelrhman/Documents/traffic_signs_detection_3/output.mp4"
                    
                    // Reload video when process starts
                    Connections {
                        target: processManager
                        function onIsRunningChanged() {
                            if (processManager.isRunning && processManager.activeModel === 1) {
                                frontCameraVideo.retryCount = 0
                                reloadTimer.start()
                            } else {
                                frontCameraVideo.source = ""
                                reloadTimer.stop()
                                retryTimer.stop()
                            }
                        }
                    }
                    
                    Timer {
                        id: reloadTimer
                        interval: 3000 // Wait 3 seconds for video to be created
                        onTriggered: {
                            console.log("Attempting to load video:", frontCameraVideo.videoPath)
                            frontCameraVideo.source = ""
                            frontCameraVideo.source = frontCameraVideo.videoPath
                            // Start retry timer to check if video loads
                            retryTimer.start()
                        }
                    }
                    
                    Timer {
                        id: retryTimer
                        interval: 2000 // Retry every 2 seconds
                        repeat: true
                        onTriggered: {
                            if (frontCameraVideo.retryCount < frontCameraVideo.maxRetries && 
                                processManager.isRunning && 
                                processManager.activeModel === 1) {
                                
                                if (frontCameraVideo.hasVideo) {
                                    console.log("Video loaded successfully")
                                    retryTimer.stop()
                                    return
                                }
                                
                                frontCameraVideo.retryCount++
                                console.log("Retry", frontCameraVideo.retryCount, "loading video:", frontCameraVideo.videoPath)
                                console.log("Video hasVideo:", frontCameraVideo.hasVideo, "playing:", frontCameraVideo.playing)
                                frontCameraVideo.source = ""
                                frontCameraVideo.source = frontCameraVideo.videoPath
                            } else if (frontCameraVideo.retryCount >= frontCameraVideo.maxRetries) {
                                console.log("Max retries reached for video loading")
                                retryTimer.stop()
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        console.log("Front camera video component created")
                    }
                    
                    // Fallback text if video doesn't load
                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!processManager.isRunning || processManager.activeModel !== 1) {
                                return "Start Traffic Sign Recognition to view output"
                            } else if (frontCameraVideo.retryCount >= frontCameraVideo.maxRetries) {
                                return "Failed to load video after " + frontCameraVideo.maxRetries + " attempts"
                            } else if (!frontCameraVideo.hasVideo) {
                                return "Loading video... (attempt " + (frontCameraVideo.retryCount + 1) + ")"
                            } else {
                                return ""
                            }
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        visible: !frontCameraVideo.hasVideo || (!processManager.isRunning || processManager.activeModel !== 1)
                    }
                    
                    // Play controls overlay
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 10
                        width: 60
                        height: 30
                        color: "#B3000000"
                        radius: 5
                        visible: frontCameraVideo.hasVideo && !frontCameraVideo.playing
                        
                        Text {
                            anchors.centerIn: parent
                            text: "▶"
                            color: "white"
                            font.pixelSize: 16
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Play button clicked")
                                frontCameraVideo.play()
                            }
                        }
                    }
                }
                
                // Status message at the bottom
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: 10
                    text: processManager.statusMessage
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    visible: processManager.statusMessage !== "Ready"
                }
            }
            
            Rectangle {
                id: controlPanel
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 120
                color: surfaceColor
                border.width: 1
                border.color: shadowColor
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    
                    Components.FeatureButton {
                        buttonText: "Traffic Sign\nRecognition"
                        bgColor: processManager.activeModel === 1 ? Qt.darker(accentColor, 1.3) : accentColor
                        Layout.fillWidth: true
                        onClicked: {
                            processManager.startModel(1) // TrafficSignRecognition
                        }
                    }

                    Components.FeatureButton {
                        buttonText: "Lane\nDetection"
                        bgColor: accentColor
                        Layout.fillWidth: true
                    }

                    Components.FeatureButton {
                        buttonText: "Drowsiness +\nTraffic Sign"
                        bgColor: processManager.activeModel === 3 ? Qt.darker(accentColor, 1.3) : accentColor
                        Layout.fillWidth: true
                        onClicked: {
                            processManager.startModel(3) // Combined
                        }
                    }
                }
            }

            // Back Button
            Rectangle {
                width: 50
                height: 50
                radius: 25
                color: surfaceColor
                border.width: 1
                border.color: shadowColor
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: 15
                }
                
                Text {
                    text: "←"
                    font.pixelSize: 24
                    anchors.centerIn: parent
                    color: textColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Stop any running process when navigating back
                        if (processManager.isRunning) {
                            processManager.stopCurrentModel()
                        }
                        stackView.pop()
                    }
                }
            }
            
            // Stop button for running processes
            Rectangle {
                width: 50
                height: 50
                radius: 25
                color: processManager.isRunning ? secondaryColor : Qt.darker(surfaceColor, 1.1)
                border.width: 1
                border.color: processManager.isRunning ? Qt.darker(secondaryColor, 1.2) : shadowColor
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 15
                }
                visible: true
                enabled: processManager.isRunning
                opacity: processManager.isRunning ? 1.0 : 0.5
                
                Text {
                    text: "⏹"
                    font.pixelSize: 20
                    anchors.centerIn: parent
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (processManager.isRunning) {
                            processManager.stopCurrentModel()
                        }
                    }
                }
            }
        }
    }

    // Cabin Camera Page
    Component {
        id: cabinCameraPage
        Page {
            width: parent ? parent.width : 800
            height: parent ? parent.height : 480
            
            background: Rectangle {
                color: backgroundColor
            }

            Rectangle {
                id: cameraView
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: controlPanel.top
                anchors.margins: 15
                color: "#000000"
                border.color: accentColor
                border.width: 2
                radius: 8
                
                // Status overlay to show which AI model is active
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 10
                    height: cabinActiveModelText.implicitHeight + 10
                    width: cabinActiveModelText.implicitWidth + 20
                    color: processManager.isRunning ? accentColor : "transparent"
                    radius: 4
                    visible: processManager.activeModel > 0
                    opacity: 0.8
                    
                    Text {
                        id: cabinActiveModelText
                        anchors.centerIn: parent
                        text: {
                            switch (processManager.activeModel) {
                                case 1: return "Traffic Sign Recognition Active";
                                case 2: return "Drowsiness Detection Active";
                                case 3: return "Combined Model Active";
                                default: return "";
                            }
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
                
                Video {
                    id: cabinCameraVideo
                    anchors.fill: parent
                    anchors.margins: 10
                    source: ""
                    autoPlay: true
                    loops: -1
                    fillMode: VideoOutput.PreserveAspectFit
                    
                    property int retryCount: 0
                    property int maxRetries: 10
                    property string videoPath: "/home/abdelrhman/Documents/drowsiness_detection_f3/output.mp4"
                    
                    // Reload video when process starts
                    Connections {
                        target: processManager
                        function onIsRunningChanged() {
                            if (processManager.isRunning && processManager.activeModel === 2) {
                                cabinCameraVideo.retryCount = 0
                                cabinReloadTimer.start()
                            } else {
                                cabinCameraVideo.source = ""
                                cabinReloadTimer.stop()
                                cabinRetryTimer.stop()
                            }
                        }
                    }
                    
                    Timer {
                        id: cabinReloadTimer
                        interval: 3000 // Wait 3 seconds for video to be created
                        onTriggered: {
                            console.log("Attempting to load cabin video:", cabinCameraVideo.videoPath)
                            cabinCameraVideo.source = ""
                            cabinCameraVideo.source = cabinCameraVideo.videoPath
                            // Start retry timer to check if video loads
                            cabinRetryTimer.start()
                        }
                    }
                    
                    Timer {
                        id: cabinRetryTimer
                        interval: 2000 // Retry every 2 seconds
                        repeat: true
                        onTriggered: {
                            if (cabinCameraVideo.retryCount < cabinCameraVideo.maxRetries && 
                                processManager.isRunning && 
                                processManager.activeModel === 2) {
                                
                                if (cabinCameraVideo.hasVideo) {
                                    console.log("Cabin video loaded successfully")
                                    cabinRetryTimer.stop()
                                    return
                                }
                                
                                cabinCameraVideo.retryCount++
                                console.log("Retry", cabinCameraVideo.retryCount, "loading cabin video:", cabinCameraVideo.videoPath)
                                console.log("Cabin video hasVideo:", cabinCameraVideo.hasVideo, "playing:", cabinCameraVideo.playing)
                                cabinCameraVideo.source = ""
                                cabinCameraVideo.source = cabinCameraVideo.videoPath
                            } else if (cabinCameraVideo.retryCount >= cabinCameraVideo.maxRetries) {
                                console.log("Max retries reached for cabin video loading")
                                cabinRetryTimer.stop()
                            }
                        }
                    }
                    
                    Component.onCompleted: {
                        console.log("Cabin camera video component created")
                    }
                    
                    // Fallback text if video doesn't load
                    Text {
                        anchors.centerIn: parent
                        text: {
                            if (!processManager.isRunning || processManager.activeModel !== 2) {
                                return "Start Drowsiness Detection to view output"
                            } else if (cabinCameraVideo.retryCount >= cabinCameraVideo.maxRetries) {
                                return "Failed to load video after " + cabinCameraVideo.maxRetries + " attempts"
                            } else if (!cabinCameraVideo.hasVideo) {
                                return "Loading video... (attempt " + (cabinCameraVideo.retryCount + 1) + ")"
                            } else {
                                return ""
                            }
                        }
                        color: "#FFFFFF"
                        font.pixelSize: 18
                        visible: !cabinCameraVideo.hasVideo || (!processManager.isRunning || processManager.activeModel !== 2)
                    }
                    
                    // Play controls overlay
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.margins: 10
                        width: 60
                        height: 30
                        color: "#B3000000"
                        radius: 5
                        visible: cabinCameraVideo.hasVideo && !cabinCameraVideo.playing
                        
                        Text {
                            anchors.centerIn: parent
                            text: "▶"
                            color: "white"
                            font.pixelSize: 16
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                console.log("Cabin play button clicked")
                                cabinCameraVideo.play()
                            }
                        }
                    }
                }
                
                // Status message at the bottom
                Text {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: 10
                    text: processManager.statusMessage
                    color: "#FFFFFF"
                    font.pixelSize: 14
                    visible: processManager.statusMessage !== "Ready"
                }
            }
            
            Rectangle {
                id: controlPanel
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 120
                color: surfaceColor
                border.width: 1
                border.color: shadowColor
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    
                    Components.FeatureButton {
                        buttonText: "Distraction\nMonitoring"
                        bgColor: accentColor
                        Layout.fillWidth: true
                    }

                    Components.FeatureButton {
                        buttonText: "Drowsiness\nDetection"
                        bgColor: processManager.activeModel === 2 ? Qt.darker(accentColor, 1.3) : accentColor
                        Layout.fillWidth: true
                        onClicked: {
                            processManager.startModel(2) // Drowsiness
                        }
                    }
                }
            }

            // Back Button
            Rectangle {
                width: 50
                height: 50
                radius: 25
                color: surfaceColor
                border.width: 1
                border.color: shadowColor
                anchors {
                    top: parent.top
                    left: parent.left
                    margins: 15
                }
                
                Text {
                    text: "←"
                    font.pixelSize: 24
                    anchors.centerIn: parent
                    color: textColor
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        // Stop any running process when navigating back
                        if (processManager.isRunning) {
                            processManager.stopCurrentModel()
                        }
                        stackView.pop()
                    }
                }
            }
            
            // Stop button for running processes
            Rectangle {
                width: 50
                height: 50
                radius: 25
                color: processManager.isRunning ? secondaryColor : Qt.darker(surfaceColor, 1.1)
                border.width: 1
                border.color: processManager.isRunning ? Qt.darker(secondaryColor, 1.2) : shadowColor
                anchors {
                    top: parent.top
                    right: parent.right
                    margins: 15
                }
                visible: true
                enabled: processManager.isRunning
                opacity: processManager.isRunning ? 1.0 : 0.5
                
                Text {
                    text: "⏹"
                    font.pixelSize: 20
                    anchors.centerIn: parent
                    color: "white"
                }
                
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (processManager.isRunning) {
                            processManager.stopCurrentModel()
                        }
                    }
                }
            }
        }
    }

    // Speech Recognition Popup
    Popup {
        id: speechPopup
        anchors.centerIn: parent
        width: 300
        height: 200
        modal: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: surfaceColor
            radius: 15
            border.color: accentColor
            border.width: 2
        }

        Column {
            anchors.centerIn: parent
            spacing: 20

            Text {
                text: "🎤"
                font.pixelSize: 48
                anchors.horizontalCenter: parent.horizontalCenter
                color: accentColor
            }

            Text {
                text: "Listening..."
                color: textColor
                font.pixelSize: 24
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                width: 200
                height: 4
                color: subtleColor
                anchors.horizontalCenter: parent.horizontalCenter
                
                Rectangle {
                    property int position: 0
                    id: animatedBar
                    width: 50
                    height: parent.height
                    color: accentColor
                    
                    NumberAnimation on position {
                        from: 0
                        to: 150
                        duration: 2000
                        loops: Animation.Infinite
                        running: speechPopup.visible
                    }
                    
                    x: animatedBar.position
                }
            }
        }
    }
    
    // Custom Components
    
    // Status Indicator Component
    component StatusIndicator: RowLayout {
        property string icon: ""
        property string text: ""
        spacing: 5
        
        Text {
            text: icon
            font.pixelSize: 16
        }
        
        Text {
            text: text
            color: textColor
            font.pixelSize: 14
        }
    }
    
    // Dashboard Button Component
    component DashboardButton: Rectangle {
        id: dashBtn
        signal clicked()
        property string buttonText: ""
        property string iconText: ""
        
        height: 90
        radius: 10
        color: surfaceColor
        border.color: subtleColor
        border.width: 1
        
        Column {
            anchors.centerIn: parent
            spacing: 5
            
            Text {
                text: iconText
                font.pixelSize: 24
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Text {
                text: buttonText
                color: textColor
                font.pixelSize: 14
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
        
        MouseArea {
            anchors.fill: parent
            onClicked: {
                parent.scale = 0.95
                clickTimer.start()
                dashBtn.clicked()
            }
        }
        
        Timer {
            id: clickTimer
            interval: 100
            onTriggered: parent.scale = 1.0
        }
        
        // Hover effect
        states: State {
            name: "hovered"
            when: mouseArea.containsMouse
            PropertyChanges {
                target: dashBtn
                border.color: accentColor
            }
        }
        
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: dashBtn.clicked()
        }
    }

    // Settings Popup
    Popup {
        id: settingsPopup
        width: 300
        height: 200
        modal: true
        anchors.centerIn: parent
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: surfaceColor
            radius: 10
            border.color: accentColor
            border.width: 2
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10
            
            Text {
                text: "Settings"
                font.pixelSize: 20
                font.bold: true
                color: textColor
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle {
                height: 1
                color: subtleColor
                Layout.fillWidth: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: "Dark Mode"
                    color: textColor
                    font.pixelSize: 16
                }
                
                Item { Layout.fillWidth: true }
                
                Switch {
                    checked: darkMode
                    onCheckedChanged: {
                        darkMode = checked
                    }
                }
            }
        }
    }
    
    // Debug Popup
    Popup {
        id: debugPopup
        width: 500
        height: 400
        modal: true
        anchors.centerIn: parent
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        background: Rectangle {
            color: surfaceColor
            radius: 10
            border.color: accentColor
            border.width: 2
        }
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10
            
            Text {
                text: "Debug Information"
                font.pixelSize: 20
                font.bold: true
                color: textColor
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle {
                height: 1
                color: subtleColor
                Layout.fillWidth: true
            }
            
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Column {
                    width: parent.width
                    spacing: 10
                    
                    Text {
                        text: "Python Executable: " + processManager.pythonExecutable
                        color: textColor
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    
                    Text {
                        text: "Traffic Sign Path: " + processManager.getTrafficSignPath()
                        color: textColor
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    
                    Text {
                        text: "Drowsiness Path: " + processManager.getDrowsinessPath()
                        color: textColor
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                    
                    Text {
                        text: "Status: " + processManager.statusMessage
                        color: textColor
                        font.pixelSize: 12
                        wrapMode: Text.Wrap
                        width: parent.width
                    }
                }
            }
            
            Rectangle {
                height: 1
                color: subtleColor
                Layout.fillWidth: true
            }
            
            RowLayout {
                Layout.fillWidth: true
                
                Components.FeatureButton {
                    buttonText: "Test Python"
                    Layout.fillWidth: true
                    onClicked: {
                        processManager.testPythonEnvironment()
                    }
                }
                
                Components.FeatureButton {
                    buttonText: "Close"
                    Layout.fillWidth: true
                    onClicked: debugPopup.close()
                }
            }
        }
    }
}
