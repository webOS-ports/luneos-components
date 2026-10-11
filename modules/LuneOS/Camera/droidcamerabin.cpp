/*
 * Copyright (C) 2026 Herman van Hazendonk <github.com@herrie.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "droidcamerabin.h"

namespace {

struct LuneosDroidBin {
    GstBin parent;
    std::function<void(GstMessage *)> *observer;
    GstElement *contents; // a child, owned through the bin
};

struct LuneosDroidBinClass {
    GstBinClass parent_class;
};

GType luneos_droid_bin_get_type();

#define LUNEOS_DROID_BIN(obj) \
    (G_TYPE_CHECK_INSTANCE_CAST((obj), luneos_droid_bin_get_type(), LuneosDroidBin))

G_DEFINE_TYPE(LuneosDroidBin, luneos_droid_bin, GST_TYPE_BIN)

void luneos_droid_bin_handle_message(GstBin *bin, GstMessage *message)
{
    LuneosDroidBin *self = LUNEOS_DROID_BIN(bin);
    if (self->observer && GST_MESSAGE_TYPE(message) == GST_MESSAGE_ELEMENT)
        (*self->observer)(message);

    GST_BIN_CLASS(luneos_droid_bin_parent_class)->handle_message(bin, message);
}

void luneos_droid_bin_finalize(GObject *object)
{
    LuneosDroidBin *self = LUNEOS_DROID_BIN(object);
    delete self->observer;
    self->observer = nullptr;

    G_OBJECT_CLASS(luneos_droid_bin_parent_class)->finalize(object);
}

void luneos_droid_bin_class_init(LuneosDroidBinClass *klass)
{
    G_OBJECT_CLASS(klass)->finalize = luneos_droid_bin_finalize;
    GST_BIN_CLASS(klass)->handle_message = luneos_droid_bin_handle_message;
}

void luneos_droid_bin_init(LuneosDroidBin *self)
{
    self->observer = nullptr;
    self->contents = nullptr;
}

} // namespace

GstElement *droid_camera_bin_new(const char *name, GstElement *contents,
                                 std::function<void(GstMessage *)> observer)
{
    GstPad *src = gst_element_get_static_pad(contents, "src");
    if (!src) {
        gst_object_unref(gst_object_ref_sink(contents));
        return nullptr;
    }

    auto *self = static_cast<LuneosDroidBin *>(
        g_object_new(luneos_droid_bin_get_type(), "name", name, nullptr));
    self->observer = new std::function<void(GstMessage *)>(std::move(observer));
    gst_bin_add(GST_BIN(self), contents);
    self->contents = contents;
    gst_element_add_pad(GST_ELEMENT(self), gst_ghost_pad_new("src", src));
    gst_object_unref(src);
    return GST_ELEMENT(self);
}

GstElement *droid_camera_bin_contents(GstElement *bin)
{
    if (!bin || !G_TYPE_CHECK_INSTANCE_TYPE(bin, luneos_droid_bin_get_type()))
        return nullptr;
    return LUNEOS_DROID_BIN(bin)->contents;
}
