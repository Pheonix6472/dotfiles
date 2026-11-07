import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: Colors.surface

    readonly property string ff: config.font ? config.font : "sans-serif"
    property bool failed: false
    property string userName: users.currentItem ? users.currentItem.uname : ""
    property string realName: (users.currentItem && users.currentItem.rname !== "") ? users.currentItem.rname : userName
    property real intro: 0

    NumberAnimation on intro { from: 0; to: 1; duration: 1600; easing.type: Easing.OutCubic }
    Component.onCompleted: pw.forceActiveFocus()

    function doLogin() {
        console.log("doLogin user=" + root.userName + " pwlen=" + pw.text.length + " session=" + sessions.currentIndex)
        console.log("doLogin user=" + root.userName + " pwlen=" + pw.text.length + " session=" + sessions.currentIndex)
        console.log("doLogin user=" + root.userName + " pwlen=" + pw.text.length + " session=" + sessions.currentIndex)
        if (pw.text.length === 0) return
        root.failed = false
        sddm.login(root.userName, pw.text, sessions.currentIndex)
    }

    // ---- hidden models ----
    ListView {
        id: users
        width: 1; height: 1; visible: false
        model: userModel
        currentIndex: userModel.lastIndex
        delegate: Item {
            width: 1; height: 1
            property string uname: model.name
            property string rname: model.realName
        }
    }
    ListView {
        id: sessions
        width: 1; height: 1; visible: false
        model: sessionModel
        currentIndex: sessionModel.lastIndex
        delegate: Item {
            width: 1; height: 1
            property string sname: model.name
        }
    }

    Timer {
        id: clk
        property date now: new Date()
        interval: 1000; running: true; repeat: true
        onTriggered: now = new Date()
    }

    // ---- wallpaper ----
    Image {
        id: wall
        anchors.fill: parent
        source: "Backgrounds/wall.jpg"
        fillMode: Image.PreserveAspectCrop
        cache: false
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 64
            blur: (pw.activeFocus || root.failed) ? 0.9 : 0.35
            brightness: -0.1
            saturation: 0.2
            Behavior on blur { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        }
    }

    // tint + vignette
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.alpha(Colors.primary, 0.22) }
            GradientStop { position: 0.55; color: Qt.alpha(Colors.surface, 0.10) }
            GradientStop { position: 1.0; color: Qt.alpha(Colors.tertiary, 0.20) }
        }
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(Colors.surface, 0.10) }
            GradientStop { position: 1.0; color: Qt.alpha(Colors.surface, 0.85) }
        }
    }

    // ---- giant clock ----
    Column {
        id: clockBlock
        anchors.left: parent.left
        anchors.leftMargin: 120
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 100
        opacity: root.intro
        spacing: -10
        transform: Translate { y: (1 - root.intro) * 60 }

        Text {
            text: sddm.hostName.toUpperCase()
            color: Colors.primary
            font.family: root.ff
            font.pixelSize: 20
            font.letterSpacing: 10
            font.weight: Font.Bold
        }
        Row {
            Text {
                text: Qt.formatDateTime(clk.now, "HH")
                color: Colors.surfaceForeground
                font.family: root.ff
                font.pixelSize: 240
                font.weight: Font.Black
            }
            Text {
                text: ":"
                color: Colors.primary
                font.family: root.ff
                font.pixelSize: 240
                font.weight: Font.Black
                opacity: (clk.now.getSeconds() % 2 === 0) ? 1.0 : 0.2
                Behavior on opacity { NumberAnimation { duration: 400 } }
            }
            Text {
                text: Qt.formatDateTime(clk.now, "mm")
                color: Colors.primary
                font.family: root.ff
                font.pixelSize: 240
                font.weight: Font.Black
            }
        }
        Text {
            text: Qt.formatDateTime(clk.now, "dddd, d. MMMM yyyy")
            color: Colors.surfaceVariantForeground
            font.family: root.ff
            font.pixelSize: 34
            leftPadding: 10
        }
    }

    // ---- login card ----
    Rectangle {
        id: card
        property real shakeX: 0
        width: 470
        height: 690
        radius: 40
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width - width - 170 + (1 - root.intro) * 100 + shakeX
        opacity: root.intro
        color: Qt.alpha(Colors.surfaceContainer, 0.60)
        border.width: 1
        border.color: Qt.alpha(root.failed ? Colors.error : Colors.primary, 0.45)
        Behavior on border.color { ColorAnimation { duration: 300 } }

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: card; property: "shakeX"; to: 22; duration: 60 }
            NumberAnimation { target: card; property: "shakeX"; to: -22; duration: 90 }
            NumberAnimation { target: card; property: "shakeX"; to: 12; duration: 70 }
            NumberAnimation { target: card; property: "shakeX"; to: 0; duration: 60 }
        }

        Column {
            anchors.centerIn: parent
            width: 360
            spacing: 22

            // avatar
Item {
    id: carousel
    width: 360
    height: 250

    Shortcut { sequence: "Ctrl+Right"; onActivated: if (users.count > 1) users.currentIndex = (users.currentIndex + 1) % users.count }
    Shortcut { sequence: "Ctrl+Left"; onActivated: if (users.count > 1) users.currentIndex = (users.currentIndex - 1 + users.count) % users.count }
    Connections {
        target: users
        function onCurrentIndexChanged() { pw.text = ""; root.failed = false }
    }

    Rectangle {
        id: glowSrc
        anchors.centerIn: parent
        width: 210; height: 210; radius: 105
        color: Colors.primary
        layer.enabled: true
        visible: false
    }
    MultiEffect {
        anchors.centerIn: parent
        width: 300; height: 300
        source: glowSrc
        blurEnabled: true
        blurMax: 64
        blur: 1.0
        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation { to: 0.8; duration: 2200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.3; duration: 2200; easing.type: Easing.InOutSine }
        }
    }

    Repeater {
        model: userModel
        delegate: Item {
            id: av
            readonly property int off: index - users.currentIndex
            readonly property real dist: Math.abs(off)
            width: 210
            height: 210
            anchors.verticalCenter: parent.verticalCenter
            x: (carousel.width - width) / 2 + off * 92
            z: 10 - dist
            scale: Math.max(0.4, 1 - dist * 0.3) * ((off === 0 && avMouse.containsMouse) ? 1.06 : 1.0)
            opacity: dist > 2 ? 0 : 1 - dist * 0.35
            visible: opacity > 0.01
            Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
            Behavior on opacity { NumberAnimation { duration: 450 } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Colors.primaryContainer
                visible: avImg.status !== Image.Ready
                Text {
                    anchors.centerIn: parent
                    text: model.name.charAt(0).toUpperCase()
                    color: Colors.primaryContainerForeground
                    font.family: root.ff
                    font.pixelSize: 90
                    font.weight: Font.Bold
                }
            }
            Image {
                id: avImg
                anchors.fill: parent
                source: "Assets/avatars/" + model.name + ".png"
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(420, 420)
                smooth: true
                mipmap: true
                visible: false
            }
            Rectangle {
                id: avMask
                anchors.fill: parent
                radius: width / 2
                layer.enabled: true
                layer.samples: 4
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: avImg
                visible: avImg.status === Image.Ready
                maskEnabled: true
                maskSource: avMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                brightness: av.off === 0 ? 0 : -0.3
                saturation: av.off === 0 ? 0 : -0.5
                Behavior on brightness { NumberAnimation { duration: 450 } }
                Behavior on saturation { NumberAnimation { duration: 450 } }
            }
            MouseArea {
                id: avMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: av.off === 0 ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: if (av.off !== 0) users.currentIndex = index
            }
        }
    }

    Shape {
        id: ring
        z: 20
        anchors.centerIn: parent
        width: 250
        height: 250
        preferredRendererType: Shape.CurveRenderer
        NumberAnimation on rotation { from: 0; to: 360; duration: 8000; loops: Animation.Infinite }
        ShapePath {
            strokeColor: "transparent"
            strokeWidth: 0
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
                centerX: 125; centerY: 125; angle: 0
                GradientStop { position: 0.0; color: Colors.primary }
                GradientStop { position: 0.45; color: Colors.tertiary }
                GradientStop { position: 0.8; color: Qt.alpha(Colors.primary, 0.0) }
                GradientStop { position: 1.0; color: Colors.primary }
            }
            PathAngleArc { centerX: 125; centerY: 125; radiusX: 125; radiusY: 125; startAngle: 0; sweepAngle: 360 }
            PathAngleArc { centerX: 125; centerY: 125; radiusX: 119; radiusY: 119; startAngle: 0; sweepAngle: 360 }
        }
    }
}
            // name
            Column {
                width: 360
                spacing: 4
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.realName
                    elide: Text.ElideRight
                    color: Colors.surfaceForeground
                    font.family: root.ff
                    font.pixelSize: 34
                    font.weight: Font.Bold
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.failed ? "ACCESS DENIED" : ("@" + root.userName)
                    color: root.failed ? Colors.error : Colors.primary
                    font.family: root.ff
                    font.pixelSize: 16
                    font.letterSpacing: 5
                    font.weight: Font.DemiBold
                }
            }

            // password
            Rectangle {
                id: pwBox
                width: 360
                height: 64
                radius: 32
                color: Colors.surfaceContainerHigh
                border.width: 2
                border.color: root.failed ? Colors.error : (pw.activeFocus ? Colors.primary : Colors.outlineVariant)
                Behavior on border.color { ColorAnimation { duration: 250 } }

                TextField {
                    id: pw
                    anchors.fill: parent
                    leftPadding: 28
                    rightPadding: 72
                    echoMode: TextInput.Password
                    passwordCharacter: "●"
                    placeholderText: "password"
                    placeholderTextColor: Colors.surfaceVariantForeground
                    color: Colors.surfaceForeground
                    font.family: root.ff
                    font.pixelSize: 20
                    verticalAlignment: TextInput.AlignVCenter
                    background: Item {}
                    onAccepted: root.doLogin()
                    onTextChanged: root.failed = false
                    Keys.onEscapePressed: text = ""
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    width: 48; height: 48; radius: 24
                    color: goMouse.containsMouse ? Colors.tertiary : Colors.primary
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent
                        text: "→"
                        color: Colors.primaryForeground
                        font.pixelSize: 26
                        font.weight: Font.Bold
                    }
                    MouseArea {
                        id: goMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.doLogin()
                    }
                }
            }

            // session pill
            Item {
                width: 360
                height: 38
                Rectangle {
                    anchors.centerIn: parent
                    width: sessText.implicitWidth + 44
                    height: 38
                    radius: 19
                    color: sessMouse.containsMouse ? Colors.primaryContainer : "transparent"
                    border.width: 1
                    border.color: Colors.outlineVariant
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        id: sessText
                        anchors.centerIn: parent
                        text: sessions.currentItem ? sessions.currentItem.sname.toUpperCase() : "SESSION"
                        color: Colors.surfaceVariantForeground
                        font.family: root.ff
                        font.pixelSize: 14
                        font.letterSpacing: 4
                    }
                    MouseArea {
                        id: sessMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: if (sessions.count > 1) sessions.currentIndex = (sessions.currentIndex + 1) % sessions.count
                    }
                }
            }

            // power row
            Row {
                width: 360
                height: 40
                spacing: 12
                Repeater {
                    model: ["SLEEP", "REBOOT", "SHUTDOWN"]
                    delegate: Rectangle {
                        width: (360 - 24) / 3
                        height: 40
                        radius: 20
                        color: pMouse.containsMouse ? (index === 2 ? Colors.error : Colors.primary) : Colors.surfaceContainerHigh
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: pMouse.containsMouse ? Colors.primaryForeground : Colors.surfaceVariantForeground
                            font.family: root.ff
                            font.pixelSize: 12
                            font.letterSpacing: 3
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: pMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (index === 0) sddm.suspend()
                                else if (index === 1) sddm.reboot()
                                else sddm.powerOff()
                            }
                        }
                    }
                }
            }
        }
    }

    // ---- login result handling ----
    Connections {
        target: sddm
        function onLoginFailed() {
            console.log("loginFailed")
            console.log("loginFailed")
            console.log("loginFailed")
            root.failed = true
            pw.text = ""
            root.failed = true
            shakeAnim.restart()
            pw.forceActiveFocus()
        }
        function onLoginSucceeded() {
            fadeOut.start()
        }
    }

    Rectangle {
        id: veil
        anchors.fill: parent
        z: 100
        color: Colors.surface
        opacity: 0
        NumberAnimation on opacity { id: fadeOut; running: false; to: 1; duration: 500 }
    }
}
