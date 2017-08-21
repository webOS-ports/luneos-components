#ifndef LUNEOSMENU_H
#define LUNEOSMENU_H

#include <QObject>
#include <QQmlEngine>

#include "luneosmenuattachedtype.h"

class LuneOSMenu : public QObject
{
    Q_OBJECT
public:
    explicit LuneOSMenu(QObject *parent = 0);

    static LuneOSMenuAttachedType *qmlAttachedProperties(QObject *object)
    {
        return new LuneOSMenuAttachedType(object);
    }
};
QML_DECLARE_TYPEINFO(LuneOSMenu, QML_HAS_ATTACHED_PROPERTIES)

#endif // LUNEOSMENU_H
