#ifndef LUNEOSSWITCHATTACHEDTYPE_H
#define LUNEOSSWITCHATTACHEDTYPE_H

#include <QObject>

class LuneOSSwitchAttachedType : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString labelOn READ labelOn WRITE setLabelOn NOTIFY labelOnChanged)
    Q_PROPERTY(QString labelOff READ labelOff WRITE setLabelOff NOTIFY labelOffChanged)
public:
    LuneOSSwitchAttachedType(QObject *parent);
    QString labelOn() const;
    void setLabelOn(QString label);
    QString labelOff() const;
    void setLabelOff(QString label);
signals:
    void labelOnChanged();
    void labelOffChanged();

private:
    QString mLabelOn;
    QString mLabelOff;
};

#endif // LUNEOSSWITCHATTACHEDTYPE_H
