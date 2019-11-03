#!/bin/sh

CONFIGURE_FLAGS="--enable-static --with-pic=yes --disable-shared --disable-gpl"

#ARCHS="arm64 x86_64 i386 armv7"
ARCHS="armv7 armv7s arm64"

# directories
SOURCE="fdk-aac-2.0.1"
FAT="fdk-aac-iOS"

SCRATCH="ffmpeg_external/build/fdk_build_scratch"
# must be an absolute path
THIN=`pwd`/"ffmpeg_external/build/fdk_build"

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

		if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
		then
		    PLATFORM="iPhoneSimulator"
		    CPU=
		    if [ "$ARCH" = "x86_64" ]
		    then
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=9.0"
			HOST="--host=x86_64-apple-darwin"
		    else
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=9.0"
			HOST="--host=i386-apple-darwin"
		    fi
		else
		    PLATFORM="iPhoneOS"
            if [ $ARCH = arm64 ]
            then
                HOST="--host=aarch64-apple-darwin"
                    else
                HOST="--host=arm-apple-darwin"
                fi
		    CFLAGS="$CFLAGS -fembed-bitcode"
		fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang -Werror=unused-command-line-argument"
		AS="$CWD/gas-preprocessor/gas-preprocessor.pl $CC"
		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
        echo "$CPU"
        echo "$HOST"
        echo "$CC"
        
        
		$CWD/ffmpeg_external/build_source/$SOURCE/configure \
		    $CONFIGURE_FLAGS \
		    $HOST \
		    $CPU \
		    CC="$CC" \
		    CXX="$CC" \
		    CPP="$CC -E" \
                    AS="$AS" \
		    CFLAGS="$CFLAGS" \
		    LDFLAGS="$LDFLAGS" \
		    CPPFLAGS="$CFLAGS" \
		    --prefix="$THIN/$ARCH"
        
        make clean
		make -j4 install
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
