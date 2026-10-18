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

#ifndef DB8MODEL_H
#define DB8MODEL_H

#include <QAbstractListModel>
#include <QQmlParserStatus>
#include <QJsonValue>
#include <QJsonArray>
#include <QJSValue>
#include <QPointer>
#include <QHash>

#include <luna-service2/lunaservice.h>

#include "lunaserviceadapter.h"

/*
 * The results of a db8 query as a list model, and the calls that change
 * them.
 *
 *     Db8Model {
 *         kind: "com.example.note:1"
 *         query: ({ orderBy: "title" })
 *         watch: true        // find again when the results would change
 *                            // (every page watches with allPages)
 *         allPages: true     // follow db8's pages (500 at most each)
 *         onError: (text, code) => console.warn(text, code)
 *     }
 *     model.put([{ text: "Hi" }], (r) => console.log(r.returnValue));
 *
 * status is "null" (no kind yet), "loading", "ready" or "error"; on an
 * error, errorText and errorCode are db8's (-3963: permission denied,
 * -3970: kind not registered) and the rows from before stay. The calls
 * - put, merge, del, putOnKind, putKind - go to com.palm.db with the
 * model's kind filled in where an object has none, and hand db8's reply
 * to the optional callback. The app needs "database.operation".
 */
class Db8Model : public QAbstractListModel,
                 public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_PROPERTY(QString kind READ kind WRITE setKind NOTIFY kindChanged)
    Q_PROPERTY(QJsonValue query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(bool watch READ watch WRITE setWatch NOTIFY watchChanged)
    Q_PROPERTY(bool allPages READ allPages WRITE setAllPages NOTIFY allPagesChanged)

    Q_PROPERTY(unsigned int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QString errorText READ errorText NOTIFY statusChanged)
    Q_PROPERTY(int errorCode READ errorCode NOTIFY statusChanged)

public:
    explicit Db8Model(QObject *parent = 0);
    virtual ~Db8Model();

    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const;

    Q_INVOKABLE QVariant get(int index);

    // Runs the query again.
    Q_INVOKABLE void refresh();

    Q_INVOKABLE void put(const QJSValue &objects, const QJSValue &callback = QJSValue());
    Q_INVOKABLE void merge(const QJSValue &objects, const QJSValue &callback = QJSValue());
    Q_INVOKABLE void del(const QJSValue &ids, const QJSValue &callback = QJSValue());
    Q_INVOKABLE void putOnKind(const QString &kind, const QJSValue &objects, const QJSValue &callback = QJSValue());
    Q_INVOKABLE void putKind(const QJSValue &kindDefinition, const QJSValue &callback = QJSValue());

    unsigned int count() const { return rowCount(); }

    QString kind() const { return mKind; }
    void setKind(const QString &kind);

    QJsonValue query() const { return mQuery; }
    void setQuery(const QJsonValue &query);

    bool watch() const { return mWatch; }
    void setWatch(bool watch);

    bool allPages() const { return mAllPages; }
    void setAllPages(bool allPages);

    QString status() const { return mStatus; }
    QString errorText() const { return mErrorText; }
    int errorCode() const { return mErrorCode; }

Q_SIGNALS:
    void kindChanged();
    void queryChanged();
    void watchChanged();
    void allPagesChanged();
    void countChanged();
    void statusChanged();
    void error(const QString &errorText, int errorCode);

protected:
    virtual void classBegin();
    virtual void componentComplete();

private:
    // One call in flight: what its reply is for. The find's own call lives
    // as long as its watch; every other call ends with its reply.
    struct Call {
        QPointer<Db8Model> model;
        quint64 generation;
        bool find;
        QJSValue callback;
        bool keep;      // a watching find: replies until it is cancelled
    };

    bool mWatch;
    bool mAllPages;
    QString mKind;
    QJsonValue mQuery;
    LunaServiceAdapter mLS2Service;
    LSHandle *mHandle;
    QJsonArray mResults;
    QJsonArray mPending;
    QHash<int, QByteArray> mRoles;
    QString mStatus;
    QString mErrorText;
    int mErrorCode;
    quint64 mGeneration;
    bool mRestartQueued;
    QHash<LSMessageToken, Call *> mCalls;

    void restart();
    void cancelFind();
    bool send(const QString &method, const QJsonObject &payload, Call *call, bool subscribe);
    void requestPage(const QJsonValue &page, bool subscribe);
    void setStatus(const QString &status, const QString &errorText = QString(), int errorCode = 0);
    void handleFindReply(const QJsonObject &response);
    void handleFailedDatabaseQuery(const QString &errorMessage, int errorCode);
    void processResults(const QJsonArray &results);
    void resetRoles();
    void write(const QString &method, const QJsonObject &payload, const QJSValue &callback);
    QJsonArray withKind(const QJSValue &objects, const QString &kind) const;

    static bool cbProcessResults(LSHandle *handle, LSMessage *message, void *context);
};

#endif // DB8MODEL_H
