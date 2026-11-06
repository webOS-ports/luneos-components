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
  sensing area, senses the whole window.
- `test_notifications.cpp`: the notifications' C++ (`notifications/`). A
  default `Notification` has defined duration, priority and doNotSuppress;
  `QObjectListModel::setData` stores the object it is given (not a number as a
  pointer), watches it in place of the one it replaces, and an out-of-range
  `removeItem` does nothing; `CategoryDefinitionStore` reports a removed
  definition and keeps the others; destroying the `NotificationManager` with
  notifications open uses no freed database.

`tests.pro` builds `lunanext-shell-tests`; it is not part of the module's
build. It needs googletest. On the build host, run the x86-64 build with its
recipe sysroot:

    QT_QPA_PLATFORM=offscreen QT_PLUGIN_PATH=<sysroot>/usr/lib/plugins \
    <sysroot>/usr/lib/ld-linux-x86-64.so.2 --library-path <sysroot>/usr/lib \
        ./lunanext-shell-tests

## Sanitizers and valgrind

`qmake CONFIG+=sanitize` adds ASan and UBSan. The tests have no threads of
their own, so ThreadSanitizer has nothing to check.

    valgrind --leak-check=full --errors-for-leak-kinds=definite ./lunanext-shell-tests

## Static analysis

`static-analysis.sh` runs gcc `-fanalyzer`, the clang analyzer, clang-tidy,
cppcheck and flawfinder over `screenshooter.cpp`:

    APP_SYSROOT=<.../recipe-sysroot> tests/static-analysis.sh
