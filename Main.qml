import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import "qml/pages"

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 800
    height: 480
    title: "NeuroDrive Dashboard"

    // Global properties
    property color accentColor: "#0066CC"  // Darker blue
    property color secondaryColor: "#FF6B35"  // Warmer orange accent
    property color backgroundColor: "#F5F5F5"  // Light gray/off-white
    property color surfaceColor: "#FFFFFF"  // Pure white
    property color textColor: "#212121"  // Dark gray, almost black
    property color subtleColor: "#E0E0E0"  // Light gray for borders
    property color shadowColor: "#DDDDDD"  // Shadow color

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
        Item {
            anchors.fill: parent
            
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
                            color: Qt.darker(textColor, 0.7)
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
        Rectangle {
            color: backgroundColor

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
                
                Text {
                    anchors.centerIn: parent
                    text: "Camera Feed"
                    color: "#FFFFFF"
                    font.pixelSize: 24
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
                    
                    FeatureButton {
                        buttonText: "Road Sign\nRecognition"
                        bgColor: accentColor
                        Layout.fillWidth: true
                    }

                    FeatureButton {
                        buttonText: "Lane\nDetection"
                        bgColor: accentColor
                        Layout.fillWidth: true
                    }

                    FeatureButton {
                        buttonText: "Object\nDetection"
                        bgColor: accentColor
                        Layout.fillWidth: true
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
                    onClicked: stackView.pop()
                }
            }
        }
    }

    // Cabin Camera Page
    Component {
        id: cabinCameraPage
        Rectangle {
            color: backgroundColor

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
                
                Text {
                    anchors.centerIn: parent
                    text: "Cabin Camera Feed"
                    color: "#FFFFFF"
                    font.pixelSize: 24
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
                    
                    FeatureButton {
                        buttonText: "Drowsiness\nDetection"
                        bgColor: accentColor
                        Layout.fillWidth: true
                    }

                    FeatureButton {
                        buttonText: "Distraction\nMonitoring"
                        bgColor: accentColor
                        Layout.fillWidth: true
                    }

                    FeatureButton {
                        buttonText: "Face\nRecognition"
                        bgColor: accentColor
                        Layout.fillWidth: true
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
                    onClicked: stackView.pop()
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
}
