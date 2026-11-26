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

- `test_wifiqrcode.cpp`: the `WIFI:` text behind `WifiQrCode`: what Android
  and GNOME Settings write, fields in any order and case, backslash escapes
  and quoted values, the first of a key winning, a missing `T:`, `nopass`
  dropping a passphrase, the 32-byte SSID limit counted in bytes, enterprise
  codes and unknown types refused, passphrase lengths per security as
  wpa_supplicant counts them, `compose()` in Android's field order, and
  `parse(compose(n)) == n` for awkward names and passphrases.
- `test_qrcode.cpp`: `QrEncoder` and the `QrCode` item, every code read back
  with zbar (the decoder `LuneOS.Camera`'s `BarcodeScanner` uses): every
  error-correction level, byte mode keeping NUL and UTF-8, the smallest
  version that holds the text, the quiet zone, too much text, whole pixels
  per module and the code centred, the item's colours with no blurred edges,
  and a painted Wi-Fi code read and parsed back.

`tests.pro` builds `luneos-components-tests`; it is not part of the module's
build. It needs googletest, libqrencode and zbar. On the build host, run the x86-64 build with its
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
cppcheck and flawfinder over `plugin/artworkcache.cpp`, `qrencoder.cpp`,
`qrcodeitem.cpp` and `wifiqrcode.cpp`:

    APP_SYSROOT=<.../recipe-sysroot> tests/static-analysis.sh
