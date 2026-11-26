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

#include <gtest/gtest.h>

#include "wifiqrcode.h"

using WifiQr::Error;

namespace {

WifiQr::Network net(const QString &ssid, const QString &security, const QString &passphrase,
                    bool hidden = false)
{
    WifiQr::Network n;
    n.ssid = ssid;
    n.security = security;
    n.passphrase = passphrase;
    n.hidden = hidden;
    return n;
}

void expectNetwork(const QString &text, const QString &ssid, const QString &security,
                   const QString &passphrase, bool hidden = false)
{
    const WifiQr::ParseResult r = WifiQr::parse(text);
    EXPECT_EQ(r.error, Error::None) << qPrintable(text) << " " << qPrintable(WifiQr::errorName(r.error));
    EXPECT_EQ(r.network.ssid, ssid) << qPrintable(text);
    EXPECT_EQ(r.network.security, security) << qPrintable(text);
    EXPECT_EQ(r.network.passphrase, passphrase) << qPrintable(text);
    EXPECT_EQ(r.network.hidden, hidden) << qPrintable(text);
}

Error errorOf(const QString &text)
{
    return WifiQr::parse(text).error;
}

} // namespace

/* What Android's Wi-Fi sharing writes, and what GNOME Settings writes. */
TEST(WifiQrParse, CodesOtherSystemsWrite)
{
    expectNetwork(QStringLiteral("WIFI:S:Home;T:WPA;P:secret123;H:false;;"),
                  QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("secret123"));
    expectNetwork(QStringLiteral("WIFI:T:WPA;S:Home;P:secret123;;"),
                  QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("secret123"));
    expectNetwork(QStringLiteral("WIFI:S:Guest;T:nopass;;"),
                  QStringLiteral("Guest"), QStringLiteral("none"), QString());
    expectNetwork(QStringLiteral("WIFI:S:Lab;T:SAE;P:correct horse;;"),
                  QStringLiteral("Lab"), QStringLiteral("sae"), QStringLiteral("correct horse"));
}

TEST(WifiQrParse, PrefixAndKeysInAnyCase)
{
    expectNetwork(QStringLiteral("wifi:s:Home;t:wpa;p:secret123;h:TRUE;;"),
                  QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("secret123"), true);
}

TEST(WifiQrParse, NoClosingSemicolons)
{
    expectNetwork(QStringLiteral("WIFI:S:Guest;T:nopass"),
                  QStringLiteral("Guest"), QStringLiteral("none"), QString());
}

TEST(WifiQrParse, BackslashTakesTheNextCharacterAsItIs)
{
    expectNetwork(QStringLiteral("WIFI:S:a\\;b\\,c\\:d;T:WPA;P:p\\\"w\\\\d\\;1234;;"),
                  QStringLiteral("a;b,c:d"), QStringLiteral("psk"), QStringLiteral("p\"w\\d;1234"));
    /* A backslash before an ordinary character is dropped, as every reader does. */
    expectNetwork(QStringLiteral("WIFI:S:\\H\\ome;T:nopass;;"),
                  QStringLiteral("Home"), QStringLiteral("none"), QString());
    /* ...and at the very end it has nothing to escape and stays. */
    expectNetwork(QStringLiteral("WIFI:S:Home;T:WPA;P:abcdefgh\\"),
                  QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("abcdefgh\\"));
}

TEST(WifiQrParse, DoubleQuotesAroundAValueComeOff)
{
    expectNetwork(QStringLiteral("WIFI:S:\"ABCD\";T:WPA;P:\"12345678\";;"),
                  QStringLiteral("ABCD"), QStringLiteral("psk"), QStringLiteral("12345678"));
    /* An escaped closing quote is part of the value, so nothing is taken off. */
    expectNetwork(QStringLiteral("WIFI:S:\"AB\\\";T:nopass;;"),
                  QStringLiteral("\"AB\""), QStringLiteral("none"), QString());
    /* A lone quote is the value. */
    expectNetwork(QStringLiteral("WIFI:S:\";T:nopass;;"),
                  QStringLiteral("\""), QStringLiteral("none"), QString());
}

TEST(WifiQrParse, ColonInsideAValue)
{
    /* Only the first colon of a field ends its key. */
    expectNetwork(QStringLiteral("WIFI:S:Home;T:WPA;P:ab:cd:ef:gh;;"),
                  QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("ab:cd:ef:gh"));
}

TEST(WifiQrParse, FirstOfAKeyWins)
{
    expectNetwork(QStringLiteral("WIFI:S:first;S:second;T:nopass;;"),
                  QStringLiteral("first"), QStringLiteral("none"), QString());
}

TEST(WifiQrParse, UnknownFieldsAreIgnored)
{
    /* R: is WPA3's transition-disable flag; joining by name does not need it. */
    expectNetwork(QStringLiteral("WIFI:S:Home;T:WPA;R:1;X:y;P:secret123;;"),
                  QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("secret123"));
}

TEST(WifiQrParse, SecurityNames)
{
    expectNetwork(QStringLiteral("WIFI:S:n;T:WPA2;P:12345678;;"), QStringLiteral("n"),
                  QStringLiteral("psk"), QStringLiteral("12345678"));
    expectNetwork(QStringLiteral("WIFI:S:n;T:WPA3;P:x;;"), QStringLiteral("n"),
                  QStringLiteral("sae"), QStringLiteral("x"));
    expectNetwork(QStringLiteral("WIFI:S:n;T:WEP;P:abcde;;"), QStringLiteral("n"),
                  QStringLiteral("wep"), QStringLiteral("abcde"));
    expectNetwork(QStringLiteral("WIFI:S:n;T:none;;"), QStringLiteral("n"),
                  QStringLiteral("none"), QString());
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:n;T:FOO;P:12345678;;")), Error::UnknownSecurity);
}

TEST(WifiQrParse, NoTypeMeansWpaWithAPassphraseAndOpenWithout)
{
    expectNetwork(QStringLiteral("WIFI:S:n;P:12345678;;"), QStringLiteral("n"),
                  QStringLiteral("psk"), QStringLiteral("12345678"));
    expectNetwork(QStringLiteral("WIFI:S:n;;"), QStringLiteral("n"), QStringLiteral("none"), QString());
    expectNetwork(QStringLiteral("WIFI:S:n;T:;;"), QStringLiteral("n"), QStringLiteral("none"), QString());
}

TEST(WifiQrParse, NopassIgnoresAPassphrase)
{
    expectNetwork(QStringLiteral("WIFI:S:n;T:nopass;P:whatever1;;"), QStringLiteral("n"),
                  QStringLiteral("none"), QString());
}

TEST(WifiQrParse, Hidden)
{
    EXPECT_TRUE(WifiQr::parse(QStringLiteral("WIFI:S:n;T:nopass;H:true;;")).network.hidden);
    EXPECT_FALSE(WifiQr::parse(QStringLiteral("WIFI:S:n;T:nopass;H:false;;")).network.hidden);
    EXPECT_FALSE(WifiQr::parse(QStringLiteral("WIFI:S:n;T:nopass;H:yes;;")).network.hidden);
    EXPECT_FALSE(WifiQr::parse(QStringLiteral("WIFI:S:n;T:nopass;;")).network.hidden);
}

TEST(WifiQrParse, NotAWifiCode)
{
    EXPECT_EQ(errorOf(QString()), Error::NotWifi);
    EXPECT_EQ(errorOf(QStringLiteral("https://example.org/")), Error::NotWifi);
    EXPECT_EQ(errorOf(QStringLiteral("LPA:1$smdp.example$CODE")), Error::NotWifi);
    EXPECT_EQ(errorOf(QStringLiteral(" WIFI:S:n;;")), Error::NotWifi);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI")), Error::NotWifi);
}

TEST(WifiQrParse, TooLongForAnyCode)
{
    QString text = QStringLiteral("WIFI:S:n;T:nopass;;");
    text += QString(2953 - text.size(), QLatin1Char(';'));
    EXPECT_EQ(errorOf(text), Error::None);
    text += QLatin1Char(';');
    EXPECT_EQ(errorOf(text), Error::TooLong);
}

TEST(WifiQrParse, Ssid)
{
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:T:WPA;P:12345678;;")), Error::NoSsid);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:;T:nopass;;")), Error::NoSsid);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:\"\";T:nopass;;")), Error::NoSsid);

    /* 32 bytes, not 32 characters: ten three-byte characters fit, eleven do not. */
    const QString ten(10, QChar(0x20AC)); // the euro sign, 3 bytes in UTF-8
    expectNetwork(QStringLiteral("WIFI:S:") + ten + QStringLiteral(";T:nopass;;"), ten,
                  QStringLiteral("none"), QString());
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:") + ten + QChar(0x20AC) + QStringLiteral(";T:nopass;;")),
              Error::SsidTooLong);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:") + QString(32, QLatin1Char('a')) + QStringLiteral(";;")),
              Error::None);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:") + QString(33, QLatin1Char('a')) + QStringLiteral(";;")),
              Error::SsidTooLong);
}

TEST(WifiQrParse, Enterprise)
{
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:corp;T:WPA2-EAP;E:PEAP;I:me;P:pw;;")), Error::Enterprise);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:corp;T:WPA;E:TTLS;P:12345678;;")), Error::Enterprise);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:corp;T:WPA-EAP;;")), Error::Enterprise);
}

TEST(WifiQrParse, PassphraseMustFitItsSecurity)
{
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:n;T:WPA;;")), Error::BadPassphrase);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:n;T:WPA;P:1234567;;")), Error::BadPassphrase);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:n;T:SAE;P:;;")), Error::BadPassphrase);
    EXPECT_EQ(errorOf(QStringLiteral("WIFI:S:n;T:WEP;P:abcd;;")), Error::BadPassphrase);
}

TEST(WifiQrPassphrase, Psk)
{
    const QString psk = QStringLiteral("psk");
    EXPECT_FALSE(WifiQr::isValidPassphrase(psk, QString(7, QLatin1Char('a'))));
    EXPECT_TRUE(WifiQr::isValidPassphrase(psk, QString(8, QLatin1Char('a'))));
    EXPECT_TRUE(WifiQr::isValidPassphrase(psk, QString(63, QLatin1Char('a'))));
    /* 64 characters only as the raw key, in hex. */
    EXPECT_FALSE(WifiQr::isValidPassphrase(psk, QString(64, QLatin1Char('g'))));
    EXPECT_TRUE(WifiQr::isValidPassphrase(psk, QString(64, QLatin1Char('F'))));
    EXPECT_FALSE(WifiQr::isValidPassphrase(psk, QString(65, QLatin1Char('f'))));
    /* Bytes, as wpa_supplicant counts: 21 euro signs are 63, 22 are 66. */
    EXPECT_TRUE(WifiQr::isValidPassphrase(psk, QString(21, QChar(0x20AC))));
    EXPECT_FALSE(WifiQr::isValidPassphrase(psk, QString(22, QChar(0x20AC))));
    /* Three euro signs are 9 bytes but 3 characters. */
    EXPECT_TRUE(WifiQr::isValidPassphrase(psk, QString(3, QChar(0x20AC))));
}

TEST(WifiQrPassphrase, WepSaeNoneAndUnknown)
{
    const QString wep = QStringLiteral("wep");
    EXPECT_TRUE(WifiQr::isValidPassphrase(wep, QStringLiteral("abcde")));
    EXPECT_TRUE(WifiQr::isValidPassphrase(wep, QStringLiteral("abcdefghijklm")));
    EXPECT_TRUE(WifiQr::isValidPassphrase(wep, QStringLiteral("0123456789")));
    EXPECT_TRUE(WifiQr::isValidPassphrase(wep, QStringLiteral("0123456789abcdef0123456789")));
    EXPECT_FALSE(WifiQr::isValidPassphrase(wep, QStringLiteral("012345678g")));
    EXPECT_FALSE(WifiQr::isValidPassphrase(wep, QStringLiteral("abcdef")));

    EXPECT_TRUE(WifiQr::isValidPassphrase(QStringLiteral("sae"), QStringLiteral("x")));
    EXPECT_TRUE(WifiQr::isValidPassphrase(QStringLiteral("sae"), QString(255, QLatin1Char('x'))));
    EXPECT_FALSE(WifiQr::isValidPassphrase(QStringLiteral("sae"), QString(256, QLatin1Char('x'))));

    EXPECT_TRUE(WifiQr::isValidPassphrase(QStringLiteral("none"), QString()));
    EXPECT_FALSE(WifiQr::isValidPassphrase(QStringLiteral("ieee8021x"), QStringLiteral("12345678")));
    EXPECT_FALSE(WifiQr::isValidPassphrase(QString(), QStringLiteral("12345678")));
}

TEST(WifiQrCompose, AsAndroidWritesIt)
{
    EXPECT_EQ(WifiQr::compose(net(QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("secret123"))),
              QStringLiteral("WIFI:S:Home;T:WPA;P:secret123;;"));
    EXPECT_EQ(WifiQr::compose(net(QStringLiteral("Lab"), QStringLiteral("sae"), QStringLiteral("pw"))),
              QStringLiteral("WIFI:S:Lab;T:SAE;P:pw;;"));
    EXPECT_EQ(WifiQr::compose(net(QStringLiteral("Old"), QStringLiteral("wep"), QStringLiteral("abcde"))),
              QStringLiteral("WIFI:S:Old;T:WEP;P:abcde;;"));
    /* No P: for an open network, whatever was passed in. */
    EXPECT_EQ(WifiQr::compose(net(QStringLiteral("Guest"), QStringLiteral("none"), QStringLiteral("x"))),
              QStringLiteral("WIFI:S:Guest;T:nopass;;"));
    EXPECT_EQ(WifiQr::compose(net(QStringLiteral("Hide"), QStringLiteral("psk"), QStringLiteral("12345678"), true)),
              QStringLiteral("WIFI:S:Hide;T:WPA;P:12345678;H:true;;"));
}

TEST(WifiQrCompose, Escapes)
{
    EXPECT_EQ(WifiQr::escape(QStringLiteral("a\\b;c,d:e\"f")), QStringLiteral("a\\\\b\\;c\\,d\\:e\\\"f"));
    EXPECT_EQ(WifiQr::compose(net(QStringLiteral("a;b"), QStringLiteral("psk"), QStringLiteral("p:w,d\\1234"))),
              QStringLiteral("WIFI:S:a\\;b;T:WPA;P:p\\:w\\,d\\\\1234;;"));
}

TEST(WifiQrCompose, NothingForWhatNoCodeCanDescribe)
{
    EXPECT_TRUE(WifiQr::compose(net(QString(), QStringLiteral("psk"), QStringLiteral("12345678"))).isEmpty());
    EXPECT_TRUE(WifiQr::compose(net(QString(33, QLatin1Char('a')), QStringLiteral("none"), QString())).isEmpty());
    EXPECT_TRUE(WifiQr::compose(net(QStringLiteral("n"), QStringLiteral("ieee8021x"), QStringLiteral("12345678"))).isEmpty());
    EXPECT_TRUE(WifiQr::compose(net(QStringLiteral("n"), QStringLiteral("psk"), QStringLiteral("short"))).isEmpty());
    EXPECT_TRUE(WifiQr::compose(net(QStringLiteral("n"), QStringLiteral("PSK"), QStringLiteral("12345678"))).isEmpty());
}

/* Whatever compose() writes, parse() reads back to the same network. */
TEST(WifiQrCompose, RoundTrip)
{
    const QList<WifiQr::Network> networks = {
        net(QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("secret123")),
        net(QStringLiteral("\"quoted\""), QStringLiteral("psk"), QStringLiteral("\"12345678\"")),
        net(QStringLiteral("\\;,:\""), QStringLiteral("sae"), QStringLiteral("\\;,:\"")),
        net(QStringLiteral("trailing\\"), QStringLiteral("psk"), QStringLiteral("endswith\\")),
        net(QStringLiteral(" spaced "), QStringLiteral("psk"), QStringLiteral(" padded pw ")),
        net(QStringLiteral("WIFI:S:x;;"), QStringLiteral("psk"), QStringLiteral("WIFI:P:y;;")),
        net(QStringLiteral("caf\u00e9 \u2615"), QStringLiteral("psk"), QStringLiteral("\u00fcber-geheim")),
        net(QString(32, QLatin1Char('s')), QStringLiteral("psk"), QString(63, QLatin1Char('p'))),
        net(QStringLiteral("hex"), QStringLiteral("psk"), QString(64, QLatin1Char('a'))),
        net(QStringLiteral("old"), QStringLiteral("wep"), QStringLiteral("0123456789")),
        net(QStringLiteral("open"), QStringLiteral("none"), QString(), true),
    };
    for (const WifiQr::Network &n : networks) {
        const QString text = WifiQr::compose(n);
        ASSERT_FALSE(text.isEmpty()) << qPrintable(n.ssid);
        expectNetwork(text, n.ssid, n.security, n.passphrase, n.hidden);
    }
}

TEST(WifiQrCodeQml, ParseGivesAMapWithEveryField)
{
    WifiQrCode qml;
    const QVariantMap ok = qml.parse(QStringLiteral("WIFI:S:Home;T:WPA;P:secret123;H:true;;"));
    EXPECT_TRUE(ok.value(QStringLiteral("valid")).toBool());
    EXPECT_EQ(ok.value(QStringLiteral("error")).toString(), QString());
    EXPECT_EQ(ok.value(QStringLiteral("ssid")).toString(), QStringLiteral("Home"));
    EXPECT_EQ(ok.value(QStringLiteral("security")).toString(), QStringLiteral("psk"));
    EXPECT_EQ(ok.value(QStringLiteral("passphrase")).toString(), QStringLiteral("secret123"));
    EXPECT_TRUE(ok.value(QStringLiteral("hidden")).toBool());

    const QVariantMap bad = qml.parse(QStringLiteral("WIFI:S:corp;T:WPA2-EAP;;"));
    EXPECT_FALSE(bad.value(QStringLiteral("valid")).toBool());
    EXPECT_EQ(bad.value(QStringLiteral("error")).toString(), QStringLiteral("enterprise"));
    EXPECT_EQ(bad.value(QStringLiteral("passphrase")).toString(), QString());

    EXPECT_EQ(qml.compose(QStringLiteral("Home"), QStringLiteral("psk"), QStringLiteral("secret123")),
              QStringLiteral("WIFI:S:Home;T:WPA;P:secret123;;"));
    EXPECT_TRUE(qml.isValidPassphrase(QStringLiteral("psk"), QStringLiteral("12345678")));
}

TEST(WifiQrCodeQml, EveryErrorHasAName)
{
    EXPECT_EQ(WifiQr::errorName(Error::None), QString());
    for (Error e : {Error::NotWifi, Error::TooLong, Error::NoSsid, Error::SsidTooLong,
                    Error::Enterprise, Error::UnknownSecurity, Error::BadPassphrase}) {
        const QString name = WifiQr::errorName(e);
        EXPECT_FALSE(name.isEmpty());
        EXPECT_NE(name, QStringLiteral("unknown"));
    }
}
