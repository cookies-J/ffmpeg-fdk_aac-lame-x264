#!/bin/sh
BUILDED_PATH="enjoy_it!!"

# directories
FF_VERSION="4.4"
#FF_VERSION="snapshot-git"
if [[ $FFMPEG_VERSION != "" ]]; then
  FF_VERSION=$FFMPEG_VERSION
fi
SOURCE="ffmpeg-$FF_VERSION"
FAT="FFmpeg-iOS"

SCRATCH="scratch"
# must be an absolute path
THIN=`pwd`/"thin"

# absolute path to x264 library
X264=`pwd`/$BUILDED_PATH/x264-iOS

FDK_AAC=`pwd`/$BUILDED_PATH/fdk-aac-iOS

LAME=`pwd`/$BUILDED_PATH/lame-iOS

#X265=`pwd`/$BUILDED_PATH/x265-iOS

#X264=`pwd`/x264
#
#FDK_AAC=`pwd`/fdk-aac
#
#LAME=`pwd`/lame
#
CONFIGURE_FLAGS="--disable-everything \
--enable-cross-compile
--enable-pic \
--enable-static --disable-stripping \
--disable-ffmpeg --disable-ffplay --disable-ffprobe --disable-programs \
--enable-indevs \
--enable-outdevs \
--enable-debug \
--enable-small \
--enable-dct \
--enable-dwt \
--enable-lsp \
--enable-mdct \
--enable-rdft \
--enable-fft \
--enable-version3  \
--enable-nonfree   \
--disable-filters  \
--enable-filter=aresample \
--disable-postproc \
--disable-bsfs \
--enable-bsf=aac_adtstoasc,h264_mp4toannexb,x265 \
--disable-encoders \
--enable-encoder=pcm_s16le,h264,aac,libmp3lame,hls,x265 \
--disable-decoders \
--enable-decoder=h264,aac,mp3,hls,x265 \
--disable-parsers  \
--enable-parser=h264,aac,mp3,x265 \
--disable-muxers   \
--enable-muxer=flv,mov,mpegts,hls,x265 \
--disable-demuxers \
--enable-demuxer=flv,mov,mpegts,h264,aac,mp3,live_flv,hls,x265 \
--disable-protocols    \
--enable-protocol=file,rtmp,pipe,hls,http,https \
--enable-hwaccels \
--disable-audiotoolbox \
--enable-autodetect
--disable-manpages \
--disable-htmlpages \
--disable-podpages \
--disable-txtpages \
--enable-asm --enable-yasm \
--enable-x86asm \
"


#CONFIGURE_FLAGS="--enable-cross-compile \
#--enable-debug \
#--disable-programs \
#--disable-doc \
#--enable-pic \
#--disable-ffmpeg --disable-ffplay --disable-ffprobe \
#--enable-small \
#--enable-hwaccels \
#--disable-audiotoolbox"

#CONFIGURE_FLAGS="--enable-cross-compile \
#                 --disable-debug \
#                 --disable-programs \
#                 --disable-shared \
#                 --disable-asm \
#                 --disable-x86asm \
#                 --enable-small \
#                 --enable-dct \
#                 --enable-dwt \
#                 --enable-lsp \
#                 --enable-mdct \
#                 --enable-rdft \
#                 --enable-fft \
#                 --enabl`e-static \
#                 --enable-version3  \
#                 --disable-postproc \
#                 --disable-d3d11va  \
#                 --disable-dxva2    \
#                 --disable-vaapi    \
#                 --disable-vdpau    \
#                 --disable-videotoolbox \
#                 --disable-securetransport"

#                 --enable-protocol=rtmp \
#                 --enable-protocol=file \
#                 --enable-libfdk_aac    \
#                 --enable-libx264  \
#                 --enable-libmp3lame"

#--disable-demuxers \
#--enable-demuxer=flv   \
#--enable-demuxer=wav   \
#--enable-demuxer=aac   \
#--enable-demuxer=mov\

#--disable-muxers   \
#--enable-muxer=flv \
#--enable-muxer=wav \
#--enable-muxer=adts    \

#--disable-decoders \
#--disable-decoder=h264_vda \
#--enable-decoder=aac   \
#--enable-decoder=mp3   \
#--enable-decoder=pcm_s16le \

#--disable-parsers  \
#--enable-parser=aac   \

#--disable-encoders \
#--enable-encoder=pcm_s16le \
#--enable-encoder=aac   \
#--enable-encoder=libvo_aacenc  \
#--enable-encoder=libfdk_aac    \
#--enable-encoder=libx264   \

#--disable-bsfs \
#--enable-bsf=aac_adtstoasc \
#--enable-bsf=h264_mp4toannexb  \

#--disable-filters  \
#--enable-filter=aresample \

if [ "$X264" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx264 --enable-encoder=libx264 --enable-decoder=libx264"
fi

if [ "$X265" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-gpl --enable-libx265 --enable-encoder=libx265 --enable-decoder=libx265"
fi

if [ "$FDK_AAC" ]
then
	CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libfdk-aac --enable-nonfree --enable-encoder=libfdk_aac --enable-decoder=libfdk_aac"
fi

if [ "$LAME" ]
then
    CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-libmp3lame --enable-encoder=libmp3lame"
fi

# avresample
#CONFIGURE_FLAGS="$CONFIGURE_FLAGS --enable-avresample"

ARCHS="arm64 armv7s armv7 x86_64"

COMPILE="y"
LIPO="y"

DEPLOYMENT_TARGET="9.2"

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



function Compile_exec() {
	if [ ! `which yasm` ]
	then
		echo 'Yasm not found'
		if [ ! `which brew` ]
		then
			echo 'Homebrew not found. Trying to install...'
                        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
				|| exit 1
		fi
		echo 'Trying to install Yasm...'
		brew install yasm || exit 1
	fi
	if [ ! `which gas-preprocessor.pl` ]
	then
		echo 'gas-preprocessor.pl not found. Trying to install...'
		(curl -L https://github.com/libav/gas-preprocessor/raw/master/gas-preprocessor.pl \
			-o /usr/local/bin/gas-preprocessor.pl \
			&& chmod +x /usr/local/bin/gas-preprocessor.pl) \
			|| exit 1
	fi

	if [ ! -r $SOURCE ]
	then
		echo 'FFmpeg source not found. Trying to download...'
		curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj \
			|| exit 1
	fi

	CWD=`pwd`
	for ARCH in $ARCHS
	do {
		echo "building arch => $ARCH..."
		mkdir -p "$SCRATCH/$ARCH"
		cd "$SCRATCH/$ARCH"

		CFLAGS="-arch $ARCH"
        if [ "$ARCH" = "i386" -o "$ARCH" = "x86_64" ]
        then
            PLATFORM="iPhoneSimulator"
            CPU=
            if [ "$ARCH" = "x86_64" ]
            then
                CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
            HOST="--host=x86_64-apple-darwin"
            else
                CFLAGS="$CFLAGS -mios-simulator-version-min=$DEPLOYMENT_TARGET"
            HOST="--host=i386-apple-darwin"
            fi
        else
            PLATFORM="iPhoneOS"
            CFLAGS="$CFLAGS -mios-version-min=$DEPLOYMENT_TARGET -fembed-bitcode"
            if [ "$ARCH" = "arm64" ]
            then
                HOST="--host=aarch64-apple-darwin"
            else
                HOST="--host=arm-apple-darwin"
            fi
        fi

		XCRUN_SDK=`echo $PLATFORM | tr '[:upper:]' '[:lower:]'`
		CC="xcrun -sdk $XCRUN_SDK clang"

		# force "configure" to use "gas-preprocessor.pl" (FFmpeg 3.3)
		if [ "$ARCH" = "arm64" ]
		then
		    AS="gas-preprocessor.pl -arch aarch64 -- $CC"
		else
		    AS="gas-preprocessor.pl -- $CC"
		fi

		CXXFLAGS="$CFLAGS"
		LDFLAGS="$CFLAGS"
		if [ "$X264" ]
		then
			CFLAGS="$CFLAGS -I$X264/include"
			LDFLAGS="$LDFLAGS -L$X264/lib"
		fi
		if [ "$FDK_AAC" ]
		then
			CFLAGS="$CFLAGS -I$FDK_AAC/include"
			LDFLAGS="$LDFLAGS -L$FDK_AAC/lib"
		fi
        if [ "$LAME" ]
        then
            CFLAGS="$CFLAGS -I$LAME/include"
            LDFLAGS="$LDFLAGS -L$LAME/lib"
        fi
        
        echo $X264
        echo $FDK_AAC
        echo $LAME
        echo $CONFIGURE_FLAGS
        
		TMPDIR=${TMPDIR/%\/} $CWD/$SOURCE/configure \
		    --target-os=darwin \
		    --arch=$ARCH \
		    --cc="$CC" \
		    --as="$AS" \
		    $CONFIGURE_FLAGS \
		    --extra-cflags="$CFLAGS" \
		    --extra-ldflags="$LDFLAGS" \
		    --prefix="$THIN/$ARCH" \
		|| exit 1

		make -j4 install $EXPORT || exit 1
		cd $CWD
    } &
    done
    wait
}

function Lipo_exec() {
	echo "building fat binaries... =>"
     if [ -r $FAT ]
    then
        rm -rf $FAT
    fi
    
    mkdir -p $FAT/lib
    set - $ARCHS
	CWD=`pwd`
	cd $THIN/$1/lib
	for LIB in *.a
	do
		cd $CWD
		echo lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB 1>&2
		lipo -create `find $THIN -name $LIB` -output $FAT/lib/$LIB || exit 1
	done

	cd $CWD
	cp -rf $THIN/$1/include $FAT
 echo 'Bye~~~~~'
}

Compile_exec
Lipo_exec

