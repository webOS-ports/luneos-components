# LunaNext.Common tests

## Unit tests (`unit/`)

gtest, for the module's C++:

- `test_units.cpp`: the uiScale and sizes `Units` gives. A `LUNA_UI_SCALE`
  (or ui-scale file) of `nan` or `inf` is no scale, and a `GRID_UNIT_PX` of
  `nan` no grid unit; a scale is clamped to 0.75-1.5; below a scale of 1 a
  1dp or 2dp size stays 1 or 2 pixels, and above it is a whole multiple; a
  scale that is no number is not written.

  The ui-scale file is `/var/luna/preferences/ui-scale`, which the tests do
  not write on the build host: there the scale comes from the environment,
  and `persistUiScale` fails to open the file whatever it is given, so the
  last test only shows its check on a device.
- `test_settingsadapter.cpp`: the panel shape `SettingsAdapter` reads. Cutouts
  are `x y w h` rects; one with a field that is no number, without four
  fields or without area is dropped and the others kept. Corner radii are one
  value or four, negative ones 0, and dropped when one of them is no number.

`tests.pro` builds `lunanext-common-tests`; it is not part of the module's
build. It needs googletest. On the build host, run the x86-64 build with its
recipe sysroot:

    QT_QPA_PLATFORM=offscreen QT_PLUGIN_PATH=<sysroot>/usr/lib/plugins \
    <sysroot>/usr/lib/ld-linux-x86-64.so.2 --library-path <sysroot>/usr/lib \
        ./lunanext-common-tests

## Sanitizers and valgrind

`qmake CONFIG+=sanitize` adds ASan and UBSan. The tests have no threads of
their own, so ThreadSanitizer has nothing to check.

    valgrind --leak-check=full --errors-for-leak-kinds=definite ./lunanext-common-tests
