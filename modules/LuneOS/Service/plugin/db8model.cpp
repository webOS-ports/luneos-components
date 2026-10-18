/*
 * Copyright (C) 2015 Simon Busch <morphis@gravedo.de>
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

#include <QCoreApplication>
#include <QJsonObject>
#include <QJsonDocument>
#include <QQmlEngine>
#include <QDebug>

#include <luna-service2/lunaservice.h>

#include "db8model.h"
#include "lunaserviceadapter.h"

Db8Model::Db8Model(QObject *parent) :
    QAbstractListModel(parent),
    mWatch(false),
    mAllPages(false),
    mHandle(0),
    mStatus(QStringLiteral("null")),
    mErrorCode(0),
    mGeneration(0),
    mRestartQueued(false)
{
    connect(this, &Db8Model::rowsInserted, [=]() { Q_EMIT countChanged(); });
    connect(this, &Db8Model::rowsRemoved, [=]() { Q_EMIT countChanged(); });
}

void Db8Model::classBegin()
{
    mLS2Service.classBegin();
}

void Db8Model::componentComplete()
{
    mLS2Service.setUsePrivateBus(false);
    mLS2Service.setName(QCoreApplication::applicationName());
    mLS2Service.componentComplete();

    mHandle = mLS2Service.getInternalLSHandle();
    restart();
}

Db8Model::~Db8Model()
{
    // Cancelled calls get no reply, so nothing can reach this model after
    // it is gone.
    for (auto it = mCalls.constBegin(); it != mCalls.constEnd(); ++it) {
        if (mHandle) {
            LSError lsError;
            LSErrorInit(&lsError);
            if (!LSCallCancel(mHandle, it.key(), &lsError)) {
                LSErrorPrint(&lsError, stderr);
                LSErrorFree(&lsError);
            }
        }
        delete it.value();
    }
}

QVariant Db8Model::get(int index)
{
    if (index < 0 || index >= mResults.count())
        return QVariant();

    QJsonValue mValue = mResults.at(index);
    return mValue.toVariant();
}

void Db8Model::refresh()
{
    restart();
}

void Db8Model::setWatch(bool watch)
{
    if (mWatch != watch) {
        mWatch = watch;
        Q_EMIT watchChanged();
        if (mHandle) {
            restart();
        }
    }
}

void Db8Model::setAllPages(bool allPages)
{
    if (mAllPages != allPages) {
        mAllPages = allPages;
        Q_EMIT allPagesChanged();
        if (mHandle) {
            restart();
        }
    }
}

void Db8Model::setQuery(const QJsonValue &query)
{
    if (mQuery != query) {
        mQuery = query;
        Q_EMIT queryChanged();
        if (mHandle) {
            restart();
        }
    }
}

void Db8Model::setKind(const QString &kind)
{
    if (mKind != kind) {
        mKind = kind;
        Q_EMIT kindChanged();
        if (mHandle) {
            restart();
        }
    }
}

void Db8Model::setStatus(const QString &status, const QString &errorText, int errorCode)
{
    if (status == mStatus && errorText == mErrorText && errorCode == mErrorCode)
        return;
    mStatus = status;
    mErrorText = errorText;
    mErrorCode = errorCode;
    Q_EMIT statusChanged();
}

bool Db8Model::cbProcessResults(LSHandle *handle, LSMessage *message, void *context)
{
    Q_UNUSED(handle);

    // Calls are cancelled before their model goes or a find is replaced,
    // so a reply always finds both.
    Call *call = static_cast<Call *>(context);
    Db8Model *model = call->model.data();
    const QJsonObject response = QJsonDocument::fromJson(LSMessageGetPayload(message)).object();

    if (call->find) {
        const bool current = model && call->generation == model->mGeneration;
        if (!call->keep) {
            if (model)
                model->mCalls.remove(LSMessageGetResponseToken(message));
            delete call;
        }
        if (current)
            model->handleFindReply(response);
        return true;
    }

    // A write: db8's reply to the caller, as an object.
    QJSValue callback = call->callback;
    if (model)
        model->mCalls.remove(LSMessageGetResponseToken(message));
    delete call;
    if (!model)
        return true;
    if (callback.isCallable()) {
        QQmlEngine *engine = qmlEngine(model);
        if (engine)
            callback.call(QJSValueList() << engine->toScriptValue(response.toVariantMap()));
    } else if (!response.value(QStringLiteral("returnValue")).toBool()) {
        qWarning() << "db8 call failed:" << response.value(QStringLiteral("errorText")).toString();
    }
    return true;
}

void Db8Model::handleFindReply(const QJsonObject &response)
{
    if (!response.value(QStringLiteral("returnValue")).toBool()) {
        handleFailedDatabaseQuery(response.value(QStringLiteral("errorText")).toString(),
                                  response.value(QStringLiteral("errorCode")).toInt());
        return;
    }

    // A watch answering again: the results would differ now. With all
    // pages each page watches its own range, and several can fire at once.
    if (response.value(QStringLiteral("fired")).toBool(false)) {
        if (!mRestartQueued) {
            mRestartQueued = true;
            QMetaObject::invokeMethod(this, "refresh", Qt::QueuedConnection);
        }
        return;
    }

    const QJsonArray results = response.value(QStringLiteral("results")).toArray();
    for (const auto &v : results)
        mPending.append(v);

    const QJsonValue next = response.value(QStringLiteral("next"));
    if (mAllPages && next.isString() && !results.isEmpty()) {
        // db8 watches the range of keys a page returned: every page watches,
        // or a change past the first one would go unnoticed.
        requestPage(next, mWatch);
        return;
    }

    processResults(mPending);
    mPending = QJsonArray();
    setStatus(QStringLiteral("ready"));
}

void Db8Model::handleFailedDatabaseQuery(const QString &errorMessage, int errorCode)
{
    qWarning() << "Failed to query database for kind"
               << mKind
               << "with query"
               << QJsonDocument(mQuery.toObject()).toJson()
               << ":"
               << errorMessage;

    mPending = QJsonArray();
    setStatus(QStringLiteral("error"), errorMessage, errorCode);
    Q_EMIT error(errorMessage, errorCode);
}

void Db8Model::processResults(const QJsonArray &results)
{
    int oldCount = rowCount();

    beginResetModel();
    mResults = results;
    resetRoles();
    endResetModel();

    if (rowCount() != oldCount) { Q_EMIT countChanged(); }
}

void Db8Model::resetRoles()
{
    mRoles.clear();

    if (mResults.count() == 0)
        return;

    QJsonValue current = mResults.at(0);

    if (!current.isObject())
        return;

    int n = 1;
    Q_FOREACH(const QString &key, current.toObject().keys()) {
        mRoles.insert(Qt::UserRole + n, key.toUtf8());
        n++;
    }
}

void Db8Model::cancelFind()
{
    for (auto it = mCalls.begin(); it != mCalls.end();) {
        if (!it.value()->find) {
            ++it;
            continue;
        }
        if (mHandle) {
            LSError lsError;
            LSErrorInit(&lsError);
            if (!LSCallCancel(mHandle, it.key(), &lsError)) {
                LSErrorPrint(&lsError, stderr);
                LSErrorFree(&lsError);
            }
        }
        delete it.value();
        it = mCalls.erase(it);
    }
}

void Db8Model::restart()
{
    mRestartQueued = false;
    cancelFind();
    ++mGeneration;
    mPending = QJsonArray();

    if (mKind.length() == 0) {
        setStatus(QStringLiteral("null"));
        return;
    }

    setStatus(QStringLiteral("loading"));
    requestPage(QJsonValue(), mWatch);
}

void Db8Model::requestPage(const QJsonValue &page, bool subscribe)
{
    QJsonObject q;
    if (mQuery.isObject())
        q = mQuery.toObject();
    q.insert(QStringLiteral("from"), mKind);
    if (page.isString())
        q.insert(QStringLiteral("page"), page);

    QJsonObject request;
    request.insert(QStringLiteral("query"), q);
    if (subscribe)
        request.insert(QStringLiteral("watch"), true);

    Call *call = new Call{this, mGeneration, true, QJSValue(), subscribe};
    if (!send(QStringLiteral("find"), request, call, subscribe))
        handleFailedDatabaseQuery(QStringLiteral("Failed to call luna://com.palm.db/find"), -1);
}

bool Db8Model::send(const QString &method, const QJsonObject &payload, Call *call, bool subscribe)
{
    if (!mHandle) {
        delete call;
        return false;
    }

    const QByteArray uri = QStringLiteral("luna://com.palm.db/%1").arg(method).toUtf8();
    const QByteArray json = QJsonDocument(payload).toJson(QJsonDocument::Compact);

    LSError lsError;
    LSErrorInit(&lsError);
    LSMessageToken token = LSMESSAGE_TOKEN_INVALID;
    const bool ok = subscribe
        ? LSCall(mHandle, uri.constData(), json.constData(), &Db8Model::cbProcessResults, call, &token, &lsError)
        : LSCallOneReply(mHandle, uri.constData(), json.constData(), &Db8Model::cbProcessResults, call, &token, &lsError);
    if (!ok) {
        qWarning() << "Failed to call remote service" << uri;
        if (LSErrorIsSet(&lsError)) {
            LSErrorPrint(&lsError, stderr);
            LSErrorFree(&lsError);
        }
        delete call;
        return false;
    }
    mCalls.insert(token, call);
    return true;
}

void Db8Model::write(const QString &method, const QJsonObject &payload, const QJSValue &callback)
{
    Call *call = new Call{this, mGeneration, false, callback, false};
    if (send(method, payload, call, false))
        return;

    // Not sent: the caller hears so as db8 would have said it.
    QQmlEngine *engine = qmlEngine(this);
    if (callback.isCallable() && engine) {
        QVariantMap reply;
        reply.insert(QStringLiteral("returnValue"), false);
        reply.insert(QStringLiteral("errorCode"), -1);
        reply.insert(QStringLiteral("errorText"), QStringLiteral("Failed to call luna://com.palm.db/%1").arg(method));
        callback.call(QJSValueList() << engine->toScriptValue(reply));
    }
}

QJsonArray Db8Model::withKind(const QJSValue &objects, const QString &kind) const
{
    QJsonArray out;
    const QJsonArray in = QJsonValue::fromVariant(objects.toVariant()).toArray();
    for (const auto &v : in) {
        QJsonObject object = v.toObject();
        if (!object.contains(QStringLiteral("_kind")) && !kind.isEmpty())
            object.insert(QStringLiteral("_kind"), kind);
        out.append(object);
    }
    return out;
}

void Db8Model::put(const QJSValue &objects, const QJSValue &callback)
{
    write(QStringLiteral("put"), QJsonObject{{QStringLiteral("objects"), withKind(objects, mKind)}}, callback);
}

void Db8Model::merge(const QJSValue &objects, const QJSValue &callback)
{
    write(QStringLiteral("merge"), QJsonObject{{QStringLiteral("objects"), withKind(objects, mKind)}}, callback);
}

void Db8Model::del(const QJSValue &ids, const QJSValue &callback)
{
    write(QStringLiteral("del"), QJsonObject{{QStringLiteral("ids"), QJsonValue::fromVariant(ids.toVariant())}}, callback);
}

void Db8Model::putOnKind(const QString &kind, const QJSValue &objects, const QJSValue &callback)
{
    write(QStringLiteral("put"), QJsonObject{{QStringLiteral("objects"), withKind(objects, kind)}}, callback);
}

void Db8Model::putKind(const QJSValue &kindDefinition, const QJSValue &callback)
{
    write(QStringLiteral("putKind"), QJsonValue::fromVariant(kindDefinition.toVariant()).toObject(), callback);
}

int Db8Model::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return static_cast<int>(mResults.count());
}

QVariant Db8Model::data(const QModelIndex &index, int role) const
{
    int currentIndex = index.row();
    if (currentIndex < 0 || currentIndex >= mResults.count())
        return QVariant();

    if (role < Qt::UserRole)
        return QVariant();

    QJsonObject object = mResults.at(currentIndex).toObject();

    return object.value(mRoles[role]).toVariant();
}

QHash<int, QByteArray> Db8Model::roleNames() const
{
    return mRoles;
}
