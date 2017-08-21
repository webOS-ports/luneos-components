#ifndef LUNEOSMENUATTACHEDTYPE_H
#define LUNEOSMENUATTACHEDTYPE_H

#include <QObject>

class LuneOSMenuAttachedType : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool appMenuStyle MEMBER mAppMenuStyle NOTIFY appMenuStyleChanged)
public:
    LuneOSMenuAttachedType(QObject *parent);

signals:
    void appMenuStyleChanged();

private:
    bool mAppMenuStyle;
};

#endif // LUNEOSMENUATTACHEDTYPE_H
