#ifndef LUNEOSSWITCH_H
#define LUNEOSSWITCH_H

#include <QObject>
#include <QQmlEngine>

#include "luneosswitchattachedtype.h"

class LuneOSSwitch : public QObject
{
    Q_OBJECT
public:
    explicit LuneOSSwitch(QObject *parent = 0);

    static LuneOSSwitchAttachedType *qmlAttachedProperties(QObject *object)
    {
        return new LuneOSSwitchAttachedType(object);
    }
};
QML_DECLARE_TYPEINFO(LuneOSSwitch, QML_HAS_ATTACHED_PROPERTIES)

#endif // LUNEOSSWITCH_H
