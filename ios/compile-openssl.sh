#! /usr/bin/env zsh
#
# Copyright (C) 2013-2014 Bilibili
# Copyright (C) 2013-2014 Zhang Rui <bbcallen@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#----------
# modify for your build tool

declare -A FF_ALL_ARCHS

FF_ALL_ARCHS=([iphoneos]="arm64" [iphonesimulator]="arm64 x86_64")

----------
UNI_BUILD_ROOT=`pwd`
UNI_TMP="$UNI_BUILD_ROOT/tmp"
UNI_TMP_LLVM_VER_FILE="$UNI_TMP/llvm.ver.txt"
FF_TARGET=$1
set -e

#----------
FF_LIBS="libssl libcrypto"

#----------
echo_archs() {
    echo "===================="
    echo "[*] check xcode version"
    echo "===================="
    echo "FF_ALL_ARCHS = $FF_ALL_ARCHS"
}

do_lipo () {
    LIB_FILE=$1

    declare -A LIPO_FLAGS

    for PLATFORM in ${(k)FF_ALL_ARCHS}
    do
        for ARCH in $=FF_ALL_ARCHS[$PLATFORM]
        do
            LIPO_FLAGS[$PLATFORM]="${LIPO_FLAGS[$PLATFORM]} $UNI_BUILD_ROOT/build/openssl-$ARCH-$PLATFORM/output/lib/$LIB_FILE"
        done
        xcrun lipo -create $=LIPO_FLAGS[$PLATFORM] -output $UNI_BUILD_ROOT/build/openssl-$PLATFORM/lib/$LIB_FILE
        xcrun lipo -info $UNI_BUILD_ROOT/build/openssl-$PLATFORM/lib/$LIB_FILE
    done


}

do_lipo_all () {

    for PLATFORM in ${(k)FF_ALL_ARCHS}
    do
        mkdir -p $UNI_BUILD_ROOT/build/openssl-$PLATFORM/lib
        ARCH=$FF_ALL_ARCHS[$PLATFORM]
        cp -R $UNI_BUILD_ROOT/build/openssl-${${(A)=ARCH}[1]}-$PLATFORM/output/include $UNI_BUILD_ROOT/build/openssl-$PLATFORM/
    done


    echo "lipo archs: $FF_ALL_ARCHS"
    for FF_LIB in $=FF_LIBS
    do
        do_lipo "$FF_LIB.a";
    done

    FRAMEWORKS_FLAGS=

    for PLATFORM in ${(k)FF_ALL_ARCHS}
    do

        LIB_FILES=
        for FF_LIB in $=FF_LIBS
        do
            LIB_FILES="$LIB_FILES $UNI_BUILD_ROOT/build/openssl-$PLATFORM/lib/$FF_LIB.a"
        done

        xcrun -sdk $PLATFORM libtool -static $=LIB_FILES -o $UNI_BUILD_ROOT/build/openssl-$PLATFORM/lib/openssl.a
        FRAMEWORKS_FLAGS="$FRAMEWORKS_FLAGS -library $UNI_BUILD_ROOT/build/openssl-$PLATFORM/lib/openssl.a -headers $UNI_BUILD_ROOT/build/openssl-$PLATFORM/include"
    done
    rm -rf $UNI_BUILD_ROOT/build/openssl.xcframework
    xcodebuild -create-xcframework $=FRAMEWORKS_FLAGS -output $UNI_BUILD_ROOT/build/openssl.xcframework

}

#----------
if [ "$FF_TARGET" = "arm64 iPhoneOS" -o "$FF_TARGET" = "arm64 iPhoneSimulator" -o "$FF_TARGET" = "x86_64 iPhoneSimulator" ]; then
    echo_archs
    sh tools/do-compile-openssl.sh $FF_TARGET
elif [ "$FF_TARGET" = "lipo" ]; then
    echo_archs
    do_lipo_all
elif [ "$FF_TARGET" = "all" ]; then
    echo_archs
    for PLATFORM in ${(k)FF_ALL_ARCHS}
    do
        for ARCH in $=FF_ALL_ARCHS[$PLATFORM]
        do
            sh tools/do-compile-openssl.sh $ARCH $PLATFORM
        done
    done

    do_lipo_all
elif [ "$FF_TARGET" = "check" ]; then
    echo_archs
elif [ "$FF_TARGET" = "clean" ]; then
    echo_archs
    for PLATFORM in ${(k)FF_ALL_ARCHS}
    do
        for ARCH in $=FF_ALL_ARCHS[$PLATFORM]
        do
            cd openssl-$ARCH-$PLATFORM && git clean -xdf && cd -
        done
    done
    rm -rf build/openssl*

else
    echo "Usage:"
    echo "  compile-openssl.sh armv7|arm64|i386|x86_64"
    echo "  compile-openssl.sh armv7s (obselete)"
    echo "  compile-openssl.sh lipo"
    echo "  compile-openssl.sh all"
    echo "  compile-openssl.sh clean"
    echo "  compile-openssl.sh check"
    exit 1
fi
