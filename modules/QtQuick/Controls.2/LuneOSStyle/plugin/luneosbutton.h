#ifndef LUNEOSBUTTON_H
#define LUNEOSBUTTON_H

#include <QObject>
#include <QQmlEngine>

#include "luneosbuttonattachedtype.h"

class LuneOSButton : public QObject
{
    Q_OBJECT
public:
    explicit LuneOSButton(QObject *parent = 0);

    static LuneOSButtonAttachedType *qmlAttachedProperties(QObject *object)
    {
        return new LuneOSButtonAttachedType(object);
    }
};
QML_DECLARE_TYPEINFO(LuneOSButton, QML_HAS_ATTACHED_PROPERTIES)

#endif // LUNEOSBUTTON_H
