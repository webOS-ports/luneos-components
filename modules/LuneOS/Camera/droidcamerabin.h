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

#ifndef DROIDCAMERABIN_H
#define DROIDCAMERABIN_H

#include <functional>

#include <gst/gst.h>

/*
 * A plain GstBin that shows the element messages its children post to an
 * observer before passing them up as usual.
 *
 * droidcamsrc reports autofocus results ("autofocus-done", "focus-move") as
 * element messages on the bus, and the bus belongs to Qt's capture session
 * pipeline, which offers no way in: it owns the sync handler and the watch.
 * Messages travel up through every enclosing bin's handle_message() on their
 * way to that bus, so a bin of our own around the camera sees them first.
 *
 * The bin holds one child, `contents` (a bin with one unlinked source pad, as
 * gst_parse_bin_from_description() builds it), and offers that pad as its own
 * "src". It takes the floating reference of `contents`. Returns nullptr, and
 * drops `contents`, when it has no source pad.
 *
 * The observer runs on whichever thread posted the message (a GStreamer or
 * HAL callback thread), never the GUI thread.
 */
GstElement *droid_camera_bin_new(const char *name, GstElement *contents,
                                 std::function<void(GstMessage *)> observer);

/*
 * The bin passed to droid_camera_bin_new(), which holds droidcamsrc and the
 * viewfinder tee. Elements to be linked to those (the recorders) go in there:
 * pads can only be linked within one bin. The pointer is borrowed; it stays
 * valid as long as `bin` does. nullptr for anything that is not such a bin.
 */
GstElement *droid_camera_bin_contents(GstElement *bin);

/*
 * A recorder: gst_parse_bin_from_description(description, TRUE, error), with
 * its element "recsink" writing to `location` and, when `audioDevice` is not
 * null, its element "recaudio" reading that device.
 *
 * Both are set as properties and not written into the description: a file
 * name with a '"' in it ended the quoted location there and went on as more
 * of the pipeline. The bin is returned floating, as the parser returns it.
 * Returns nullptr (and sets `error` if the description did not parse) when
 * the bin cannot be made or lacks either element.
 */
GstElement *droid_recorder_bin_new(const char *description, const char *location,
                                   const char *audioDevice, GError **error);

#endif // DROIDCAMERABIN_H
