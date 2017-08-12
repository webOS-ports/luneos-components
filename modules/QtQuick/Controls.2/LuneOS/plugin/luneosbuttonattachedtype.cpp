#include "luneosbuttonattachedtype.h"

#include <QColor>
#include <QUrl>

LuneOSButtonAttachedType::LuneOSButtonAttachedType(QObject *parent) : QObject(parent)
{
    mMainColor = primaryColor();
    mTextColor = QColor();  // invalid color by default, choose automatically between white and #292929
}

QColor LuneOSButtonAttachedType::mainColor() const
{
    return mMainColor;
}

void LuneOSButtonAttachedType::setMainColor(QColor newColor)
{
    if(mMainColor != newColor) {
        mMainColor = newColor;
        mainColorChanged();

        if(!mTextColor.isValid()) textColorChanged();
    }
}

QColor LuneOSButtonAttachedType::textColor() const
{
    if(mTextColor.isValid()) return mTextColor; // if a specific text color has been set, return it

    // otherwise determine which default color would contrast best given the main color of the button
    bool isMainColorDark = (mMainColor.redF()*0.299 + mMainColor.greenF()*0.587 + mMainColor.blueF()*0.114) < 0.726;
    return isMainColorDark ? QColor("white") : QColor("#292929");
}

void LuneOSButtonAttachedType::setTextColor(QColor newColor)
{
    if(mTextColor != newColor) {
        mTextColor = newColor;
        textColorChanged();
    }
}

QUrl LuneOSButtonAttachedType::image() const
{
    return mImage;
}

void LuneOSButtonAttachedType::setImage(QUrl image)
{
    if(mImage != image) {
        mImage = image;
        imageChanged();
    }
}




