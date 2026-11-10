# C++ unit tests and hardening for LuneOS.Service

The QML tests one level up run against the stand-ins in `test/imports`; these
run the plugin's real C++.

## Unit tests

`tst_lunaservice_deferred.cpp` is a gtest suite for `LunaServiceAdapter`, the
C++ behind `LunaService`. It runs the real adapter, inside a QML engine where
the case needs one, against `fake_ls2.cpp`: a stand-in for luna-service2 and
webos-application that records what the adapter asks of the bus. No hub is
needed. It pins how calls made before the service is registered behave: held,
sent once it is, in the order made, cancellable while held, and given their
error if it cannot register.

Only luna-service2's, pbnjson's and webos-application's headers, and gtest,
come from the recipe sysroot of the x86-64 build:

    export X86_WORKDIR=<build>/tmp/work/corei7-64-webos-linux/luneos-components/<version>
    ./run-tests.sh                # host g++ against the host's Qt 6
    CXX=clang++ ./run-tests.sh    # the same with Clang
    ./run-tests.sh sysroot        # Yocto g++ against the device's Qt, run
                                  # through the sysroot's loader

gtest arguments pass through, e.g. `./run-tests.sh host --gtest_filter=*Cancel*`.

The suite is mutation-checked: making the adapter send calls before it has
registered, ignore a cancel of a held call, send held calls in reverse,
emit `initialized` before them, or drop the null check on a call cancelled
meanwhile, each fails at least one test (the last one crashes).

## Hardening

    ./run-tests.sh asan           # AddressSanitizer + UndefinedBehaviorSanitizer
    ./run-tests.sh tsan           # ThreadSanitizer, one test per process
    ./run-tests.sh valgrind       # memcheck, fails on errors and definite leaks
    ./check-warnings.sh           # GCC and Clang, x86-64/aarch64/armv7
    ./static-analysis.sh          # -fanalyzer, clang --analyze, clang-tidy,
                                  # cppcheck, flawfinder

`check-warnings.sh` also needs `AARCH64_WORKDIR` and `ARMV7_WORKDIR`, the
same recipe's workdirs for those machines. Under TSan the host's Qt is not
instrumented, so it reports races inside Qt's own QML type loader thread; the
exit status is the tests', and a report naming `lunaserviceadapter.cpp` is the
one to look at. `static-analysis.sh` lists the known noise in its header.

Everything builds into `build/`, which git ignores.
