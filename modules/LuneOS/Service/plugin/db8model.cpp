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
#include <QDebug>

#include <luna-service2/lunaservice.h>

#include "db8model.h"
#include "lunaserviceadapter.h"

Db8Model::Db8Model(QObject *parent) :
    QAbstractListModel(parent),
    mToken(LSMESSAGE_TOKEN_INVALID),
    mHandle(0)
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
    if (mHandle) {
        restart();
    }
}

Db8Model::~Db8Model()
{
    if(mWatch && mToken != LSMESSAGE_TOKEN_INVALID) {
        LSError error;
        LSErrorInit(&error);
        LSCallCancel(mHandle, mToken, &error);
        if (LSErrorIsSet(&error)) {
            LSErrorPrint(&error, stderr);
            LSErrorFree(&error);
        }
    }
}

QVariant Db8Model::get(int index)
{
    if (index < 0 || index >= mResults.count())
        return QVariant();

    QJsonValue mValue = mResults.at(index);
    return mValue.toVariant();
}

void Db8Model::setWatch(bool watch)
{
    if (mWatch != watch) {
        mWatch = watch;
        watchChanged();
        if (mHandle) {
            restart();
        }
    }
}

void Db8Model::setQuery(const QJsonValue &query)
{
    if (mQuery != query) {
        mQuery = query;
        queryChanged();
        if (mHandle) {
            restart();
        }
    }
}

void Db8Model::setKind(const QString &kind)
{
    if (mKind != kind) {
        mKind = kind;
        kindChanged();
        if (mHandle) {
            restart();
        }
    }
}

bool Db8Model::cbProcessResults(LSHandle *handle, LSMessage *message, void *context)
{
    Q_UNUSED(handle);

    Db8Model *model = static_cast<Db8Model*>(context);

    qDebug() << Q_FUNC_INFO << LSMessageGetPayload(message);

    QJsonObject response = QJsonDocument::fromJson(LSMessageGetPayload(message)).object();

    bool success = response.value("returnValue").toBool();
    if (!success)
        model->handleFailedDatabaseQuery(response.value("errorText").toString());

    bool fired = response.value("fired").toBool(false);
    if (fired) {
        g_timeout_add(0, cbTriggerRestart, model);
        return true;
    }

    model->processResults(response.value("results"));

    return true;
}

gboolean Db8Model::cbTriggerRestart(gpointer user_data)
{
    Db8Model *model = static_cast<Db8Model*>(user_data);
    model->restart();
    return FALSE;
}

void Db8Model::handleFailedDatabaseQuery(const QString &errorMessage)
{
    qWarning() << "Failed to query database for kind"
               << mKind
               << "with query"
               << QJsonDocument(mQuery.toObject()).toJson()
               << ":"
               << errorMessage;
}

void Db8Model::processResults(const QJsonValue &results)
{
    qDebug() << Q_FUNC_INFO << "Got results" << results;

    if (!results.isArray())
        return;

    beginResetModel();
    mResults = results.toArray();
    resetRoles();
    endResetModel();
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
    Q_FOREACH(QString key, current.toObject().keys()) {
        mRoles.insert(Qt::UserRole + n, key.toUtf8());
        n++;
    }
}

void Db8Model::restart()
{
    qDebug() << Q_FUNC_INFO;

    if (mKind.length() == 0)
        return;

    QJsonObject request;
    QJsonObject query;

    if (mQuery.isObject())
        query = mQuery.toObject();

    query.insert("from", mKind);
    request.insert("query", query);

    if (mWatch)
        request.insert("watch", true);

    QString payload = QJsonDocument(request).toJson();

    if (mHandle) {
        LSError error;
        LSErrorInit(&error);
        QString errorMessage;

        if (!mWatch) {
            if (!LSCallOneReply(mHandle, "luna://com.palm.db/find", payload.toUtf8().constData(),
                                &Db8Model::cbProcessResults, this, &mToken, &error)) {
                qWarning("Failed to call remote service luna://com.palm.db/find");
                errorMessage = QString("Failed to call remote service: %0").arg(error.message);
            }
        }
        else {
            if (!LSCall(mHandle, "luna://com.palm.db/find", payload.toUtf8().constData(),
                                &Db8Model::cbProcessResults, this, &mToken, &error)) {
                qWarning("Failed to call remote service luna://com.palm.db/find");
                errorMessage = QString("Failed to call remote service: %0").arg(error.message);
            }
        }

        if (LSErrorIsSet(&error)) {
            LSErrorPrint(&error, stderr);
            LSErrorFree(&error);
        }
    }
}

int Db8Model::rowCount(const QModelIndex &parent) const
{
    return mResults.count();
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
