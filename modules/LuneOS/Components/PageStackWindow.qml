import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.4
import LunaNext.Common 0.1
import LuneOS.Service 1.0
import LuneOS.Application 1.0

Item {
    id: pageStackWindow
    width: Settings.displayWidth
    height: Settings.displayHeight
    visible: true

    property alias initialPage: __stackView.initialItem

    StackView {
        id: __stackView
        anchors.fill: parent
        focus: visible
    }


}

