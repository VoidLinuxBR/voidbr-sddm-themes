// VoidBR Modern — tema do greeter SDDM (Qt6)
// Visual no estilo do greeter do Umbriel (noctalia): fundo com véu escuro,
// relógio à esquerda, cartão de login à direita, energia no canto.
// Feito para teclado: o foco começa na senha; Tab percorre senha → sessão →
// usuário → entrar → suspender → reiniciar → desligar → senha (KeyNavigation;
// itens ocultos ou desabilitados são pulados); Shift+Tab faz o inverso.
// Enter entra (no campo de senha) ou ativa o botão focado.
import QtQuick
import QtQuick.Controls.Basic
import "components"

Item {
    id: root

    width: 1920
    height: 1080

    // escala a partir do layout de referência (1440x810)
    readonly property real s: Math.max(0.6, Math.min(width / 1440, height / 810))

    // ---- cores (Material escuro, como o noctalia) ----
    readonly property color accent: config.accent || "#cfbcff"
    readonly property color onAccent: config.onAccent || "#21005d"
    readonly property color onSurface: "#e6e0e9"
    readonly property color muted: "#cac4d0"
    readonly property color outline: "#49454f"
    readonly property color field: "#1d1b20"
    readonly property color card: Qt.rgba(43 / 255, 41 / 255, 48 / 255, 0.88)
    readonly property color popupBg: "#211f26"
    readonly property color error: "#ffb4ab"
    readonly property string fontFamily: config.fontFamily || "Noto Sans"

    // ---- usuários (cópia do userModel para acessar por índice) ----
    property var users: []
    readonly property var currentUser: users.length > 0 && userBox.currentIndex >= 0
                                       ? users[Math.min(userBox.currentIndex, users.length - 1)]
                                       : ({ "name": userModel.lastUser || "", "realName": "", "icon": "" })
    readonly property string displayName: currentUser.realName && currentUser.realName.length > 0
                                          ? currentUser.realName : currentUser.name

    Repeater {
        model: userModel
        delegate: Item {
            required property string name
            required property string realName
            required property string icon
            Component.onCompleted: root.users = root.users.concat([{ "name": name, "realName": realName, "icon": icon }])
        }
    }

    function doLogin() {
        if (!root.currentUser.name)
            return;
        errorText.text = "";
        sddm.login(root.currentUser.name, password.text, sessionBox.currentIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = "";
            errorText.text = "Senha incorreta. Tente novamente.";
            shake.restart();
            password.forceActiveFocus();
        }
    }

    // ---- fundo ----
    Rectangle {
        anchors.fill: parent
        color: "#141218"
    }
    Image {
        anchors.fill: parent
        source: config.background || "Assets/background.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }
    Rectangle {
        anchors.fill: parent
        color: "#100d16"
        opacity: config.dimOpacity ? Number(config.dimOpacity) : 0.45
    }

    // ---- faixa do topo ----
    Item {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: 56 * root.s

        Row {
            anchors { left: parent.left; leftMargin: 32 * root.s; verticalCenter: parent.verticalCenter }
            spacing: 12 * root.s
            Image {
                source: "Assets/logo.svg"
                sourceSize.width: 26 * root.s
                sourceSize.height: 26 * root.s
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: "VoidBR"
                color: root.onSurface
                font { family: root.fontFamily; pixelSize: 15 * root.s; weight: Font.DemiBold }
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: sddm.hostName
                color: root.muted
                font { family: root.fontFamily; pixelSize: 14 * root.s }
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors { right: parent.right; rightMargin: 32 * root.s; verticalCenter: parent.verticalCenter }
            spacing: 6 * root.s
            Image {
                source: "Assets/icons/keyboard.svg"
                sourceSize.width: 18 * root.s
                sourceSize.height: 18 * root.s
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: keyboard.layouts.length > 0 && keyboard.currentLayout >= 0
                      ? keyboard.layouts[keyboard.currentLayout].shortName.toUpperCase() : "BR"
                color: root.muted
                font { family: root.fontFamily; pixelSize: 14 * root.s }
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    // ---- relógio ----
    Column {
        id: clock
        x: 96 * root.s
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * root.s

        property date now: new Date()
        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.now = new Date()
        }

        Text {
            text: Qt.formatTime(clock.now, config.clockFormat || "HH:mm")
            color: root.onSurface
            font { family: root.fontFamily; pixelSize: 112 * root.s; weight: Font.DemiBold; letterSpacing: -3 * root.s }
        }
        Text {
            text: Qt.locale(config.dateLocale || "pt_BR").toString(clock.now, "dddd, d 'de' MMMM")
            color: root.muted
            font { family: root.fontFamily; pixelSize: 22 * root.s; weight: Font.Medium }
        }
    }

    // ---- cartão de login ----
    Rectangle {
        id: loginCard
        width: 400 * root.s
        height: cardColumn.implicitHeight + 56 * root.s
        anchors { right: parent.right; rightMargin: 120 * root.s; verticalCenter: parent.verticalCenter }
        radius: 12 * root.s
        color: root.card
        border.width: 1
        border.color: root.outline

        SequentialAnimation {
            id: shake
            NumberAnimation { target: loginCard; property: "anchors.rightMargin"; to: 132 * root.s; duration: 50 }
            NumberAnimation { target: loginCard; property: "anchors.rightMargin"; to: 108 * root.s; duration: 70 }
            NumberAnimation { target: loginCard; property: "anchors.rightMargin"; to: 126 * root.s; duration: 60 }
            NumberAnimation { target: loginCard; property: "anchors.rightMargin"; to: 120 * root.s; duration: 50 }
        }

        Column {
            id: cardColumn
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 28 * root.s }
            spacing: 18 * root.s

            // avatar: foto do usuário (~/.face.icon) ou a inicial
            Rectangle {
                width: 88 * root.s
                height: 88 * root.s
                radius: width / 2
                color: root.accent
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true

                Text {
                    anchors.centerIn: parent
                    visible: avatar.status !== Image.Ready
                    text: root.displayName.length > 0 ? root.displayName.charAt(0).toUpperCase() : "?"
                    color: root.onAccent
                    font { family: root.fontFamily; pixelSize: 36 * root.s; weight: Font.Bold }
                }
                Image {
                    id: avatar
                    anchors.fill: parent
                    source: root.currentUser.icon ? root.currentUser.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2 * root.s
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.displayName
                    color: root.onSurface
                    font { family: root.fontFamily; pixelSize: 20 * root.s; weight: Font.DemiBold }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.currentUser.realName && root.currentUser.realName.length > 0
                    text: root.currentUser.name
                    color: root.muted
                    font { family: root.fontFamily; pixelSize: 14 * root.s }
                }
            }

            // sessão + trocar usuário
            Row {
                width: parent.width
                spacing: 8 * root.s

                ComboBox {
                    id: sessionBox
                    width: parent.width - userBox.width - parent.spacing
                    height: 44 * root.s
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex
                    focusPolicy: Qt.StrongFocus
                    Accessible.name: "Sessão"
                    KeyNavigation.tab: userBox
                    KeyNavigation.backtab: password
                    font { family: root.fontFamily; pixelSize: 14 * root.s }

                    contentItem: Row {
                        leftPadding: 14 * root.s
                        spacing: 8 * root.s
                        Image {
                            source: "Assets/icons/session.svg"
                            sourceSize.width: 18 * root.s
                            sourceSize.height: 18 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: sessionBox.displayText
                            color: root.onSurface
                            font: sessionBox.font
                            elide: Text.ElideRight
                            width: sessionBox.width - 80 * root.s
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    indicator: Image {
                        x: sessionBox.width - width - 14 * root.s
                        anchors.verticalCenter: parent.verticalCenter
                        source: "Assets/icons/chevron-down.svg"
                        sourceSize.width: 16 * root.s
                        sourceSize.height: 16 * root.s
                        rotation: sessionBox.popup.visible ? 180 : 0
                    }
                    background: Rectangle {
                        radius: 6 * root.s
                        color: sessionBox.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                        border.width: sessionBox.visualFocus || sessionBox.popup.visible ? 2 * root.s : 1 * root.s
                        border.color: sessionBox.visualFocus || sessionBox.popup.visible ? root.accent : root.outline
                    }
                    delegate: ItemDelegate {
                        id: sessionItem
                        required property int index
                        required property string name
                        width: sessionBox.width - 12 * root.s
                        height: 40 * root.s
                        highlighted: sessionBox.highlightedIndex === index
                        contentItem: Text {
                            text: sessionItem.name
                            color: sessionBox.currentIndex === sessionItem.index ? root.accent : root.onSurface
                            font { family: root.fontFamily; pixelSize: 14 * root.s
                                   weight: sessionBox.currentIndex === sessionItem.index ? Font.DemiBold : Font.Normal }
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 6 * root.s
                        }
                        background: Rectangle {
                            radius: 6 * root.s
                            color: sessionItem.highlighted ? Qt.rgba(207 / 255, 188 / 255, 255 / 255, 0.16) : "transparent"
                        }
                    }
                    popup: Popup {
                        y: sessionBox.height + 6 * root.s
                        width: sessionBox.width
                        padding: 6 * root.s
                        implicitHeight: Math.min(contentItem.implicitHeight + 12 * root.s, 320 * root.s)
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                            currentIndex: sessionBox.highlightedIndex
                            spacing: 2 * root.s
                            ScrollIndicator.vertical: ScrollIndicator {}
                        }
                        background: Rectangle {
                            radius: 8 * root.s
                            color: root.popupBg
                            border.width: 1
                            border.color: root.outline
                        }
                    }
                }

                // trocar usuário: lista aparece ao abrir (Espaço/Enter/clique)
                ComboBox {
                    id: userBox
                    width: 44 * root.s
                    height: 44 * root.s
                    model: userModel
                    textRole: "name"
                    currentIndex: userModel.lastIndex
                    focusPolicy: Qt.StrongFocus
                    enabled: userModel.count > 1
                    Accessible.name: "Trocar usuário"
                    KeyNavigation.tab: loginButton
                    KeyNavigation.backtab: sessionBox
                    onActivated: password.forceActiveFocus()

                    contentItem: Item {
                        Image {
                            anchors.centerIn: parent
                            source: "Assets/icons/users.svg"
                            sourceSize.width: 18 * root.s
                            sourceSize.height: 18 * root.s
                            opacity: userBox.enabled ? 1 : 0.4
                        }
                    }
                    indicator: Item {}
                    background: Rectangle {
                        radius: 6 * root.s
                        color: userBox.hovered ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                        border.width: userBox.visualFocus || userBox.popup.visible ? 2 * root.s : 1 * root.s
                        border.color: userBox.visualFocus || userBox.popup.visible ? root.accent : root.outline
                    }
                    delegate: ItemDelegate {
                        id: userItem
                        required property int index
                        required property string name
                        required property string realName
                        width: 240 * root.s
                        height: 40 * root.s
                        highlighted: userBox.highlightedIndex === index
                        contentItem: Text {
                            text: userItem.realName.length > 0 ? userItem.realName + "  (" + userItem.name + ")" : userItem.name
                            color: userBox.currentIndex === userItem.index ? root.accent : root.onSurface
                            font { family: root.fontFamily; pixelSize: 14 * root.s }
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 6 * root.s
                        }
                        background: Rectangle {
                            radius: 6 * root.s
                            color: userItem.highlighted ? Qt.rgba(207 / 255, 188 / 255, 255 / 255, 0.16) : "transparent"
                        }
                    }
                    popup: Popup {
                        x: userBox.width - width
                        y: userBox.height + 6 * root.s
                        width: 252 * root.s
                        padding: 6 * root.s
                        implicitHeight: Math.min(contentItem.implicitHeight + 12 * root.s, 320 * root.s)
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: userBox.popup.visible ? userBox.delegateModel : null
                            currentIndex: userBox.highlightedIndex
                            spacing: 2 * root.s
                        }
                        background: Rectangle {
                            radius: 8 * root.s
                            color: root.popupBg
                            border.width: 1
                            border.color: root.outline
                        }
                    }
                }
            }

            // senha + entrar
            Column {
                width: parent.width
                spacing: 10 * root.s

                Text {
                    text: "Senha"
                    color: root.muted
                    font { family: root.fontFamily; pixelSize: 13 * root.s }
                }

                Row {
                    width: parent.width
                    spacing: 8 * root.s

                    TextField {
                        id: password
                        width: parent.width - loginButton.width - parent.spacing
                        height: 48 * root.s
                        focus: true
                        activeFocusOnTab: true
                        echoMode: TextInput.Password
                        passwordCharacter: "•"
                        color: root.onSurface
                        selectionColor: root.accent
                        selectedTextColor: root.onAccent
                        leftPadding: 14 * root.s
                        rightPadding: 14 * root.s
                        font { family: root.fontFamily; pixelSize: 18 * root.s; letterSpacing: password.text.length > 0 ? 3 * root.s : 0 }
                        placeholderText: "Digite sua senha"
                        placeholderTextColor: root.muted
                        Accessible.name: "Senha"
                        onAccepted: root.doLogin()
                        KeyNavigation.tab: sessionBox
                        KeyNavigation.backtab: btnShutdown
                        background: Rectangle {
                            radius: 6 * root.s
                            color: root.field
                            border.width: password.activeFocus ? 2 * root.s : 1 * root.s
                            border.color: password.activeFocus ? root.accent : root.outline
                        }
                    }

                    Button {
                        id: loginButton
                        width: 48 * root.s
                        height: 48 * root.s
                        padding: 0
                        text: "Entrar"
                        focusPolicy: Qt.StrongFocus
                        Accessible.name: "Entrar"
                        Keys.onReturnPressed: clicked()
                        Keys.onEnterPressed: clicked()
                        onClicked: root.doLogin()
                        KeyNavigation.tab: btnSuspend
                        KeyNavigation.backtab: userBox
                        contentItem: Item {
                            Image {
                                anchors.centerIn: parent
                                source: "Assets/icons/arrow-right.svg"
                                sourceSize.width: 22 * root.s
                                sourceSize.height: 22 * root.s
                            }
                        }
                        background: Rectangle {
                            radius: 6 * root.s
                            color: loginButton.down ? Qt.darker(root.accent, 1.2)
                                 : loginButton.hovered ? Qt.lighter(root.accent, 1.08)
                                 : root.accent
                            border.width: loginButton.visualFocus ? 2 * root.s : 0
                            border.color: root.onSurface
                        }
                    }
                }
            }

            // Caps Lock / erro
            Rectangle {
                width: parent.width
                height: 34 * root.s
                visible: keyboard.capsLock || errorText.text.length > 0
                radius: 6 * root.s
                color: Qt.rgba(255 / 255, 180 / 255, 171 / 255, 0.14)
                Row {
                    anchors { left: parent.left; leftMargin: 12 * root.s; verticalCenter: parent.verticalCenter }
                    spacing: 8 * root.s
                    Image {
                        source: "Assets/icons/capslock.svg"
                        sourceSize.width: 16 * root.s
                        sourceSize.height: 16 * root.s
                        visible: keyboard.capsLock && errorText.text.length === 0
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        id: errorText
                        visible: text.length > 0
                        color: root.error
                        font { family: root.fontFamily; pixelSize: 13 * root.s }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        visible: keyboard.capsLock && errorText.text.length === 0
                        text: "Caps Lock ativado"
                        color: root.error
                        font { family: root.fontFamily; pixelSize: 13 * root.s }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Tab alterna os campos · Enter entra"
                color: root.muted
                font { family: root.fontFamily; pixelSize: 12 * root.s }
            }
        }
    }

    // ---- energia ----
    Row {
        anchors { right: parent.right; bottom: parent.bottom; rightMargin: 32 * root.s; bottomMargin: 84 * root.s }
        spacing: 10 * root.s

        IconButton {
            id: btnSuspend
            s: root.s
            KeyNavigation.tab: btnReboot
            KeyNavigation.backtab: loginButton
            text: "Suspender"
            iconSource: Qt.resolvedUrl("Assets/icons/suspend.svg")
            focusColor: root.accent
            visible: sddm.canSuspend
            onClicked: sddm.suspend()
        }
        IconButton {
            id: btnReboot
            s: root.s
            KeyNavigation.tab: btnShutdown
            KeyNavigation.backtab: btnSuspend
            text: "Reiniciar"
            iconSource: Qt.resolvedUrl("Assets/icons/reboot.svg")
            focusColor: root.accent
            visible: sddm.canReboot
            onClicked: sddm.reboot()
        }
        IconButton {
            id: btnShutdown
            s: root.s
            KeyNavigation.tab: password
            KeyNavigation.backtab: btnReboot
            text: "Desligar"
            iconSource: Qt.resolvedUrl("Assets/icons/shutdown.svg")
            focusColor: root.accent
            borderColor: root.error
            visible: sddm.canPowerOff
            onClicked: sddm.powerOff()
        }
    }

    Component.onCompleted: password.forceActiveFocus()
}
