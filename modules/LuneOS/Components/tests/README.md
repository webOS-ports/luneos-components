# LuneOS.Components tests

## Unit tests (`unit/`)

gtest, for the module's C++:

- `test_artworkcache.cpp`: the artwork cache behind `image://artwork` and
  `ArtworkImage`: an SVG drawn at the size asked for and kept as PNG, the kept
  picture read back next time, one side given and the other from the
  picture's proportions, only absolute `.svg` files taken, a changed picture
  replacing only its own old files (`flash-off` leaves `flash-off-pressed`),
  each app's artwork in a folder of its own, names made plain for the cache,
  the path read out of an `image://artwork` id, drawing where nothing can be
  kept, and many requests for one picture at once.

`tests.pro` builds `luneos-components-tests`; it is not part of the module's
build. It needs googletest. On the build host, run the x86-64 build with its
recipe sysroot:

    QT_PLUGIN_PATH=<sysroot>/usr/lib/plugins \
    <sysroot>/usr/lib/ld-linux-x86-64.so.2 --library-path <sysroot>/usr/lib \
        ./luneos-components-tests

## Sanitizers and valgrind

`qmake CONFIG+=sanitize` adds ASan and UBSan; the image toolchain ships no
sanitizer runtimes, so build those with the host compiler against the host's
own Qt. ThreadSanitizer likewise, natively:

    ./luneos-components-tests --gtest_filter='*ManyAtOnce*'
    valgrind --leak-check=full --errors-for-leak-kinds=definite ./luneos-components-tests

## Static analysis

`static-analysis.sh` runs gcc `-fanalyzer`, the clang analyzer, clang-tidy,
cppcheck and flawfinder over `plugin/artworkcache.cpp`:

    APP_SYSROOT=<.../recipe-sysroot> tests/static-analysis.sh
