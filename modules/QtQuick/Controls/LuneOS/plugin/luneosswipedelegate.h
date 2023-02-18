#ifndef LUNEOSSWIPEDELEGATE_H
#define LUNEOSSWIPEDELEGATE_H

#include <QObject>
#include <QQmlEngine>

#include "luneosswipedelegateattachedtype.h"

class LuneOSSwipeDelegate : public QObject
{
    Q_OBJECT
public:
    explicit LuneOSSwipeDelegate(QObject *parent = 0);

    static LuneOSSwipeDelegateAttachedType *qmlAttachedProperties(QObject *object)
    {
        return new LuneOSSwipeDelegateAttachedType(object);
    }
};
QML_DECLARE_TYPEINFO(LuneOSSwipeDelegate, QML_HAS_ATTACHED_PROPERTIES)

#endif // LUNEOSSWIPEDELEGATE_H
