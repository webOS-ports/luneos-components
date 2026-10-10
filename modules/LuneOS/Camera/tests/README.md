# LuneOS.Camera tests

## Unit tests (`unit/`)

gtest, for the parts that need no camera:

- `test_cameracontrols.cpp`: the GstPhotography mode names (the Android
  values gst-droid sends), parsing `zoom-ratios` and picking a zoom index,
  the tap-to-focus region, and `viewToFrame()`. The last is checked against
  a forward transform built independently with `QTransform`, for every turn,
  mirroring, zoom and window shape.
- `test_barcodedecoder.cpp`: luminance extraction from planar, packed and
  padded frames, including the bounds it refuses, and zbar decoding. The
  barcodes are EAN-13s drawn from the GS1 definition in the test itself, so
  no binary fixtures are needed.
- `test_barcodescanner.cpp`: the scanner around it, with real `QVideoFrame`s
  through a `QVideoSink`, its worker thread, de-duplication, and deletion
  while a decode is still running.
- `test_droidcamerabin.cpp`: the bin the camera is wrapped in, built from
  GStreamer's core elements in the camera bin's shape: its source pad, the
  observer seeing element messages, and that a recorder linked to the
  viewfinder tee must go in the inner bin (`droid_camera_bin_contents()`).

`tests.pro` builds `luneos-camera-tests`; it is not part of the module's
build. It needs googletest in the sysroot. On the build host, run the x86-64
build with its recipe sysroot:

    QT_PLUGIN_PATH=<sysroot>/usr/lib/plugins \
    <sysroot>/usr/lib/ld-linux-x86-64.so.2 \
        --library-path <sysroot>/usr/lib:<sysroot>/usr/lib/pulseaudio \
        ./luneos-camera-tests

## Sanitizers and valgrind

`qmake CONFIG+=sanitize` adds ASan and UBSan. The image toolchain ships no
sanitizer runtimes, so build with the host compiler instead, against either
the sysroot (linking the runtime statically) or the host's own Qt.

ThreadSanitizer needs a host-native build: against the sysroot's libraries
its runtime loses track of thread exits and aborts in
`sanitizer_thread_registry.cpp`. Run it with the suppressions in `tsan.supp`:

    TSAN_OPTIONS=suppressions=tests/tsan.supp ./luneos-camera-tests

The Qt libraries are not instrumented, so the hand-over of a result from the
scanner's worker to the GUI thread (a queued call, synchronised inside Qt) is
invisible to TSan. `tsan.supp` suppresses exactly those reports and says why
for each one. A race in this module's own code is still reported.

valgrind memcheck runs the same binary:

    valgrind --leak-check=full --errors-for-leak-kinds=definite \
        --error-exitcode=9 ./luneos-camera-tests

## Static analysis

`static-analysis.sh` runs gcc `-fanalyzer` (-O0 and -O2), the clang analyzer
with the alpha checkers, clang-tidy, cppcheck and flawfinder over the
module's sources, and fails on any finding in them:

    CAMERA_SYSROOT=<.../recipe-sysroot> CAMERA_MOC_DIR=<build dir> \
        tests/static-analysis.sh

`CAMERA_MOC_DIR` is a build directory of the module, for `plugin.moc`.
