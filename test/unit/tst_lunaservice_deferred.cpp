/*
 * (c) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License version 3, as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranties of
 * MERCHANTABILITY, SATISFACTORY QUALITY, or FITNESS FOR A PARTICULAR
 * PURPOSE.  See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along
 * with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// LunaService calls made before the service completed: held, then sent once
// it registered, in order; cancellable while held; an error if it could not
// register. Runs the real LunaServiceAdapter against fake_ls2.cpp.
#include <gtest/gtest.h>

#include <QCoreApplication>
#include <QJSEngine>
#include <QQmlComponent>
#include <QQmlEngine>
#include <QScopedPointer>
#include <QtQml>

#include "fake_ls2.h"
#include "lunaserviceadapter.h"

using Events = std::vector<std::string>;

QT_BEGIN_NAMESPACE
inline void PrintTo(const QString &s, std::ostream *os) { *os << '"' << s.toStdString() << '"'; }
QT_END_NAMESPACE

class LunaServiceDeferred : public ::testing::Test
{
protected:
    QQmlEngine engine;

    void SetUp() override { fakeBus().reset(); }

    // A LunaService whose creation has begun but not completed, as QML has
    // it while it evaluates bindings and completes the objects before it.
    LunaServiceAdapter *begin(QQmlComponent &component, const char *name)
    {
        component.setData(QByteArray("import LuneOS.Service 1.0\nLunaService { name: \"") + name + "\" }",
                          QUrl());
        EXPECT_TRUE(component.isReady()) << component.errorString().toStdString();
        return qobject_cast<LunaServiceAdapter *>(component.beginCreate(engine.rootContext()));
    }

    // A JS function that appends what it is called with to the global "log".
    QJSValue logger(const char *tag)
    {
        return engine.evaluate(QString("(function (m) { log.push('%1:' + "
                                       "(typeof m === 'string' ? m : 'response')); })").arg(tag));
    }

    QStringList log() { return engine.globalObject().property("log").toVariant().toStringList(); }

    void SetUpLog() { engine.globalObject().setProperty("log", engine.newArray()); }
};

TEST_F(LunaServiceDeferred, CallBeforeCompleteIsHeldThenSentAfterRegistering)
{
    QQmlComponent component(&engine);
    QScopedPointer<LunaServiceAdapter> svc(begin(component, "com.test.held"));
    ASSERT_TRUE(svc);

    svc->call("luna://com.test/one", "{\"a\":1}", QJSValue(), QJSValue());
    EXPECT_EQ(fakeBus().events, Events{}) << "nothing goes out before the service is up";

    component.completeCreate();
    EXPECT_EQ(fakeBus().events, (Events{"register:com.test.held", "call:luna://com.test/one {\"a\":1}"}));
}

TEST_F(LunaServiceDeferred, HeldCallsGoOutInTheOrderMadeAndKeepTheirKind)
{
    QQmlComponent component(&engine);
    QScopedPointer<LunaServiceAdapter> svc(begin(component, "com.test.order"));

    svc->subscribe("luna://com.test/watch", "{\"subscribe\":true}", QJSValue(), QJSValue());
    svc->call("luna://com.test/get", "{}", QJSValue(), QJSValue());
    component.completeCreate();

    EXPECT_EQ(fakeBus().events, (Events{"register:com.test.order",
                                        "subscribe:luna://com.test/watch {\"subscribe\":true}",
                                        "call:luna://com.test/get {}"}));
}

TEST_F(LunaServiceDeferred, InitializedComesAfterTheHeldCallsWentOut)
{
    QQmlComponent component(&engine);
    QScopedPointer<LunaServiceAdapter> svc(begin(component, "com.test.init"));
    QObject::connect(svc.data(), &LunaServiceAdapter::initialized,
                     [] { fakeBus().events.push_back("initialized"); });

    svc->call("luna://com.test/early", "{}", QJSValue(), QJSValue());
    component.completeCreate();

    EXPECT_EQ(fakeBus().events, (Events{"register:com.test.init", "call:luna://com.test/early {}",
                                        "initialized"}));
}

TEST_F(LunaServiceDeferred, AHeldCallCancelledNeverGoesOut)
{
    QQmlComponent component(&engine);
    QScopedPointer<LunaServiceAdapter> svc(begin(component, "com.test.cancel"));

    QObject *dropped = svc->call("luna://com.test/dropped", "{}", QJSValue(), QJSValue());
    svc->call("luna://com.test/kept", "{}", QJSValue(), QJSValue());
    ASSERT_TRUE(QMetaObject::invokeMethod(dropped, "cancel"));
    component.completeCreate();

    EXPECT_EQ(fakeBus().events, (Events{"register:com.test.cancel", "call:luna://com.test/kept {}"}))
        << "no call and no LSCallCancel for one that never went out";
}

TEST_F(LunaServiceDeferred, WhenRegisteringFailsHeldCallsGetTheirErrorThen)
{
    SetUpLog();
    fakeBus().registerOk = false;
    QQmlComponent component(&engine);
    QScopedPointer<LunaServiceAdapter> svc(begin(component, "com.test.refused"));
    bool initialized = false;
    QObject::connect(svc.data(), &LunaServiceAdapter::initialized, [&] { initialized = true; });

    svc->call("luna://com.test/x", "{}", logger("ok"), logger("err"));
    EXPECT_EQ(log(), QStringList{}) << "no error before the service even tried";

    component.completeCreate();
    ASSERT_EQ(log().size(), 1);
    EXPECT_TRUE(log().at(0).startsWith("err:")) << log().at(0).toStdString();
    EXPECT_TRUE(log().at(0).contains("not registered")) << log().at(0).toStdString();
    EXPECT_FALSE(initialized);
}

TEST_F(LunaServiceDeferred, AnErrorCallbackMayCancelAnotherHeldCall)
{
    SetUpLog();
    fakeBus().registerOk = false;
    QQmlComponent component(&engine);
    QScopedPointer<LunaServiceAdapter> svc(begin(component, "com.test.chain"));

    svc->call("luna://com.test/first", "{}", QJSValue(),
              engine.evaluate("(function (m) { log.push('first'); second.cancel(); })"));
    QObject *second = svc->call("luna://com.test/second", "{}", QJSValue(), logger("second"));
    engine.globalObject().setProperty("second", engine.newQObject(second));

    component.completeCreate();
    EXPECT_EQ(log(), QStringList{"first"}) << "the cancelled call is neither sent nor answered";
}

TEST_F(LunaServiceDeferred, ACallOnceCompleteGoesStraightOut)
{
    QQmlComponent component(&engine);
    QScopedPointer<LunaServiceAdapter> svc(begin(component, "com.test.after"));
    component.completeCreate();
    fakeBus().events.clear();

    svc->call("luna://com.test/now", "{}", QJSValue(), QJSValue());
    EXPECT_EQ(fakeBus().events, Events{"call:luna://com.test/now {}"});
}

TEST_F(LunaServiceDeferred, AServiceGoneBeforeCompletingSendsNothing)
{
    QQmlComponent component(&engine);
    LunaServiceAdapter *svc = begin(component, "com.test.gone");
    svc->call("luna://com.test/never", "{}", QJSValue(), QJSValue());
    delete svc;

    EXPECT_EQ(fakeBus().events, Events{});
}

// The way it happened in luna-next-cardshell: a binding calls the service
// while the object holding both is still being made.
TEST_F(LunaServiceDeferred, ABindingCallingTheServiceWhileItIsMadeReachesTheBus)
{
    SetUpLog();
    QQmlComponent component(&engine);
    component.setData("import QtQml\nimport LuneOS.Service 1.0\n"
                      "QtObject {\n"
                      "    property LunaService svc: LunaService { name: \"com.test.binding\" }\n"
                      "    property var early: svc.call(\"luna://com.test/binding\", \"{}\",\n"
                      "        function (m) {}, function (e) { log.push('err:' + e); })\n"
                      "}\n", QUrl());
    ASSERT_TRUE(component.isReady()) << component.errorString().toStdString();
    QScopedPointer<QObject> root(component.create());
    ASSERT_TRUE(root);

    EXPECT_EQ(fakeBus().events, (Events{"register:com.test.binding", "call:luna://com.test/binding {}"}));
    EXPECT_EQ(log(), QStringList{});
}

int main(int argc, char **argv)
{
    QCoreApplication app(argc, argv);
    qmlRegisterType<LunaServiceAdapter>("LuneOS.Service", 1, 0, "LunaService");
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
