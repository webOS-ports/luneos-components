#include "luneosswitchattachedtype.h"

LuneOSSwitchAttachedType::LuneOSSwitchAttachedType(QObject *parent) : QObject(parent)
{

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
