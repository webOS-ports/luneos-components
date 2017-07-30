#ifndef LUNEOSRADIOBUTTON_H
#define LUNEOSRADIOBUTTON_H

#include <QObject>
#include <QQmlEngine>

#include "luneosradiobuttonattachedtype.h"

class LuneOSRadioButton : public QObject
{
    Q_OBJECT
public:
    explicit LuneOSRadioButton(QObject *parent = 0);

    static LuneOSRadioButtonAttachedType *qmlAttachedProperties(QObject *object)
    {
        return new LuneOSRadioButtonAttachedType(object);
    }
};
QML_DECLARE_TYPEINFO(LuneOSRadioButton, QML_HAS_ATTACHED_PROPERTIES)

#endif // LUNEOSRADIOBUTTON_H
