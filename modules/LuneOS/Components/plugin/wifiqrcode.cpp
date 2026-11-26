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

#include "wifiqrcode.h"

#include <algorithm>

namespace WifiQr {

namespace {

/* The most a QR code holds: 2953 bytes, version 40 at the lowest correction. */
constexpr qsizetype maxTextLength = 2953;
constexpr qsizetype maxSsidBytes = 32;

bool isHex(const QString &value)
{
    return std::all_of(value.cbegin(), value.cend(), [](QChar c) {
        return (c >= QLatin1Char('0') && c <= QLatin1Char('9'))
               || (c >= QLatin1Char('a') && c <= QLatin1Char('f'))
               || (c >= QLatin1Char('A') && c <= QLatin1Char('F'));
    });
}

/* Whether the character at index is preceded by an odd number of backslashes. */
bool isEscaped(const QString &raw, qsizetype index)
{
    qsizetype backslashes = 0;
    for (qsizetype i = index - 1; i >= 0 && raw.at(i) == QLatin1Char('\\'); --i)
        ++backslashes;
    return backslashes % 2 == 1;
}

/*
 * A field's value as written (escapes still in it) to what it means: the
 * double quotes around it taken off, then every "\x" read as "x". A backslash
 * at the very end has nothing to escape and stays.
 */
QString decodeValue(const QString &raw)
{
    QString value = raw;
    if (value.size() >= 2 && value.startsWith(QLatin1Char('"')) && value.endsWith(QLatin1Char('"'))
            && !isEscaped(value, value.size() - 1))
        value = value.mid(1, value.size() - 2);

    QString out;
    out.reserve(value.size());
    for (qsizetype i = 0; i < value.size(); ++i) {
        if (value.at(i) == QLatin1Char('\\') && i + 1 < value.size())
            ++i;
        out.append(value.at(i));
    }
    return out;
}

/* T: as written to one of ours; "" when it is none we know. */
QString securityFromType(const QString &type)
{
    const QString t = type.trimmed().toUpper();
    if (t == QLatin1String("WPA") || t == QLatin1String("WPA2"))
        return QStringLiteral("psk");
    if (t == QLatin1String("SAE") || t == QLatin1String("WPA3"))
        return QStringLiteral("sae");
    if (t == QLatin1String("WEP"))
        return QStringLiteral("wep");
    if (t == QLatin1String("NOPASS") || t == QLatin1String("NONE"))
        return QStringLiteral("none");
    return QString();
}

QString typeFromSecurity(const QString &security)
{
    if (security == QLatin1String("psk"))
        return QStringLiteral("WPA");
    if (security == QLatin1String("sae"))
        return QStringLiteral("SAE");
    if (security == QLatin1String("wep"))
        return QStringLiteral("WEP");
    if (security == QLatin1String("none"))
        return QStringLiteral("nopass");
    return QString();
}

} // namespace

QString escape(const QString &value)
{
    QString out;
    out.reserve(value.size());
    for (const QChar c : value) {
        if (c == QLatin1Char('\\') || c == QLatin1Char(';') || c == QLatin1Char(',')
                || c == QLatin1Char(':') || c == QLatin1Char('"'))
            out.append(QLatin1Char('\\'));
        out.append(c);
    }
    return out;
}

bool isValidPassphrase(const QString &security, const QString &passphrase)
{
    /* Lengths in bytes, as connman and wpa_supplicant count them. */
    const qsizetype bytes = passphrase.toUtf8().size();

    if (security == QLatin1String("none"))
        return true;
    if (security == QLatin1String("psk"))
        return (bytes >= 8 && bytes <= 63) || (passphrase.size() == 64 && isHex(passphrase));
    if (security == QLatin1String("sae"))
        /* SAE takes a password of any length; 255 keeps nonsense out. */
        return bytes >= 1 && bytes <= 255;
    if (security == QLatin1String("wep"))
        return bytes == 5 || bytes == 13
               || ((passphrase.size() == 10 || passphrase.size() == 26) && isHex(passphrase));
    return false;
}

ParseResult parse(const QString &text)
{
    ParseResult result;
    static const QLatin1String prefix("WIFI:");

    if (!text.startsWith(prefix, Qt::CaseInsensitive)) {
        result.error = Error::NotWifi;
        return result;
    }
    if (text.size() > maxTextLength) {
        result.error = Error::TooLong;
        return result;
    }

    QString ssid, type, passphrase, hidden;
    bool haveSsid = false, haveType = false, havePassphrase = false, haveHidden = false;
    bool enterprise = false;

    /* Split at every ';' that is not escaped; the first of a key wins. */
    qsizetype start = prefix.size();
    for (qsizetype i = start; i <= text.size(); ++i) {
        if (i < text.size() && (text.at(i) != QLatin1Char(';') || isEscaped(text, i)))
            continue;

        const QString field = text.mid(start, i - start);
        start = i + 1;

        const qsizetype colon = field.indexOf(QLatin1Char(':'));
        if (colon <= 0)
            continue; // empty, as in the closing ";;", or no key

        const QString key = field.left(colon).trimmed().toUpper();
        const QString raw = field.mid(colon + 1);

        if (key == QLatin1String("S") && !haveSsid) {
            ssid = decodeValue(raw);
            haveSsid = true;
        } else if (key == QLatin1String("T") && !haveType) {
            type = decodeValue(raw);
            haveType = true;
        } else if (key == QLatin1String("P") && !havePassphrase) {
            passphrase = decodeValue(raw);
            havePassphrase = true;
        } else if (key == QLatin1String("H") && !haveHidden) {
            hidden = decodeValue(raw);
            haveHidden = true;
        } else if (key == QLatin1String("E") || key == QLatin1String("A")
                   || key == QLatin1String("I") || key == QLatin1String("PH2")) {
            /* EAP method, anonymous identity, identity, phase 2 */
            enterprise = true;
        }
    }

    if (ssid.isEmpty()) {
        result.error = Error::NoSsid;
        return result;
    }
    if (ssid.toUtf8().size() > maxSsidBytes) {
        result.error = Error::SsidTooLong;
        return result;
    }
    if (enterprise || type.contains(QLatin1String("EAP"), Qt::CaseInsensitive)) {
        result.error = Error::Enterprise;
        return result;
    }

    QString security;
    if (type.trimmed().isEmpty())
        /* No T: a code with a passphrase is a WPA one in practice. */
        security = passphrase.isEmpty() ? QStringLiteral("none") : QStringLiteral("psk");
    else
        security = securityFromType(type);

    if (security.isEmpty()) {
        result.error = Error::UnknownSecurity;
        return result;
    }
    if (security == QLatin1String("none"))
        passphrase.clear(); // "nopass" means it, whatever P: says
    else if (!isValidPassphrase(security, passphrase)) {
        result.error = Error::BadPassphrase;
        return result;
    }

    result.network.ssid = ssid;
    result.network.security = security;
    result.network.passphrase = passphrase;
    result.network.hidden = hidden.trimmed().compare(QLatin1String("true"), Qt::CaseInsensitive) == 0;
    return result;
}

QString compose(const Network &network)
{
    const QString type = typeFromSecurity(network.security);
    if (network.ssid.isEmpty() || network.ssid.toUtf8().size() > maxSsidBytes || type.isEmpty()
            || !isValidPassphrase(network.security, network.passphrase))
        return QString();

    /* In the order Android writes them. */
    QString text = QStringLiteral("WIFI:S:") + escape(network.ssid) + QLatin1Char(';')
                   + QStringLiteral("T:") + type + QLatin1Char(';');
    if (network.security != QLatin1String("none"))
        text += QStringLiteral("P:") + escape(network.passphrase) + QLatin1Char(';');
    if (network.hidden)
        text += QStringLiteral("H:true;");
    text += QLatin1Char(';');
    return text;
}

QString errorName(Error error)
{
    switch (error) {
    case Error::None: return QString();
    case Error::NotWifi: return QStringLiteral("notWifi");
    case Error::TooLong: return QStringLiteral("tooLong");
    case Error::NoSsid: return QStringLiteral("noSsid");
    case Error::SsidTooLong: return QStringLiteral("ssidTooLong");
    case Error::Enterprise: return QStringLiteral("enterprise");
    case Error::UnknownSecurity: return QStringLiteral("unknownSecurity");
    case Error::BadPassphrase: return QStringLiteral("badPassphrase");
    }
    return QStringLiteral("unknown");
}

} // namespace WifiQr

WifiQrCode::WifiQrCode(QObject *parent)
    : QObject(parent)
{
}

QVariantMap WifiQrCode::parse(const QString &text) const
{
    const WifiQr::ParseResult result = WifiQr::parse(text);
    QVariantMap map;
    map.insert(QStringLiteral("valid"), result.error == WifiQr::Error::None);
    map.insert(QStringLiteral("error"), WifiQr::errorName(result.error));
    map.insert(QStringLiteral("ssid"), result.network.ssid);
    map.insert(QStringLiteral("security"), result.network.security);
    map.insert(QStringLiteral("passphrase"), result.network.passphrase);
    map.insert(QStringLiteral("hidden"), result.network.hidden);
    return map;
}

QString WifiQrCode::compose(const QString &ssid, const QString &security,
                            const QString &passphrase, bool hidden) const
{
    WifiQr::Network network;
    network.ssid = ssid;
    network.security = security;
    network.passphrase = passphrase;
    network.hidden = hidden;
    return WifiQr::compose(network);
}

bool WifiQrCode::isValidPassphrase(const QString &security, const QString &passphrase) const
{
    return WifiQr::isValidPassphrase(security, passphrase);
}
