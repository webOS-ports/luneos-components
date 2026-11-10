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

// A stand-in for luna-service2 and webos-application, enough for
// LunaServiceAdapter: it records what the adapter asks of the bus.
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <glib.h>
#include <luna-service2/lunaservice.h>

#include "fake_ls2.h"

struct LSHandle { int id; };
struct LSMessage { int refs; };

FakeBus &fakeBus()
{
    static FakeBus bus;
    return bus;
}

static LSHandle theHandle = { 1 };

static bool fail(LSError *lserror, const char *what)
{
    if (lserror) {
        lserror->error_code = -1;
        lserror->message = strdup(what);
    }
    return false;
}

extern "C" {

bool LSErrorInit(LSError *error)
{
    memset(error, 0, sizeof(*error));
    return true;
}

void LSErrorFree(LSError *error)
{
    free(error->message);
    error->message = nullptr;
    error->error_code = 0;
}

bool LSErrorIsSet(LSError *lserror) { return lserror && lserror->error_code != 0; }

void LSErrorPrint(LSError *lserror, FILE *out)
{
    fprintf(out, "fake LSError: %s\n", lserror->message ? lserror->message : "");
}

bool LSRegister(const char *name, LSHandle **sh, LSError *lserror)
{
    fakeBus().events.push_back(std::string("register:") + name);
    if (!fakeBus().registerOk)
        return fail(lserror, "register refused");
    *sh = &theHandle;
    return true;
}

bool LSRegisterApplicationService(const char *name, const char *, LSHandle **sh, LSError *lserror)
{
    return LSRegister(name, sh, lserror);
}

bool LSGmainAttach(LSHandle *, GMainLoop *, LSError *) { return true; }

bool LSUnregister(LSHandle *, LSError *)
{
    fakeBus().events.push_back("unregister");
    return true;
}

static bool doCall(const char *kind, LSHandle *sh, const char *uri, const char *payload,
                   LSMessageToken *token)
{
    (void)sh;
    fakeBus().events.push_back(std::string(kind) + ":" + uri + " " + payload);
    *token = ++fakeBus().lastToken;
    return true;
}

bool LSCall(LSHandle *sh, const char *uri, const char *payload, LSFilterFunc, void *,
            LSMessageToken *ret_token, LSError *)
{
    return doCall("subscribe", sh, uri, payload, ret_token);
}

bool LSCallOneReply(LSHandle *sh, const char *uri, const char *payload, LSFilterFunc, void *,
                    LSMessageToken *ret_token, LSError *)
{
    return doCall("call", sh, uri, payload, ret_token);
}

bool LSCallCancel(LSHandle *, LSMessageToken token, LSError *)
{
    fakeBus().events.push_back("cancel:" + std::to_string(token));
    return true;
}

void LSMessageRef(LSMessage *) {}
void LSMessageUnref(LSMessage *) {}
const char *LSMessageGetPayload(LSMessage *) { return "{}"; }
const char *LSMessageGetApplicationID(LSMessage *) { return ""; }
const char *LSMessageGetSenderServiceName(LSMessage *) { return ""; }
const char *LSMessageGetCategory(LSMessage *) { return "/"; }
bool LSMessageReply(LSHandle *, LSMessage *, const char *, LSError *) { return true; }
bool LSRegisterCategoryAppend(LSHandle *, const char *, LSMethod *, LSSignal *, LSError *) { return true; }
bool LSMethodSetData(LSHandle *, const char *, const char *, void *, LSError *) { return true; }
bool LSSubscriptionAdd(LSHandle *, const char *, LSMessage *, LSError *) { return true; }
bool LSSubscriptionReply(LSHandle *, const char *, const char *, LSError *) { return true; }

bool webos_application_get_handle(char **app_id, struct LSHandle **service_handle)
{
    *app_id = nullptr;
    *service_handle = nullptr;
    return false;
}

}
