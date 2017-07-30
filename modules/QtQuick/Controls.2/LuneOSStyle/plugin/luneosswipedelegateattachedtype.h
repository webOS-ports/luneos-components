#ifndef LUNEOSSWIPEDELEGATEATTACHEDTYPE_H
#define LUNEOSSWIPEDELEGATEATTACHEDTYPE_H

#include <QObject>

class LuneOSSwipeDelegateAttachedType : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString confirmText READ confirmText WRITE setConfirmText NOTIFY confirmTextChanged)
public:
    LuneOSSwipeDelegateAttachedType(QObject *parent);
    QString confirmText() const;
    void setConfirmText(QString label);
Q_SIGNALS:
    void confirmTextChanged();
    void confirmed();

private:
    QString mConfirmText;
};

#endif // LUNEOSSWIPEDELEGATEATTACHEDTYPE_H
