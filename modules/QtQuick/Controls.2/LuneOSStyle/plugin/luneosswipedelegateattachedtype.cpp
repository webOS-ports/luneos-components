#include "luneosswipedelegateattachedtype.h"

LuneOSSwipeDelegateAttachedType::LuneOSSwipeDelegateAttachedType(QObject *parent) : QObject(parent)
{

}

QString LuneOSSwipeDelegateAttachedType::confirmText() const
{
    return mConfirmText;
}

void LuneOSSwipeDelegateAttachedType::setConfirmText(QString text)
{
    if(mConfirmText != text) {
        mConfirmText = text;
        confirmTextChanged();
    }
}

