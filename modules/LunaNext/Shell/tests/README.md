# LunaNext.Shell tests

## Unit tests (`unit/`)

gtest, for the module's C++:

- `test_screenshooter.cpp`: where `ScreenShooter` writes a screenshot. Only a
  plain file name is taken (no `/`, `\`, `..`, leading `.`, control characters
  or more than `NAME_MAX` bytes), always under `/media/internal/screencaptures`;
  an empty name gets a timestamp and `-1`, `-2`, ... when that exists; an
  existing file is never overwritten, a symlink in place of the file or of the
  folder is never followed, a missing folder is created, and a name whose
  format cannot be written leaves nothing behind.
- `test_inversemousearea.cpp`: the touch events `InverseMouseArea` maps to
  mouse events. A touch that ends without the one that began on it (it began
  before the filter was set, or another finger lifts), or one on something
  that is no item, passes through as it is; the finger that began a press
  ends it. An area that is the first item of its window, and so its own
  sensing area, senses the whole window. One destroyed in its window runs no
  slot on what is left of it. A touch, a mouse press or a hover outside the
  area lands at its place in the area's own coordinates, through the item it
  was on; a finger that moves while down moves the press.
- `test_gesturehandler.cpp`: `GestureHandler`, with touches that go through
  Qt as a touch screen's would. A touch that stays within a finger is a tap
  where it is on the screen; one that moves further is none. A flick from the
  left or right edge that is long enough and not along the edge is an edge
  flick from where it began, its length measured on the screen; a short one,
  one along the edge or one in the middle is none. An edge touch held past the
  timeout is a flick that timed out. Unless set, the timeout is 2000 ms and the
  minimal flick length 100.
- `test_notifications.cpp`: the notifications' C++ (`notifications/`). A
  default `Notification` has defined duration, priority and doNotSuppress;
  `QObjectListModel::setData` stores the object it is given (not a number as a
  pointer), watches it in place of the one it replaces, and an out-of-range
  `removeItem` does nothing; `CategoryDefinitionStore` reports a removed
  definition and keeps the others; destroying the `NotificationManager` with
  notifications open uses no freed database.
- `test_fpscounter.cpp`: `FpsCounter` starts at 0, counts the frames of the
  window it is in (and of no other), counts nothing once destroyed, and takes
  frames from another thread, as the threaded render loop swaps them.
- `test_reticleitem.cpp`: `Reticle`'s `imagePath` can be set and read as a
  property, and the item takes its size from that image.

`tests.pro` builds `lunanext-shell-tests`; it is not part of the module's
build. It needs googletest. On the build host, run the x86-64 build with its
recipe sysroot:

    QT_QPA_PLATFORM=offscreen QT_PLUGIN_PATH=<sysroot>/usr/lib/plugins \
    <sysroot>/usr/lib/ld-linux-x86-64.so.2 --library-path <sysroot>/usr/lib \
        ./lunanext-shell-tests

## Sanitizers and valgrind

`qmake CONFIG+=sanitize` adds ASan and UBSan. The FpsCounter test swaps
frames from a thread of its own; build with `-fsanitize=thread` to have
ThreadSanitizer check it.

    valgrind --leak-check=full --errors-for-leak-kinds=definite ./lunanext-shell-tests

## Static analysis

`static-analysis.sh` runs gcc `-fanalyzer`, the clang analyzer, clang-tidy,
cppcheck and flawfinder over `screenshooter.cpp`:

    APP_SYSROOT=<.../recipe-sysroot> tests/static-analysis.sh
