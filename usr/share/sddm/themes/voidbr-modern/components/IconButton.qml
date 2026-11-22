// Botão só com ícone: foco de teclado visível (Tab) e ativação por
// Enter/Return/Espaço. Usado nos botões de energia e no trocar usuário.
import QtQuick
import QtQuick.Controls.Basic

Button {
    id: control

    property string iconSource: ""
    property real s: 1
    property real size: 48 * s
    property bool round: true
    property color borderColor: "#49454f"
    property color focusColor: "#cfbcff"
    property color fill: Qt.rgba(29 / 255, 27 / 255, 32 / 255, 0.7)

    implicitWidth: size
    implicitHeight: size
    padding: 0
    focusPolicy: Qt.StrongFocus
    hoverEnabled: true

    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()

    Accessible.name: text

    contentItem: Item {
        Image {
            anchors.centerIn: parent
            source: control.iconSource
            sourceSize.width: 20 * control.s
            sourceSize.height: 20 * control.s
            width: 20 * control.s
            height: 20 * control.s
            fillMode: Image.PreserveAspectFit
            opacity: control.enabled ? 1 : 0.4
        }
    }

    background: Rectangle {
        radius: control.round ? width / 2 : 6 * control.s
        color: control.down ? Qt.lighter(control.fill, 1.8)
             : control.hovered ? Qt.lighter(control.fill, 1.4)
             : control.fill
        border.width: control.visualFocus ? 2 * control.s : 1 * control.s
        border.color: control.visualFocus ? control.focusColor : control.borderColor
    }

    ToolTip.visible: hovered && text.length > 0
    ToolTip.text: text
    ToolTip.delay: 500
}
