#!/bin/sh
BUILDED_PATH="enjoy_it!!"

CONFIGURE_FLAGS="--disable-frontend --disable-shared --disable-gpl"

# ARCHS="arm64 x86_64 i386 armv7"
ARCHS="armv7 armv7s arm64 x86_64"
# directories
SOURCE="lame-3.100"
FAT="lame-iOS"

SCRATCH="ffmpeg_external/build/lame_build_scratch"
# must be an absolute path
THIN=`pwd`/"ffmpeg_external/build/lame_build"

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
 
    if [ -r $CWD/$SCRATCH ]
    then
        rm -rf $CWD/$SCRATCH
    fi
    
    if [ -r $THIN ]
    then
        rm -rf $THIN
    fi
    
    if [ ! -r "$CWD/ffmpeg_external/build_source/$SOURCE" ]
    then
        echo 'lame source not found. Trying to download...'
        (curl https://netix.dl.sourceforge.net/project/lame/lame/3.100/lame-3.100.tar.gz -o "$CWD/ffmpeg_external/build_source/$SOURCE.tar.gz" \
        && tar xf "$CWD/ffmpeg_external/build_source/$SOURCE.tar.gz" -C "$CWD/ffmpeg_external/build_source/") \
            || exit 1
    fi
    
    
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
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
			HOST="--host=x86_64-apple-darwin"
		    else
		    	CFLAGS="$CFLAGS -mios-simulator-version-min=7.0"
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
 
    if [ -r $BUILDED_PATH/$FAT ]
    then
        rm -rf $BUILDED_PATH/$FAT
    fi
    
	mkdir -p $BUILDED_PATH/$FAT/lib
	set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		lipo -create `find $THIN -name $LIB` -output $BUILDED_PATH/$FAT/lib/$LIB
	done

	cd $CWD
	cp -rf $THIN/$1/include $BUILDED_PATH/$FAT
fi
