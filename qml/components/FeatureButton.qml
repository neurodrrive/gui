import QtQuick
import QtQuick.Controls

Rectangle {
    id: featureBtn
    property string buttonText: ""
    property color bgColor: "gray"
    property bool isHovered: false
    property bool pressed: false
    
    signal clicked()

    width: 300
    height: 60
    color: bgColor
    radius: 10
    border.width: 1
    border.color: Qt.darker(bgColor, 1.2)
    
    Text {
        anchors.centerIn: parent
        text: buttonText
        color: "white"
        font.bold: true
        font.pixelSize: 16
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }

    // Gradient overlay with dark mode considerations
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.15) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
        }
    }

    // Add a simple shadow/glow effect without using FastBlur
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: parent.radius + 2
        color: "transparent"
        border.width: featureBtn.isHovered ? 4 : 0
        border.color: Qt.alpha(Qt.lighter(bgColor, 1.3), 0.5)
        z: -1
        
        Behavior on border.width { 
            NumberAnimation { duration: 200 } 
        }
    }

    // Click animation
    states: State {
        name: "pressed"
        when: featureBtn.pressed
        PropertyChanges {
            target: featureBtn
            scale: 0.95
        }
    }
    
    transitions: Transition {
        from: ""; to: "pressed"; reversible: true
        PropertyAnimation { properties: "scale"; duration: 100 }
    }
    
    // Mouse handling
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        
        onPressed: featureBtn.pressed = true
        onReleased: featureBtn.pressed = false
        onClicked: featureBtn.clicked()
        
        onEntered: {
            featureBtn.isHovered = true
            featureBtn.border.color = Qt.lighter(bgColor, 1.3)
            featureBtn.border.width = 2
        }
        
        onExited: {
            featureBtn.isHovered = false
            featureBtn.border.color = Qt.darker(bgColor, 1.2)
            featureBtn.border.width = 1
        }
    }
} 