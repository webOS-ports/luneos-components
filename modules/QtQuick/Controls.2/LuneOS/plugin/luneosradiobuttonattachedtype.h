#ifndef LUNEOSRADIOBUTTONATTACHEDTYPE_H
#define LUNEOSRADIOBUTTONATTACHEDTYPE_H

#include <QObject>

class LuneOSRadioButtonAttachedType : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool useCollapsedLayout READ useCollapsedLayout WRITE setUseCollapsedLayout NOTIFY useCollapsedLayoutChanged)
public:
    LuneOSRadioButtonAttachedType(QObject *parent);
    bool useCollapsedLayout() const;
    void setUseCollapsedLayout(bool collapsedLayout);
signals:
    void useCollapsedLayoutChanged();

private:
    bool mUseCollapsedLayout;
};

#endif // LUNEOSRADIOBUTTONATTACHEDTYPE_H
