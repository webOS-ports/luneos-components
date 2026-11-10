/*
 * Copyright (C) 2013-2015 Simon Busch <morphis@gravedo.de>
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

#ifndef LUNASERVICEADAPTER_H_
#define LUNASERVICEADAPTER_H_

#include <QObject>
#include <QString>
#include <QQmlParserStatus>
#include <QJSValue>
#include <QJsonValue>
#include <QList>
#include <QVariant>
#include <luna-service2/lunaservice.h>

/*
 * A message as QML sees it. serviceId is the sender's name as the hub
 * resolved it and is the one to base a decision on. applicationId is what the
 * sender wrote into its own message: the hub does not check it, so it says
 * which app a privileged sender (such as a web app manager) speaks for, and
 * nothing about a sender that is not trusted.
 */
class LunaServiceMessage : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString payload READ payload CONSTANT)
    Q_PROPERTY(QString applicationId READ applicationId CONSTANT)
    Q_PROPERTY(QString serviceId READ serviceId CONSTANT)

public:
    LunaServiceMessage(LSMessage *message, QObject *parent = 0);
    ~LunaServiceMessage();

    QString payload() const;
    QString applicationId() const;
    QString serviceId() const;

    LSMessage* messageObject() const;

private:
    LSMessage *mMessage;
};

class LunaServiceCall : public QObject
{
    Q_OBJECT

public:
    explicit LunaServiceCall(QObject *parent = 0);
    virtual ~LunaServiceCall();

    void setup(LSHandle *serviceHandle, QJSValue callback, QJSValue errorCallback, int responseLimit = -1);
    bool execute(const QString& uri, const QString& arguments);

    // A call made before its LunaService completed: it goes out with
    // executeDeferred once the service is registered (or failed to be).
    void defer(const QString& uri, const QString& arguments);
    bool isDeferred() const { return mDeferred; }
    bool executeDeferred(LSHandle *serviceHandle);

    Q_INVOKABLE void cancel();

private:
    LSHandle *mServiceHandle;
    QJSValue mCallback;
    QJSValue mErrorCallback;
    LSMessageToken mToken;
    int mResponseLimit;
    int mResponseCount;
    bool mDeferred;
    QString mDeferredUri;
    QString mDeferredArguments;

    static bool responseCallback(LSHandle *handle, LSMessage *message, void *user_data);
    bool handleResponse(LSHandle *handle, LSMessage *message);
};

class LunaServiceAdapter : public QObject,
                           public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    Q_PROPERTY(QString name READ name WRITE setName)
    Q_PROPERTY(bool usePrivateBus READ usePrivateBus WRITE setUsePrivateBus)
    Q_PROPERTY(QString service READ service WRITE setService)
    Q_PROPERTY(QString method READ method WRITE setMethod)
    Q_PROPERTY(QJSValue onResponse READ getResponseCallback WRITE setResponseCallback)
    Q_PROPERTY(QJSValue onError READ getErrorCallback WRITE setErrorCallback)

public:
    LunaServiceAdapter(QObject *parent = 0);
    virtual ~LunaServiceAdapter();

    void classBegin();
    void componentComplete();

    QString name() const;
    bool usePrivateBus() const;
    QString service() const;
    QString method() const;
    QJSValue getResponseCallback() const;
    QJSValue getErrorCallback() const;

    void setName(const QString& name);
    void setUsePrivateBus(bool usePrivateBus);
    void setService(const QString& service);
    void setMethod(const QString& method);
    void setResponseCallback(QJSValue callback);
    void setErrorCallback(QJSValue callback);

    Q_INVOKABLE QObject* call(const QString& uri, const QString& arguments, QJSValue callback, QJSValue errorCallback);
    Q_INVOKABLE QObject* call(const QString& arguments);
    Q_INVOKABLE QObject* call(const QJsonValue& arguments);
    Q_INVOKABLE QObject* call(const QString& arguments, QJSValue, QJSValue errorCallback);
    Q_INVOKABLE QObject* subscribe(const QString& uri, const QString& arguments, QJSValue callback, QJSValue errorCallback);
    Q_INVOKABLE QObject* subscribe(const QString& arguments);
    Q_INVOKABLE QObject* subscribe(const QJsonValue& arguments);
    Q_INVOKABLE QObject* subscribe(const QString& arguments, QJSValue callback, QJSValue errorCallback);
    Q_INVOKABLE bool registerMethod(const QString& category, const QString& name, QJSValue callback);
    Q_INVOKABLE bool addSubscription(const QString& key, QJSValue message);
    Q_INVOKABLE bool replyToSubscribers(const QString& key, const QString& payload);

    void removePendingCall(LunaServiceCall *call);

    LSHandle *getInternalLSHandle()  { return mServiceHandle; }
Q_SIGNALS:
    void initialized();

private:
    QString mName;
    bool mUsePrivateBus;
    LSHandle *mServiceHandle;
    bool mInitialized;
    // Whether componentComplete ran: calls made before it are held
    // (LunaServiceCall::defer) rather than sent on a handle not there yet.
    bool mComplete;
    QString mService;
    QString mMethod;
    QJSValue mResponseCallback;
    QJSValue mErrorCallback;
    QString mCallUri;
    QList<LunaServiceCall*> mPendingCalls;

    LunaServiceCall* createAndExecuteCall(const QString& uri, const QString& arguments, QJSValue callback, QJSValue errorCallback, int responseLimit);
    bool registerService();
    void executeDeferredCalls();

    QString buildMethodPath(const QString& category, const QString& method);
    void updateCallUri();

    static bool serviceMethodCallback(LSHandle *handle, LSMessage *message, void *data);
    bool handleServiceMethodCallback(LSHandle *handle, LSMessage *message, QJSValue callback);
    bool nameAllowed() const;

    // The methods this adapter registered (category/method), whose slots
    // (lunaserviceadapter.cpp) it lets go of when it is destroyed.
    QList<QString> mRegisteredMethods;
    // Whether this adapter holds a reference on serviceHandles[mName].
    bool mHoldsHandleRef;

    static GMainLoop *mainLoop();
};

#endif
