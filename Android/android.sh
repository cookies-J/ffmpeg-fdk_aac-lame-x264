#
#API=30
#ARCH="armv7"
#
#
#NDK="/Users/jele//Library/Android/sdk/ndk/23.1.7779620"
##PLATFORM="$NDK/platforms/android-30/arch-arm/"
##PREBUILT="$NDK/toolchains/arm-linux-androideabi-4.9/prebuilt/darwin-x86_64"
##Library/Android/sdk/ndk/23.1.7779620/toolchains/llvm/prebuilt/darwin-x86_64/arm-linux-androideabi
#TOOLCHAIN="$NDK/toolchains/llvm/prebuilt/darwin-x86_64"
##OUTPUT=/home/romain/dev/android/ffmpeg_build
#
#SYSROOT="$TOOLCHAIN/sysroot"
#
#TOOL_PREFIX="$TOOLCHAIN/bin/armv7a-linux-androideabi"
#
#CC="$TOOL_PREFIX$API-clang"
#CXX="$TOOL_PREFIX$API-clang++"
# 用于编译android平台的脚本

# NDK所在目录
NDK_PATH=/Users/jele//Library/Android/sdk/ndk/23.1.7779620 # tag1
# macOS 平台编译，其他平台看一下 $NDK_PATH/toolchains/llvm/prebuilt/ 下的文件夹名称
HOST_PLATFORM=darwin-x86_64  #tag1
# minSdkVersion
API=30

TOOLCHAINS="$NDK_PATH/toolchains/llvm/prebuilt/$HOST_PLATFORM"
SYSROOT="$NDK_PATH/toolchains/llvm/prebuilt/$HOST_PLATFORM/sysroot"
# 生成 -fpic 与位置无关的代码
CFLAG="-D__ANDROID_API__=$API -Os -fPIC -DANDROID "
LDFLAG="-lc -lm -ldl -llog "

# 输出目录
PREFIX=`pwd`/../android-build
# 日志输出目录
CONFIG_LOG_PATH=${PREFIX}/log
# 公共配置
COMMON_OPTIONS=
# 交叉配置
CONFIGURATION=

build() {
    APP_ABI=$1
    echo "======== > Start build $APP_ABI"
    case ${APP_ABI} in
    armeabi-v7a)
    ARCH="arm"
    CPU="armv7-a"
    MARCH="armv7-a"
    TARGET=armv7a-linux-androideabi
    CC="$TOOLCHAINS/bin/$TARGET$API-clang"
    CXX="$TOOLCHAINS/bin/$TARGET$API-clang++"
    LD="$TOOLCHAINS/bin/$TARGET$API-clang"
    # 交叉编译工具前缀
    CROSS_PREFIX="$TOOLCHAINS/bin/arm-linux-androideabi-"
    EXTRA_CFLAGS="$CFLAG -mfloat-abi=softfp -mfpu=vfp -marm -march=$MARCH "
    EXTRA_LDFLAGS="$LDFLAG"
    EXTRA_OPTIONS="--enable-neon --cpu=$CPU "
    ;;
    arm64-v8a)
    ARCH="aarch64"
    TARGET=$ARCH-linux-android
    CC="$TOOLCHAINS/bin/$TARGET$API-clang"
    CXX="$TOOLCHAINS/bin/$TARGET$API-clang++"
    LD="$TOOLCHAINS/bin/$TARGET$API-clang"
    CROSS_PREFIX="$TOOLCHAINS/bin/$TARGET-"
    EXTRA_CFLAGS="$CFLAG"
    EXTRA_LDFLAGS="$LDFLAG"
    EXTRA_OPTIONS=""
    ;;
    x86)
    ARCH="x86"
    CPU="i686"
    MARCH="i686"
    TARGET=i686-linux-android
    CC="$TOOLCHAINS/bin/$TARGET$API-clang"
    CXX="$TOOLCHAINS/bin/$TARGET$API-clang++"
    LD="$TOOLCHAINS/bin/$TARGET$API-clang"
    CROSS_PREFIX="$TOOLCHAINS/bin/$TARGET-"
    #EXTRA_CFLAGS="$CFLAG -march=$MARCH -mtune=intel -mssse3 -mfpmath=sse -m32"
    EXTRA_CFLAGS="$CFLAG -march=$MARCH  -mssse3 -mfpmath=sse -m32"
    EXTRA_LDFLAGS="$LDFLAG"
    EXTRA_OPTIONS="--cpu=$CPU "
    ;;
    x86_64)
    ARCH="x86_64"
    CPU="x86-64"
    MARCH="x86_64"
    TARGET=$ARCH-linux-android
    CC="$TOOLCHAINS/bin/$TARGET$API-clang"
    CXX="$TOOLCHAINS/bin/$TARGET$API-clang++"
    LD="$TOOLCHAINS/bin/$TARGET$API-clang"
    CROSS_PREFIX="$TOOLCHAINS/bin/$TARGET-"
    #EXTRA_CFLAGS="$CFLAG -march=$CPU -mtune=intel -msse4.2 -mpopcnt -m64"
    EXTRA_CFLAGS="$CFLAG -march=$CPU -msse4.2 -mpopcnt -m64"
    EXTRA_LDFLAGS="$LDFLAG"
    EXTRA_OPTIONS="--cpu=$CPU "
    ;;
    esac
    
    echo "-------- > Start clean workspace"
    make clean
    
    echo "-------- > Start build configuration"
    CONFIGURATION="$COMMON_OPTIONS"
    CONFIGURATION="$CONFIGURATION --logfile=$CONFIG_LOG_PATH/config_$APP_ABI.log"
    CONFIGURATION="$CONFIGURATION --prefix=$PREFIX"
    CONFIGURATION="$CONFIGURATION --libdir=$PREFIX/libs/$APP_ABI"
    CONFIGURATION="$CONFIGURATION --incdir=$PREFIX/includes/$APP_ABI"
    CONFIGURATION="$CONFIGURATION --pkgconfigdir=$PREFIX/pkgconfig/$APP_ABI"
    CONFIGURATION="$CONFIGURATION --cross-prefix=$CROSS_PREFIX"
    CONFIGURATION="$CONFIGURATION --arch=$ARCH"
    CONFIGURATION="$CONFIGURATION --sysroot=$SYSROOT"
    CONFIGURATION="$CONFIGURATION --cc=$CC"
    CONFIGURATION="$CONFIGURATION --cxx=$CXX"
    CONFIGURATION="$CONFIGURATION --ld=$LD"
    # nm 和 strip
    CONFIGURATION="$CONFIGURATION --nm=$TOOLCHAINS/bin/llvm-nm"
    CONFIGURATION="$CONFIGURATION --strip=$TOOLCHAINS/bin/llvm-strip"
    CONFIGURATION="$CONFIGURATION $EXTRA_OPTIONS"
    
    echo "-------- > Start config makefile with $CONFIGURATION --extra-cflags=${EXTRA_CFLAGS} --extra-ldflags=${EXTRA_LDFLAGS}"
    ./configure ${CONFIGURATION} \
    --extra-cflags="$EXTRA_CFLAGS" \
    --extra-ldflags="$EXTRA_LDFLAGS"
    
    echo "-------- > Start make $APP_ABI with -j1"
    make -j8
    
    echo "-------- > Start install $APP_ABI"
    make install
    echo "++++++++ > make and install $APP_ABI complete."
    
}

build_all() {
    echo "$0"
    
#    COMMON_OPTIONS="$COMMON_OPTIONS --disable-everything"
    #配置开源协议声明
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-gpl"
    #目标android平台
    COMMON_OPTIONS="$COMMON_OPTIONS --target-os=android"
    #取消默认的静态库
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-static"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-shared"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-protocols"
    #开启交叉编译
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-cross-compile"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-optimizations"
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-debug"
    #尽可能小
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-small"
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-doc"
    #不要命令（执行文件）
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-programs"  # do not build command line programs
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-ffmpeg"    # disable ffmpeg build
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-ffplay"    # disable ffplay build
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-ffprobe"   # disable ffprobe build
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-symver"
#    COMMON_OPTIONS="$COMMON_OPTIONS --disable-network"
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-x86asm"
    COMMON_OPTIONS="$COMMON_OPTIONS --disable-asm"
    #启用
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-pthreads"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-mediacodec"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-jni"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-zlib"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-pic"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-hwaccels"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-autodetect"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-nonfree"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-version3"
    
    # demuxer
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=flv"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=mov"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=mpegts"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=h264"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=aac"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=mp3"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=live_flv"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=hls"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=x265"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=flac"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=webm_dash_manifest"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=hevc"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=mkv"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=matroska"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-demuxer=ac3"
    # deccoder
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=aac"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=mp3"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=hls"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=x265"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=flac"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=vp9"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=hevc"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=mkv"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=matroska"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-decoder=ac3"
    #protocol
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-protocol=file"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-protocol=rtmp"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-protocol=pipe"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-protocol=hls"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-protocol=http"
    COMMON_OPTIONS="$COMMON_OPTIONS --enable-protocol=https"
    
    echo "COMMON_OPTIONS=$COMMON_OPTIONS"
    echo "PREFIX=$PREFIX"
    echo "CONFIG_LOG_PATH=$CONFIG_LOG_PATH"
    mkdir -p ${CONFIG_LOG_PATH}
    build "armeabi-v7a"
    build "arm64-v8a"
    #  build "x86"
    #  build "x86_64"
}

echo "-------- Start --------"
build_all
echo "-------- End --------"

