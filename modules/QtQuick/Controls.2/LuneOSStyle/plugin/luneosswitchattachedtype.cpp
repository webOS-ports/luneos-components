#include "luneosswitchattachedtype.h"

#include <QColor>

LuneOSSwitchAttachedType::LuneOSSwitchAttachedType(QObject *parent) : QObject(parent)
{
    mTextColor = QColor("#26282a");
}

QString LuneOSSwitchAttachedType::labelOn() const
{
    return mLabelOn;
}

void LuneOSSwitchAttachedType::setLabelOn(QString label)
{
    if(mLabelOn != label) {
        mLabelOn = label;
        labelOnChanged();
    }
}

QString LuneOSSwitchAttachedType::labelOff() const
{
    return mLabelOff;
}

void LuneOSSwitchAttachedType::setLabelOff(QString label)
{
    if(mLabelOff != label) {
        mLabelOff = label;
        labelOffChanged();
    }
}

QColor LuneOSSwitchAttachedType::textColor() const
{
    return mTextColor;
}

void LuneOSSwitchAttachedType::setTextColor(QColor color)
{
    if(mTextColor != color) {
        mTextColor = color;
        textColorChanged();
    }
}
