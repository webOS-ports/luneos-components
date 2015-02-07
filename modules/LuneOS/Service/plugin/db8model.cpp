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

#include "db8model.h"

Db8Model::Db8Model(QObject *parent) :
    QAbstractListModel(parent)
{
    try {
        mHandle = LS::registerService(QCoreApplication::applicationName().toUtf8().constData());
        mHandle.attachToLoop(g_main_context_default());
    }
    catch (LS::Error &error) {
        qWarning("Failed to register service handle: %s", error.what());
    }
}

void Db8Model::classBegin()
{
}

void Db8Model::componentComplete()
{
    restart();
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

    if (!mWatch)
        mCurrentCall = mHandle.callOneReply("luna://com.palm.db/find",
                                            payload.toUtf8().constData());
    else
        mCurrentCall = mHandle.callMultiReply("luna://com.palm.db/find",
                                              payload.toUtf8().constData());

    mCurrentCall.continueWith(cbProcessResults, this);
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
