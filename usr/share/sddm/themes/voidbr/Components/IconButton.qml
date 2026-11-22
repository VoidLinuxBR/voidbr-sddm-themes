import ".."
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Button {
    // Defaults that can still be overridden

    id: root

    property color bgColor: Global.mSurfaceVariant
    property color textColor: Global.mOnSurfaceVariant
    property int fontSize: Global.fontM
    property real borderRadius: Global.buttonRadius
    property string utf8Code: "\uf071"
    // destaque também quando o botão recebe foco pelo teclado (Tab)
    readonly property bool lit: root.down || root.hovered || root.visualFocus

    // Enter/Return ativam o botão (o Button do QtQuick.Controls só aceita Espaço)
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    background: Rectangle {
        radius: root.borderRadius
        color: root.lit ? bgColor : "transparent"
        border.color: bgColor
        border.width: 1
    }

    contentItem: Icon {
        utf8Code: root.utf8Code
        fontSize: root.fontSize
        color: root.lit ? textColor : bgColor
        Layout.fillWidth: true
    }

}
