import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root
    
    // Signals
    signal loginSuccessful()
    signal loginFailed(string errorMessage)
    
    // Properties
    property string imagePath: "img/youssef.jpg"
    property string carId: "111"
    
    Rectangle {
        anchors.fill: parent
        color: mainWindow.backgroundColor
        
        Rectangle {
            id: loginBox
            width: 400
            height: 350
            radius: 15
            color: mainWindow.surfaceColor
            border.color: mainWindow.subtleColor
            border.width: 1
            anchors.centerIn: parent
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 30
                width: parent.width - 80
                
                Text {
                    text: "NEURODRIVE"
                    font.pixelSize: 32
                    font.bold: true
                    color: mainWindow.accentColor
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Image {
                    id: profileImage
                    source: imagePath
                    width: 120
                    height: 120
                    fillMode: Image.PreserveAspectCrop
                    Layout.alignment: Qt.AlignHCenter
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        border.width: 3
                        border.color: mainWindow.accentColor
                        clip: true
                    }
                    
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: profileImage.width
                            height: profileImage.height
                            radius: width / 2
                        }
                    }
                }
                
                Rectangle {
                    id: loginButton
                    Layout.fillWidth: true
                    height: 60
                    radius: 10
                    color: mainWindow.accentColor
                    
                    Text {
                        text: "LOGIN"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 18
                        anchors.centerIn: parent
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            parent.scale = 0.95
                            loginClickTimer.start()
                            
                            // Call the network service to verify the driver
                            var success = networkService.verifyDriver(carId, imagePath)
                            if (!success) {
                                loginFailed("Failed to initialize login request")
                            }
                        }
                    }
                    
                    Timer {
                        id: loginClickTimer
                        interval: 100
                        onTriggered: loginButton.scale = 1.0
                    }
                }
                
                // Status message
                Text {
                    id: statusMessage
                    Layout.fillWidth: true
                    color: mainWindow.textColor
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    visible: false
                }
            }
        }
    }
    
    // Connect to the signal from NetworkService
    Connections {
        target: networkService
        
        function onVerificationComplete(success, message) {
            statusMessage.text = message
            statusMessage.visible = true
            
            if (success) {
                statusMessage.color = "green"
                // Delay before proceeding to dashboard
                successTimer.start()
            } else {
                statusMessage.color = "red"
            }
        }
    }
    
    Timer {
        id: successTimer
        interval: 1000
        onTriggered: {
            loginSuccessful()
        }
    }
} 