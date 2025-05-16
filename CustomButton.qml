import QtQuick
import QtQuick.Controls

Button {
    id: customBtn
    property string buttonText: ""
    property color buttonColor: "gray"

    contentItem: Text {
        text: buttonText
        color: "white"
        font.bold: true
        font.pixelSize: 16
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    background: Rectangle {
        id: bgRect
        color: buttonColor
        radius: 10
        border.width: 2
        border.color: Qt.darker(buttonColor, 1.2)
        
        // Gradient overlay
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.15) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.05) }
            }
        }
    }

    width: 150
    height: 100
    
    // Click animation
    states: State {
        name: "pressed"
        when: customBtn.pressed
        PropertyChanges {
            target: customBtn
            scale: 0.95
        }
    }
    
    transitions: Transition {
        from: ""; to: "pressed"; reversible: true
        PropertyAnimation { properties: "scale"; duration: 100 }
    }
    
    // Hover effect
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                bgRect.border.color = Qt.lighter(buttonColor, 1.3)
                bgRect.border.width = 3
            } else {
                bgRect.border.color = Qt.darker(buttonColor, 1.2)
                bgRect.border.width = 2
            }
        }
    }
}
