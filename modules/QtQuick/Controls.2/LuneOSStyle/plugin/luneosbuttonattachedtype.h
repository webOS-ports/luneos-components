#ifndef LUNEOSBUTTONATTACHEDTYPE_H
#define LUNEOSBUTTONATTACHEDTYPE_H

#include <QObject>
#include <QColor>

class LuneOSButtonAttachedType : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QColor textColor READ textColor WRITE setTextColor NOTIFY textColorChanged)
    Q_PROPERTY(QColor mainColor READ mainColor WRITE setMainColor NOTIFY mainColorChanged)
    Q_PROPERTY(QColor primaryColor     READ primaryColor CONSTANT)
    Q_PROPERTY(QColor secondaryColor   READ secondaryColor CONSTANT)
    Q_PROPERTY(QColor affirmativeColor READ affirmativeColor CONSTANT)
    Q_PROPERTY(QColor negativeColor    READ negativeColor CONSTANT)
    Q_PROPERTY(QColor blueColor        READ blueColor CONSTANT)
    Q_PROPERTY(QColor grayColor        READ grayColor CONSTANT)
public:
    LuneOSButtonAttachedType(QObject *parent);

    QColor mainColor() const;
    void setMainColor(QColor label);

    QColor textColor() const;
    void setTextColor(QColor label);

    QColor primaryColor() { return QColor("#80171717"); }
    QColor secondaryColor() { return QColor("#CCFFFFFF"); }
    QColor affirmativeColor() { return QColor("#2aa100"); }
    QColor negativeColor() { return QColor("#be0003"); }
    QColor blueColor() { return QColor("#2071bb"); }
    QColor grayColor() { return QColor("#4b4b4b"); }
signals:
    void mainColorChanged();
    void textColorChanged();

private:
    QColor mMainColor;
    QColor mTextColor;
};

#endif // LUNEOSBUTTONATTACHEDTYPE_H
