/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

#ifndef WIFIQRCODE_H
#define WIFIQRCODE_H

#include <QObject>
#include <QString>
#include <QVariantMap>

/*
 * The text a Wi-Fi QR code holds, the one Android, iOS, GNOME Settings and
 * every router sticker use:
 *
 *     WIFI:S:<ssid>;T:<WPA|WEP|SAE|nopass>;P:<passphrase>;H:true;;
 *
 * Fields come in any order and end with ';'; in a value a backslash takes the
 * next character as it is, so "\;", "\,", "\:", "\"" and "\\" stand for
 * themselves. A value in double quotes has them taken off: the format's way of
 * saying "this is text, though it looks like hex". The quoted-hex SSID of the
 * original ZXing note is not decoded; no phone writes one and none reads one.
 *
 * Free of anything but QtCore so it can be tested on its own.
 */
namespace WifiQr {

struct Network {
    QString ssid;
    // "none", "wep", "psk" (WPA/WPA2 personal) or "sae" (WPA3 personal)
    QString security;
    QString passphrase;
    bool hidden = false;
};

/* Why a text is not a network that can be joined. */
enum class Error {
    None,
    NotWifi,           // not a WIFI: code at all
    TooLong,           // longer than any QR code can hold
    NoSsid,            // S: missing or empty
    SsidTooLong,       // more than the 32 bytes an SSID can have
    Enterprise,        // WPA2-EAP and friends: a passphrase cannot join those
    UnknownSecurity,   // a T: none of the above
    BadPassphrase,     // missing, or the wrong length for its security
};

struct ParseResult {
    Error error = Error::None;
    Network network;
};

/* What a QR code holds, read as a Wi-Fi network. */
ParseResult parse(const QString &text);

/*
 * The text for a network, or an empty string when it is not one a QR code can
 * describe (no SSID, an unknown security, a passphrase that does not fit it).
 * parse(compose(n)) gives n back.
 */
QString compose(const Network &network);

/* Backslashes in front of the characters the format gives a meaning. */
QString escape(const QString &value);

/* A passphrase connman and wpa_supplicant would take for this security. */
bool isValidPassphrase(const QString &security, const QString &passphrase);

/* The name an Error has for QML, e.g. "noSsid"; "" for Error::None. */
QString errorName(Error error);

} // namespace WifiQr

/*
 * WifiQr for QML, as the singleton LuneOS.Components.WifiQrCode:
 *
 *     var net = WifiQrCode.parse(text)
 *     // {valid, error, ssid, security, passphrase, hidden}
 *     qrCode.text = WifiQrCode.compose(ssid, "psk", passphrase, false)
 */
class WifiQrCode : public QObject
{
    Q_OBJECT

public:
    explicit WifiQrCode(QObject *parent = nullptr);

    Q_INVOKABLE QVariantMap parse(const QString &text) const;
    Q_INVOKABLE QString compose(const QString &ssid, const QString &security,
                                const QString &passphrase, bool hidden = false) const;
    Q_INVOKABLE bool isValidPassphrase(const QString &security, const QString &passphrase) const;
};

#endif // WIFIQRCODE_H
