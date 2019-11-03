#!/bin/sh



#export AS="../gas-preprocessor/gas-preprocessor.pl -arch arm -- xcrun -sdk iphoneos clang"
#export CC="xcrun -sdk iphoneos clang"
#cd ./x264-stable
#
#./configure \
#    --enable-static \
#    --enable-pic    \
#    --disable-shared\
#    --host=arm -apple-darwin\
#    --extra-cflags="-arch armv7s -mios-version-min=9.0" \
#    --extra-asflags="-arch armv7s -mios-version-min=9.0" \
#    --extra-ldflags="-arch armv7s -mios-version-min=9.0" \
#    --prefix="../thinx264/armv7s"
#
#make -j8
#make install

CONFIGURE_FLAGS="--enable-static --enable-pic --disable-cli"

ARCHS="arm64 armv7s armv7"

# directories
SOURCE="x264-stable"
FAT="x264-iOS"

SCRATCH="ffmpeg_external/build/x264_build_srcatch"
# must be an absolute path
THIN=`pwd`/"ffmpeg_external/build/x264_build"

COMPILE="y"
LIPO="y"

if [ "$*" ]
then
    if [ "$*" = "lipo" ]
    then
        # skip compile
        COMPILE=
    else
        ARCHS="$*"
        if [ $# -eq 1 ]
        then
            # skip lipo
            LIPO=
        fi
    fi
fi

if [ "$COMPILE" ]
then
    CWD=`pwd`
    for ARCH in $ARCHS
    do
        echo "building $ARCH..."
        mkdir -p "$SCRATCH/$ARCH"
        cd "$SCRATCH/$ARCH"
        CFLAGS="-arch $ARCH"
                ASFLAGS=

        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iPhoneSimulator"
            CPU=
            if [ "$ARCH" = "x86_64" ]
            then
                CFLAGS="$CFLAGS -mios-simulator-version-min=9.3"
                HOST=
            else
                CFLAGS="$CFLAGS -mios-simulator-version-min=9.3"
            HOST="--host=i386-apple-darwin"
            fi
        else
            PLATFORM="iPhoneOS"
            if [ $ARCH = "arm64" ]
            then
                HOST="--host=aarch64-apple-darwin"
            XARCH="-arch aarch64"
            else
                HOST="--host=arm-apple-darwin"
            XARCH="-arch arm"
            fi
            CFLAGS="$CFLAGS -fembed-bitcode -mios-version-min=9.3"
            ASFLAGS="$CFLAGS"
        fi

        XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
        CC="xcrun -sdk $XCRUN_SDK clang"
        if [ $PLATFORM = "iPhoneOS" ]
        then
            export AS="$CWD/ffmpeg_external/build_source/$SOURCE/tools/gas-preprocessor.pl $XARCH -- $CC"
        else
            export -n AS
        fi
        CXXFLAGS="$CFLAGS"
        LDFLAGS="$CFLAGS"

        CC=$CC $CWD/ffmpeg_external/build_source/$SOURCE/configure \
            $CONFIGURE_FLAGS \
            $HOST \
            --extra-cflags="$CFLAGS" \
            --extra-asflags="$ASFLAGS" \
            --extra-ldflags="$LDFLAGS" \
            --prefix="$THIN/$ARCH" || exit 1
        make clean
        make -j4 install || exit 1
        cd $CWD
    done
fi

if [ "$LIPO" ]
then
    echo "building fat binaries..."
    mkdir -p $FAT/lib
    set - $ARCHS
    CWD=`pwd`
    cd $THIN/$1/lib
    for LIB in *.a
    do
        cd $CWD
        lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB
    done

    cd $CWD
    cp -rf $THIN/$1/include $FAT
fi
