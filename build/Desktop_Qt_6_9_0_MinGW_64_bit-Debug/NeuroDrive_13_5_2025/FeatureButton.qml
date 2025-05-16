import QtQuick
import QtQuick.Controls

Button {
    id: featureBtn
    property string buttonText: ""
    property color bgColor: "gray"

    contentItem: Text {
        text: buttonText
        color: "white"
        font.bold: true
        font.pixelSize: 14
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        wrapMode: Text.WordWrap
    }

    background: Rectangle {
        id: bgRect
        color: bgColor
        radius: 10
        border.width: 1
        border.color: Qt.darker(bgColor, 1.2)
        
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
    
    // Hover effect
    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                bgRect.border.color = Qt.lighter(bgColor, 1.3)
                bgRect.border.width = 2
            } else {
                bgRect.border.color = Qt.darker(bgColor, 1.2)
                bgRect.border.width = 1
            }
        }
    }

    width: 300
    height: 60
}


