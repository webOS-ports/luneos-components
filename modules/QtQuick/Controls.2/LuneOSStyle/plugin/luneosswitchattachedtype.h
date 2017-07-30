#ifndef LUNEOSSWITCHATTACHEDTYPE_H
#define LUNEOSSWITCHATTACHEDTYPE_H

#include <QObject>
#include <QColor>

class LuneOSSwitchAttachedType : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString labelOn READ labelOn WRITE setLabelOn NOTIFY labelOnChanged)
    Q_PROPERTY(QString labelOff READ labelOff WRITE setLabelOff NOTIFY labelOffChanged)
    Q_PROPERTY(QColor textColor READ textColor WRITE setTextColor NOTIFY textColorChanged)
public:
    LuneOSSwitchAttachedType(QObject *parent);
    QString labelOn() const;
    void setLabelOn(QString label);
    QString labelOff() const;
    void setLabelOff(QString label);
    QColor textColor() const;
    void setTextColor(QColor color);
signals:
    void labelOnChanged();
    void labelOffChanged();
    void textColorChanged();

private:
    QString mLabelOn;
    QString mLabelOff;
    QColor mTextColor;
};

#endif // LUNEOSSWITCHATTACHEDTYPE_H
