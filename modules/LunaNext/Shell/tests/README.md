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

`tests.pro` builds `lunanext-shell-tests`; it is not part of the module's
build. It needs googletest. On the build host, run the x86-64 build with its
recipe sysroot:

    QT_QPA_PLATFORM=offscreen QT_PLUGIN_PATH=<sysroot>/usr/lib/plugins \
    <sysroot>/usr/lib/ld-linux-x86-64.so.2 --library-path <sysroot>/usr/lib \
        ./lunanext-shell-tests

## Sanitizers and valgrind

`qmake CONFIG+=sanitize` adds ASan and UBSan. The test has no threads of its
own, so ThreadSanitizer has nothing to check.

    valgrind --leak-check=full --errors-for-leak-kinds=definite ./lunanext-shell-tests

## Static analysis

`static-analysis.sh` runs gcc `-fanalyzer`, the clang analyzer, clang-tidy,
cppcheck and flawfinder over `screenshooter.cpp`:

    APP_SYSROOT=<.../recipe-sysroot> tests/static-analysis.sh
