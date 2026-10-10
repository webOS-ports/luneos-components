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

#include <gtest/gtest.h>

#include <gst/gst.h>

#include <string>
#include <vector>

#include "droidcamerabin.h"

/* droidcamerabin.cpp with GStreamer's core elements standing in for
 * droidcamsrc: the same shape as the camera bin DroidCameraFactory builds, a
 * source feeding a tee named "vftee" whose one unlinked pad is the bin's. */

namespace {

GstElement *cameraLikeContents()
{
    GError *error = nullptr;
    GstElement *contents = gst_parse_bin_from_description(
        "fakesrc name=droidcam ! tee name=vftee ! queue", TRUE, &error);
    g_clear_error(&error);
    return contents;
}

GstElement *recorder()
{
    GError *error = nullptr;
    GstElement *rec = gst_parse_bin_from_description("queue ! fakesink", TRUE, &error);
    g_clear_error(&error);
    return rec;
}

/* Adds a recorder to `into` and links it to a new pad of the tee, the way
 * DroidCameraFactory::startSwRecording() does. */
GstPadLinkReturn linkRecorder(GstElement *outer, GstElement *into)
{
    GstElement *tee = gst_bin_get_by_name(GST_BIN(outer), "vftee");
    GstElement *rec = recorder();
    if (!tee || !rec)
        return GST_PAD_LINK_REFUSED;
    gst_bin_add(GST_BIN(into), rec);
    GstPad *teepad = gst_element_request_pad_simple(tee, "src_%u");
    GstPad *sinkpad = gst_element_get_static_pad(rec, "sink");
    const GstPadLinkReturn ret = gst_pad_link(teepad, sinkpad);
    gst_object_unref(sinkpad);
    gst_object_unref(teepad);
    gst_object_unref(tee);
    return ret;
}

} // namespace

TEST(DroidCameraBin, OffersTheContentsSourcePadAsItsOwn)
{
    GstElement *outer = droid_camera_bin_new("cam", cameraLikeContents(), [](GstMessage *) {});
    ASSERT_NE(outer, nullptr);
    gst_object_ref_sink(outer);

    GstPad *src = gst_element_get_static_pad(outer, "src");
    ASSERT_NE(src, nullptr);
    EXPECT_TRUE(GST_IS_GHOST_PAD(src));
    EXPECT_EQ(gst_pad_get_direction(src), GST_PAD_SRC);
    gst_object_unref(src);
    gst_object_unref(outer);
}

TEST(DroidCameraBin, ContentsIsTheBinHoldingTheCamera)
{
    GstElement *contents = cameraLikeContents();
    GstElement *outer = droid_camera_bin_new("cam", contents, [](GstMessage *) {});
    ASSERT_NE(outer, nullptr);
    gst_object_ref_sink(outer);

    EXPECT_EQ(droid_camera_bin_contents(outer), contents);
    GstElement *cam = gst_bin_get_by_name(GST_BIN(outer), "droidcam");
    ASSERT_NE(cam, nullptr);
    EXPECT_EQ(GST_ELEMENT(GST_OBJECT_PARENT(cam)), droid_camera_bin_contents(outer));
    gst_object_unref(cam);
    gst_object_unref(outer);
}

/* What recording needs: a recorder placed in the contents links to the tee. */
TEST(DroidCameraBin, RecorderInTheContentsLinksToTheTee)
{
    GstElement *outer = droid_camera_bin_new("cam", cameraLikeContents(), [](GstMessage *) {});
    ASSERT_NE(outer, nullptr);
    gst_object_ref_sink(outer);

    EXPECT_EQ(linkRecorder(outer, droid_camera_bin_contents(outer)), GST_PAD_LINK_OK);
    gst_object_unref(outer);
}

/* Why the contents are needed at all: next to them, in the outer bin, the
 * link is refused ("cannot link recorder", seen on a device). */
TEST(DroidCameraBin, RecorderInTheOuterBinCannotLinkToTheTee)
{
    GstElement *outer = droid_camera_bin_new("cam", cameraLikeContents(), [](GstMessage *) {});
    ASSERT_NE(outer, nullptr);
    gst_object_ref_sink(outer);

    EXPECT_EQ(linkRecorder(outer, outer), GST_PAD_LINK_WRONG_HIERARCHY);
    gst_object_unref(outer);
}

TEST(DroidCameraBin, ContentsWithoutSourcePadIsRefused)
{
    GError *error = nullptr;
    GstElement *closed = gst_parse_bin_from_description("fakesrc ! fakesink", TRUE, &error);
    g_clear_error(&error);
    ASSERT_NE(closed, nullptr);

    EXPECT_EQ(droid_camera_bin_new("cam", closed, [](GstMessage *) {}), nullptr);
}

TEST(DroidCameraBin, ContentsOfOtherElementsIsNull)
{
    EXPECT_EQ(droid_camera_bin_contents(nullptr), nullptr);
    GstElement *plain = gst_bin_new("plain");
    gst_object_ref_sink(plain);
    EXPECT_EQ(droid_camera_bin_contents(plain), nullptr);
    gst_object_unref(plain);
}

TEST(DroidCameraBin, ObserverSeesElementMessagesOfTheCamera)
{
    std::vector<std::string> seen;
    GstElement *outer = droid_camera_bin_new("cam", cameraLikeContents(), [&seen](GstMessage *m) {
        seen.emplace_back(gst_structure_get_name(gst_message_get_structure(m)));
    });
    ASSERT_NE(outer, nullptr);
    gst_object_ref_sink(outer);

    GstElement *cam = gst_bin_get_by_name(GST_BIN(outer), "droidcam");
    ASSERT_NE(cam, nullptr);
    gst_element_post_message(cam, gst_message_new_element(
        GST_OBJECT(cam), gst_structure_new_empty("autofocus-done")));
    gst_element_post_message(cam, gst_message_new_info(GST_OBJECT(cam), nullptr, "not shown"));

    ASSERT_EQ(seen.size(), 1u);
    EXPECT_EQ(seen.front(), "autofocus-done");
    gst_object_unref(cam);
    gst_object_unref(outer);
}
