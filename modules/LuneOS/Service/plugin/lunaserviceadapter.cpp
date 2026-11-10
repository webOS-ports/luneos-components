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

#include <glib.h>
#include <QJSValueList>
#include <QDebug>
#include <QQmlEngine>
#include <QTimer>
#include <QCoreApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QPointer>

#include "lunaserviceadapter.h"
#include "webos_application.h"

#define LUNA_QML_LAUNCHER_PATH        "/usr/bin/qml-runner"
#define LUNA_QML_LAUNCHER_PATH_LUNEOS "/usr/sbin/luna-qml-launcher"

/*
 * Where a method registered with LunaService.registerMethod is routed. Each
 * method gets its own slot as luna-service2 method data, so adapters that
 * share one handle (two LunaService items with the same name) each get their
 * own calls, and a call that arrives after its adapter was destroyed meets an
 * empty slot rather than the freed adapter. A slot lives as long as the
 * handle it was registered on, because luna-service2 keeps its pointer until
 * then.
 */
struct MethodSlot
{
    QPointer<LunaServiceAdapter> owner;
    QJSValue callback;
};

typedef QHash<QString, MethodSlot*> MethodSlots;

/*
 * Made the first time it is used, not at static initialisation, whose order
 * with other statics cannot be relied on. The same goes for
 * globalServiceHandles() below.
 */
static QHash<LSHandle*, MethodSlots> &globalMethodSlots()
{
    static QHash<LSHandle*, MethodSlots> methodSlots;
    return methodSlots;
}

static void freeMethodSlots(LSHandle *handle)
{
    const MethodSlots handleSlots = globalMethodSlots().take(handle);
    qDeleteAll(handleSlots);
}

class LunaServiceHandle
{
public:
    LunaServiceHandle(LSHandle *handle) : mHandle(handle), mRefCount(0) { }

    LSHandle* handle() const
    {
        return mHandle;
    }

    void ref()
    {
        mRefCount++;
    }

    bool unref()
    {
        mRefCount--;
        if (mRefCount == 0) {
            LSError error;
            LSErrorInit(&error);

            if (!LSUnregister(mHandle, &error)) {
                qWarning("Failed to unregister service: %s", error.message);
                LSErrorFree(&error);
            }
            // luna-service2 calls nothing of this handle any more.
            freeMethodSlots(mHandle);

            return false;
        }

        return true;
    }

private:
    LSHandle *mHandle;
    unsigned int mRefCount;
};

static QMap<QString, LunaServiceHandle*> &globalServiceHandles()
{
    static QMap<QString, LunaServiceHandle*> serviceHandles;
    return serviceHandles;
}

LunaServiceMessage::LunaServiceMessage(LSMessage *message, QObject *parent) :
    QObject(parent),
    mMessage(message)
{
    LSMessageRef(mMessage);
}

LunaServiceMessage::~LunaServiceMessage()
{
    LSMessageUnref(mMessage);
}

QString LunaServiceMessage::payload() const
{
    return QString(LSMessageGetPayload(mMessage));
}

QString LunaServiceMessage::applicationId() const
{
    return QString(LSMessageGetApplicationID(mMessage));
}

QString LunaServiceMessage::serviceId() const
{
    return QString(LSMessageGetSenderServiceName(mMessage));
}

LSMessage* LunaServiceMessage::messageObject() const
{
    return mMessage;
}

LunaServiceCall::LunaServiceCall(QObject *parent) :
    QObject(parent),
    mServiceHandle(0),
    mToken(LSMESSAGE_TOKEN_INVALID),
    mResponseLimit(-1),
    mResponseCount(0),
    mDeferred(false)
{
}

LunaServiceCall::~LunaServiceCall()
{
    if (mToken != LSMESSAGE_TOKEN_INVALID)
        cancel();
}

void LunaServiceCall::setup(LSHandle *serviceHandle, QJSValue callback, QJSValue errorCallback, int responseLimit)
{
    mServiceHandle = serviceHandle;
    mCallback = callback;
    mErrorCallback = errorCallback;
    mResponseLimit = responseLimit;
}

bool LunaServiceCall::execute(const QString& uri, const QString& arguments)
{
    LSError error;
    LSErrorInit(&error);
    QString errorMessage;

    if (!mServiceHandle) {
        errorMessage = QString("Failed to call remote service %0: the LunaService is not registered").arg(uri);
        goto error;
    }

    {
        auto funcLSCall = (mResponseLimit == 1) ? LSCallOneReply : LSCall;
        
        if (!funcLSCall(mServiceHandle, uri.toUtf8().constData(), arguments.toUtf8().constData(),
                        &LunaServiceCall::responseCallback, this, &mToken, &error)) {
            qWarning("Failed to call remote service %s", uri.toUtf8().constData());
            errorMessage = QString("Failed to call remote service: %0").arg(error.message);
            goto error;
        }
    }

    return true;

error:
    if (LSErrorIsSet(&error)) {
        LSErrorPrint(&error, stderr);
        LSErrorFree(&error);
    }

    if (mErrorCallback.isCallable())
        mErrorCallback.call(QJSValueList() << errorMessage);

    return false;
}

void LunaServiceCall::defer(const QString& uri, const QString& arguments)
{
    mDeferred = true;
    mDeferredUri = uri;
    mDeferredArguments = arguments;
}

bool LunaServiceCall::executeDeferred(LSHandle *serviceHandle)
{
    mDeferred = false;
    mServiceHandle = serviceHandle;
    // execute may run the error callback, which may destroy this call:
    // nothing of it is touched after.
    const QString uri = mDeferredUri;
    const QString arguments = mDeferredArguments;
    mDeferredUri.clear();
    mDeferredArguments.clear();
    return execute(uri, arguments);
}

bool LunaServiceCall::responseCallback(LSHandle *handle, LSMessage *message, void *user_data)
{
    LunaServiceCall *call = static_cast<LunaServiceCall*>(user_data);
    return call->handleResponse(handle, message);
}

bool LunaServiceCall::handleResponse(LSHandle *handle, LSMessage *message)
{
    Q_UNUSED(handle);

    LunaServiceMessage msg(message);
    mResponseCount++;

    if (mCallback.isCallable()) {
        // The callback may cancel this call (a page ends its subscription
        // when the last message came) or destroy the LunaService it belongs
        // to; either deletes this object. Nothing of it is touched after
        // that: luna-service2 already knows the call is gone.
        QPointer<LunaServiceCall> self(this);
        QJSEngine *engine = qjsEngine(parent());
        if (engine) {
            mCallback.call(QJSValueList() << engine->newQObject(&msg));
            if (!self)
                return true;
        } else {
            qWarning("LunaService call answered, but its LunaService is in no QML engine");
        }
    }

    const char* category = LSMessageGetCategory(message);
    bool messageInErrorCategory = (category && strcmp(LUNABUS_ERROR_CATEGORY, category) == 0);

    if (messageInErrorCategory || (mResponseLimit != -1 && mResponseCount >= mResponseLimit))
        cancel();

    return true;
}

void LunaServiceCall::cancel()
{
    // Held until its service completes: it never goes out.
    if (mDeferred) {
        mDeferred = false;
        static_cast<LunaServiceAdapter*>(parent())->removePendingCall(this);
        return;
    }

    if (mToken == LSMESSAGE_TOKEN_INVALID)
        return;

    if (mServiceHandle == 0)
        return;

    if (mResponseLimit != 1 || mResponseCount != 1) {
        LSError error;
        LSErrorInit(&error);

        if (!LSCallCancel(mServiceHandle, mToken, &error)) {
            qWarning("Failed to cancel call");
            LSErrorPrint(&error, stderr);
            LSErrorFree(&error);
        }
    }

    mToken = LSMESSAGE_TOKEN_INVALID;

    LunaServiceAdapter *adapter = static_cast<LunaServiceAdapter*>(parent());
    adapter->removePendingCall(this);
}

GMainLoop* LunaServiceAdapter::mainLoop()
{
    static GMainLoop *mainLoop = 0;

    if (!mainLoop) {
        GMainContext *mainContext = g_main_context_default();
        mainLoop = g_main_loop_new(mainContext, TRUE);
    }

    return mainLoop;
}

LunaServiceAdapter::LunaServiceAdapter(QObject *parent) :
    QObject(parent),
    mName(""),
    mUsePrivateBus(false),
    mServiceHandle(0),
    mInitialized(false),
    mComplete(false),
    mService(""),
    mMethod(""),
    mHoldsHandleRef(false)
{
}

LunaServiceAdapter::~LunaServiceAdapter()
{
    Q_FOREACH (LunaServiceCall *call, mPendingCalls) {
        mPendingCalls.removeOne(call);
        delete call;
    }

    // Calls to methods this adapter registered get an error reply from now on
    // (serviceMethodCallback), unless another adapter took the method over.
    if (mServiceHandle) {
        const MethodSlots &handleSlots = globalMethodSlots()[mServiceHandle];
        for (const QString &methodPath : std::as_const(mRegisteredMethods)) {
            MethodSlot *slot = handleSlots.value(methodPath);
            if (slot && slot->owner == this) {
                slot->owner.clear();
                slot->callback = QJSValue();
            }
        }
        if (handleSlots.isEmpty())
            globalMethodSlots().remove(mServiceHandle);
    }

    // Only a reference this adapter took is given back: one that never
    // registered (or reused the handle of webos_application_init) has none.
    if (!mHoldsHandleRef)
        return;

    LunaServiceHandle *handle = globalServiceHandles().value(mName);

    if (handle && !handle->unref()) {
        globalServiceHandles().remove(mName);
        delete handle;
    }
}

bool LunaServiceAdapter::nameAllowed() const
{
    // qml-runner may register under any app ID (it is in containers.d), and
    // registers whatever name the app gives: an app would then speak with
    // the permissions of another. Under the launcher a LunaService therefore
    // only gets the app's own ID, which qml-runner set as applicationName.
    if (QCoreApplication::applicationFilePath() != LUNA_QML_LAUNCHER_PATH &&
        QCoreApplication::applicationFilePath() != LUNA_QML_LAUNCHER_PATH_LUNEOS)
        return true;

    return !QCoreApplication::applicationName().isEmpty() &&
           mName == QCoreApplication::applicationName();
}

void LunaServiceAdapter::classBegin()
{
}

/*
 * The service registers here, as its creation completes. QML may call it
 * before that - a binding, or another object completing first, such as a
 * Repeater whose delegates ask for something as they are made - so calls
 * made until then are held, and go out now, in the order they were made.
 * If the service could not be registered, each gets its error callback, as
 * a call on an unregistered service always did.
 */
void LunaServiceAdapter::componentComplete()
{
    mInitialized = registerService();
    mComplete = true;

    QPointer<LunaServiceAdapter> self(this);
    executeDeferredCalls();
    if (!self)
        return;

    if (mInitialized)
        Q_EMIT initialized();
}

void LunaServiceAdapter::executeDeferredCalls()
{
    QList<QPointer<LunaServiceCall>> deferred;
    for (LunaServiceCall *pending : std::as_const(mPendingCalls)) {
        if (pending->isDeferred())
            deferred.append(pending);
    }

    // A callback may cancel a call still held, which deletes it, or destroy
    // this adapter and with it every call.
    QPointer<LunaServiceAdapter> self(this);
    for (const QPointer<LunaServiceCall> &held : std::as_const(deferred)) {
        if (!self)
            return;
        if (held)
            held->executeDeferred(mServiceHandle);
    }
}

bool LunaServiceAdapter::registerService()
{
    LSError error;

    if (mName.length() == 0)
        mName = QCoreApplication::applicationName();

    if (!nameAllowed()) {
        qWarning("LunaService: an app %s may not use the name %s",
                 qUtf8Printable(QCoreApplication::applicationName()), qUtf8Printable(mName));
        return false;
    }

    // There are two main use-cases for LunaService:
    // 1. QML app is started via luna-qml-launcher or qml-runner
    //     -> the qml launcher will register an application handle with the name "luna-qml-launcher-<pid>"
    //     -> the app therefore needs to register its own applicative service, and do LS2 calls under its usual appId name
    //     -> if the app does LS2 calls under a specific name, LSCall will be used with a dedicated applicative service. 
    //        `--- Note that the app needs to be able to allow these names in the role json file !
    // 2. Standalone executable app using QML (luna-next, maliit-server...)
    //     -> The app may (or may not) register a handle using webos_application_init
    //     -> if the app does LS2 under the same name as webos_application_init, the handle is reused
    //     -> if the app does LS2 calls under a specific name, a new service is registered and LSCall will be used.
    //        `--- Note that the app needs to allow these names in the role json file

    // check wether we have the handle for the same service already cached
    
    if (globalServiceHandles().contains(mName)) {
        LunaServiceHandle *serviceHandle = globalServiceHandles().value(mName);
        serviceHandle->ref();
        mHoldsHandleRef = true;
        mServiceHandle = serviceHandle->handle();
    }
    else {
        LSErrorInit(&error);

        // If the app is a QML app launched with luna-qml-launcher, we want to follow the naming logic of web apps: appId-pid
        if (QCoreApplication::applicationFilePath() == LUNA_QML_LAUNCHER_PATH ||
            QCoreApplication::applicationFilePath() == LUNA_QML_LAUNCHER_PATH_LUNEOS) {
            QString serviceHandleName = mName + "-" + QString::number(QCoreApplication::applicationPid());
            if (!LSRegisterApplicationService(serviceHandleName.toUtf8().constData(), mName.toUtf8().constData(), &mServiceHandle, &error)) {
                qWarning("Could not register ls2 applicative service handle!");
                goto error;
            }

            if(!LSGmainAttach(mServiceHandle, mainLoop(), &error)) {
                qWarning("Could not attach to glib main loop!");
                goto error_registered;
            }

            LunaServiceHandle *handle = new LunaServiceHandle(mServiceHandle);
            handle->ref();
            mHoldsHandleRef = true;
            globalServiceHandles().insert(mName, handle);
        }
        else {
            // Standalone QML app
            
            // Using main appId name, and webos_application_init has already been used ? reuse the handle.
            if (mName == QCoreApplication::applicationName()) {
                char *app_id = NULL;
                LSHandle *service_handle = NULL;
                if (webos_application_get_handle(&app_id, &service_handle) && service_handle)
                {
                    mServiceHandle = service_handle;
                }
                g_free(app_id);
            }
            
            // if that didn't work, or if the name is custom, register the name
            if (!mServiceHandle) {
                // Standalone QML app: let's suppose the app knows what it is doing and is priviledged.
                // If not, it'll fail.
                if (!LSRegister(mName.toUtf8().constData(), &mServiceHandle, &error)) {
                    qWarning("Could not register ls2 service handle!");
                    goto error;
                }

                if(!LSGmainAttach(mServiceHandle, mainLoop(), &error)) {
                    qWarning("Could not attach to glib main loop!");
                    goto error_registered;
                }

                LunaServiceHandle *handle = new LunaServiceHandle(mServiceHandle);
                handle->ref();
                mHoldsHandleRef = true;
                globalServiceHandles().insert(mName, handle);
            }
        }
    }

    return true;

error_registered:
    // Registered but not attached: nobody holds this handle, so it goes.
    if (LSErrorIsSet(&error)) {
        LSErrorPrint(&error, stderr);
        LSErrorFree(&error);
    }
    if (!LSUnregister(mServiceHandle, &error)) {
        LSErrorPrint(&error, stderr);
        LSErrorFree(&error);
    }
    mServiceHandle = 0;
    return false;

error:
    if (LSErrorIsSet(&error)) {
        LSErrorPrint(&error, stderr);
        LSErrorFree(&error);
    }
    mServiceHandle = 0;
    return false;
}

QString LunaServiceAdapter::name() const
{
    return mName;
}

bool LunaServiceAdapter::usePrivateBus() const
{
    return mUsePrivateBus;
}

QString LunaServiceAdapter::service() const
{
    return mService;
}

QString LunaServiceAdapter::method() const
{
    return mMethod;
}

void LunaServiceAdapter::setName(const QString& name)
{
    if (mInitialized) {
        qWarning("Not allowed to change service name after it has been initialized");
        return;
    }

    mName = name;
}

void LunaServiceAdapter::setUsePrivateBus(bool usePrivateBus)
{
    if (mInitialized) {
        qWarning("Not allowed to change service type after it has been initialized");
        return;
    }

    mUsePrivateBus = usePrivateBus;
}

void LunaServiceAdapter::setService(const QString& service)
{
    if (!service.startsWith("palm://") && !service.startsWith("luna://"))
        qWarning("%s: Invalid service name %s set", __FUNCTION__, service.toUtf8().constData());
    mService = service;
    updateCallUri();
}

void LunaServiceAdapter::setMethod(const QString& method)
{
    mMethod = method;
    updateCallUri();
}

void LunaServiceAdapter::setResponseCallback(QJSValue callback)
{
    mResponseCallback = callback;
}

void LunaServiceAdapter::setErrorCallback(QJSValue callback)
{
    mErrorCallback = callback;
}

QJSValue LunaServiceAdapter::getResponseCallback() const
{
    return mResponseCallback;
}

QJSValue LunaServiceAdapter::getErrorCallback() const
{
    return mErrorCallback;
}

void LunaServiceAdapter::updateCallUri()
{
    mCallUri = mService;
    if (!mCallUri.endsWith("/"))
        mCallUri += "/";
    mCallUri += mMethod;
}

QString LunaServiceAdapter::buildMethodPath(const QString& category, const QString& method)
{
    QString methodPath;

    if (category.endsWith("/"))
        methodPath = category + method;
    else
        methodPath = category + "/" + method;

    return methodPath;
}

bool LunaServiceAdapter::registerMethod(const QString& category, const QString& name, QJSValue callback)
{
    LSError error;

    if (!mServiceHandle) {
        qWarning() << "Method" << name << "for category" << category
                   << "cannot be registered: the service is not registered";
        return false;
    }

    if (!callback.isCallable()) {
        qWarning() << "Got something as callback which is not callable:" << callback.toString();
        return false;
    }

    QString methodPath = buildMethodPath(category, name);
    MethodSlots &handleSlots = globalMethodSlots()[mServiceHandle];
    MethodSlot *slot = handleSlots.value(methodPath);

    if (slot && slot->owner == this) {
        qWarning() << "Method" << name << "for category" << category
                   << "already has a registered handler";
        return false;
    }

    LSErrorInit(&error);

    if (!slot) {
        LSMethod methods[2];
        memset(&methods, 0, sizeof(methods));
        QByteArray methodName = name.toUtf8();
        methods[0].name = methodName.constData();
        methods[0].function = &LunaServiceAdapter::serviceMethodCallback;

        // luna-service2 copies the method's name, function and flags.
        if (!LSRegisterCategoryAppend(mServiceHandle, category.toUtf8().constData(),
                                      methods, NULL, &error)) {
            qWarning() << "Could not register method handler for method"
                       << name << "in category" << category  << ":" << error.message;
            LSErrorFree(&error);
            if (handleSlots.isEmpty())
                globalMethodSlots().remove(mServiceHandle);
            return false;
        }

        slot = new MethodSlot;
        if (!LSMethodSetData(mServiceHandle, category.toUtf8().constData(),
                             methodName.constData(), slot, &error)) {
            qWarning() << "Failed to set data for method" << methodPath << ":"
                       << error.message;
            LSErrorFree(&error);
            // The method stays registered, without data: luna-service2 then
            // passes the category's, which is never set, and the call gets
            // its error reply.
            delete slot;
            if (handleSlots.isEmpty())
                globalMethodSlots().remove(mServiceHandle);
            return false;
        }
        handleSlots.insert(methodPath, slot);
    } else if (slot->owner) {
        qWarning() << "Method" << methodPath << "of" << mName
                   << "is taken over from another LunaService of that name";
    }

    slot->owner = this;
    slot->callback = callback;
    if (!mRegisteredMethods.contains(methodPath))
        mRegisteredMethods.append(methodPath);

    return true;
}

static bool replyError(LSHandle *handle, LSMessage *message, const char *errorText)
{
    QJsonObject reply;
    reply.insert("returnValue", false);
    reply.insert("errorCode", -1);
    reply.insert("errorText", QString::fromUtf8(errorText));

    LSError error;
    LSErrorInit(&error);
    if (!LSMessageReply(handle, message,
                        QJsonDocument(reply).toJson(QJsonDocument::Compact).constData(), &error)) {
        qWarning() << "Failed to send response to client:" << error.message;
        LSErrorFree(&error);
    }
    // The call is answered either way: luna-service2 has nothing to add.
    return true;
}

bool LunaServiceAdapter::serviceMethodCallback(LSHandle *handle, LSMessage *message, void *data)
{
    MethodSlot *slot = static_cast<MethodSlot*>(data);

    if (!slot || !slot->owner || !slot->callback.isCallable())
        return replyError(handle, message, "Method is not available");

    return slot->owner->handleServiceMethodCallback(handle, message, slot->callback);
}

// callback is a copy on purpose: the call may destroy this adapter, whose
// destructor clears the slot the callback came from, while it still runs.
bool LunaServiceAdapter::handleServiceMethodCallback(LSHandle *handle, LSMessage *message, QJSValue callback)
{
    QJSEngine *engine = qjsEngine(this);
    if (!engine)
        return replyError(handle, message, "Method is not available");

    LunaServiceMessage msg(message);
    // The callback may destroy this adapter; nothing of it is used after.
    QJSValue response = callback.call(QJSValueList() << engine->newQObject(&msg));

    QString responseStr;
    if (!response.isString()) {
        qWarning() << "Got something from callback which isn't a string:" << response.toString();
        qWarning() << "Sending error response to client";
        responseStr = "{\"returnValue\":false,\"errorText\":\"internal error occured\"}";
    }
    else {
        responseStr = response.toString();
    }

    LSError error;

    LSErrorInit(&error);

    if (!LSMessageReply(handle, message, responseStr.toUtf8().constData(), &error)) {
        qWarning() << "Failed to send response to client:" << error.message;
        LSErrorFree(&error);
        return false;
    }

    return true;
}

void LunaServiceAdapter::removePendingCall(LunaServiceCall *call)
{
    if (!mPendingCalls.contains(call))
        return;

    mPendingCalls.removeOne(call);

    delete call;
}

LunaServiceCall* LunaServiceAdapter::createAndExecuteCall(const QString& uri, const QString& arguments, QJSValue callback,  QJSValue errorCallback, int responseLimit)
{
    LunaServiceCall *call = new LunaServiceCall(this);

    call->setup(mServiceHandle, callback, errorCallback, responseLimit);
    mPendingCalls.append(call);

    if (!mComplete) {
        call->defer(uri, arguments);
        return call;
    }

    // The error callback may destroy this adapter, and the call with it.
    QPointer<LunaServiceCall> guard(call);
    call->execute(uri, arguments);

    return guard.data();
}

QObject* LunaServiceAdapter::call(const QString& uri, const QString& arguments, QJSValue callback, QJSValue errorCallback)
{
    return createAndExecuteCall(uri, arguments, callback, errorCallback, 1);
}

QObject* LunaServiceAdapter::call(const QString& arguments)
{
    return createAndExecuteCall(mCallUri, arguments, mResponseCallback, mErrorCallback, 1);
}

QObject* LunaServiceAdapter::call(const QJsonValue& arguments)
{
    QString argumentsAsStr = QJsonDocument(arguments.toObject()).toJson(QJsonDocument::Compact);
    return createAndExecuteCall(mCallUri, argumentsAsStr, mResponseCallback, mErrorCallback, 1);
}

QObject* LunaServiceAdapter::call(const QString& arguments, QJSValue callback, QJSValue errorCallback)
{
    return createAndExecuteCall(mCallUri, arguments, callback, errorCallback, 1);
}

QObject* LunaServiceAdapter::subscribe(const QString& uri, const QString& arguments, QJSValue callback, QJSValue errorCallback)
{
    return createAndExecuteCall(uri, arguments, callback, errorCallback, -1);
}

QObject* LunaServiceAdapter::subscribe(const QString& arguments)
{
    return createAndExecuteCall(mCallUri, arguments, mResponseCallback, mErrorCallback, -1);
}

QObject* LunaServiceAdapter::subscribe(const QJsonValue& arguments)
{
    QString argumentsAsStr = QJsonDocument(arguments.toObject()).toJson(QJsonDocument::Compact);
    return createAndExecuteCall(mCallUri, argumentsAsStr, mResponseCallback, mErrorCallback, -1);
}

QObject* LunaServiceAdapter::subscribe(const QString& arguments, QJSValue callback, QJSValue errorCallback)
{
    return createAndExecuteCall(mCallUri, arguments, callback, errorCallback, -1);
}

bool LunaServiceAdapter::addSubscription(const QString& key, QJSValue message)
{
    LunaServiceMessage *msg = 0;

    if (!message.isQObject())
        return false;

    msg = qobject_cast<LunaServiceMessage*>(message.toQObject());
    if (msg == 0 || !mServiceHandle)
        return false;

    if (!LSSubscriptionAdd(mServiceHandle, key.toUtf8().constData(), msg->messageObject(), NULL))
        return false;

    return true;
}

bool LunaServiceAdapter::replyToSubscribers(const QString& key, const QString& payload)
{
    if (!mServiceHandle)
        return false;

    if (!LSSubscriptionReply(mServiceHandle, key.toUtf8().constData(),
                             payload.toUtf8().constData(), NULL))
        return false;

    return true;
}
