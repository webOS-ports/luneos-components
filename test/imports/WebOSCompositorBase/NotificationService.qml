import QtQuick 2.0

import LuneOS.Service 1.0

QtObject {
    id: root
    property ListModel toastModel: ModelSingletons.toastModel
    property ListModel alertModel: ModelSingletons.alertModel
    property ListModel pincodePromptModel: ModelSingletons.pincodePromptModel
}
