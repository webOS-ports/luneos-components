pragma Singleton

import QtQuick 2.9

Item {
    id: networkManagerFactory

    /*readonly*/ property NetworkManager instance: NetworkManager {}
}
