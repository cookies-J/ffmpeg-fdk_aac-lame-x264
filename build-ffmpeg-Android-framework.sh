

CWD=`pwd`
FFMPEG_SOURCE="../ffmpeg-4.4"
function currFolder() {
 echo "you currnent local is $1"
}

function createFolder() {
    mkdir -p "$CWD/$1"
}

function gotoFolder() {
    cd "`pwd`/$1"
    currFolder `pwd`
}

function configureFFMpegFolder() {
    if [ ! -r "$FFMPEG_SOURCE" ]
    then
        echo 'Copy FFmpeg source'
        ln -s $FFMPEG_SOURCE ./
        # curl http://www.ffmpeg.org/releases/$SOURCE.tar.bz2 | tar xj || exit 1
    else
        curl http://www.ffmpeg.org/releases/ffmpeg-4.4.tar.bz2 | tar xj || exit 1
    fi
    
}


# 1. create filepath
createFolder Android
gotoFolder Android

# 2. download && copie ffmpeg
#configureFFMpegFolder
gotoFolder ffmpeg-4.4

# 3. build

sh "`pwd`/../android.sh"
