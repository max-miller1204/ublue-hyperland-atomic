import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 640
    height: 480
    color: "#1a1b26"

    property int sessionIndex: session.index

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginSucceeded() { }
        function onLoginFailed() {
            password.text = ""
            errorMessage.text = textConstants.loginFailed
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 12
        width: 300

        Text {
            text: textConstants.welcomeText.arg(sddm.hostName)
            color: "#c0caf5"
            font.pixelSize: 24
            font.family: "JetBrains Mono"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        ComboBox {
            id: session
            width: parent.width
            height: 36
            model: sessionModel
            index: sessionModel.lastIndex
            color: "#24283b"
            textColor: "#c0caf5"
            borderColor: "#414868"
            focusColor: "#7aa2f7"
            hoverColor: "#414868"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
        }

        TextBox {
            id: username
            width: parent.width
            height: 36
            text: userModel.lastUser
            font.pixelSize: 13
            font.family: "JetBrains Mono"
            color: "#24283b"
            textColor: "#c0caf5"
            borderColor: "#414868"
            focusColor: "#7aa2f7"
            hoverColor: "#414868"
            KeyNavigation.tab: password
            Keys.onPressed: {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    sddm.login(username.text, password.text, sessionIndex)
                    event.accepted = true
                }
            }
        }

        PasswordBox {
            id: password
            width: parent.width
            height: 36
            font.pixelSize: 13
            font.family: "JetBrains Mono"
            color: "#24283b"
            textColor: "#c0caf5"
            borderColor: "#414868"
            focusColor: "#7aa2f7"
            hoverColor: "#414868"
            tooltipBG: "#24283b"
            tooltipFG: "#c0caf5"
            KeyNavigation.backtab: username
            Keys.onPressed: {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    sddm.login(username.text, password.text, sessionIndex)
                    event.accepted = true
                }
            }
        }

        Text {
            id: errorMessage
            color: "#f7768e"
            font.pixelSize: 12
            font.family: "JetBrains Mono"
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Button {
            id: loginButton
            text: textConstants.login
            width: parent.width
            height: 36
            color: "#7aa2f7"
            textColor: "#1a1b26"
            activeColor: "#89b4fa"
            pressedColor: "#5d7cbf"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
            onClicked: sddm.login(username.text, password.text, sessionIndex)
        }

        Row {
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter

            ImageButton {
                id: shutdownButton
                source: "shutdown.svg"
                height: 32
                width: 32
                onClicked: sddm.powerOff()
            }

            ImageButton {
                id: rebootButton
                source: "reboot.svg"
                height: 32
                width: 32
                onClicked: sddm.reboot()
            }
        }
    }

    Component.onCompleted: {
        if (username.text === "") {
            username.focus = true
        } else {
            password.focus = true
        }
    }
}
