#!/bin/bash

function checkCommand() {
    if which $1 &> /dev/null; then
        echo "已经就绪 $1"
    else
        echo "请先安装 $1"
        exit -1
    fi
}

function dependCheck() {
    DEPEND_LIST="gcc go ffmpeg sqlcipher adb"
    for cmd in $DEPEND_LIST
    do
        checkCommand $cmd
    done
    return 0
}


function pull_WeChat_Data()
{
    EnMicroMsgDB_NUMBER=$(adb shell find /data/data/com.tencent.mm/MicroMsg/ -name 'EnMicroMsg.db' | wc -l)
    if [ $EnMicroMsgDB_NUMBER != 1 ]; then
        echo "该设备没有聊天数据库，或者存在多份聊天记录"
        exit -1
    fi

    mkdir res
    EnMicroMsgDB_PATH=$(adb shell find /data/data/com.tencent.mm/MicroMsg/ -name 'EnMicroMsg.db')
    MicroMsg_PATH=$(dirname ${EnMicroMsgDB_PATH})

    EXPORT_LIST="EnMicroMsg.db WxFileIndex.db image2 voice2 video avatar Download attachment"
    for li in $EXPORT_LIST
    do
        adb shell test -e ${MicroMsg_PATH}/${li}
        if [ $? == 0 ]; then
            adb pull ${MicroMsg_PATH}/${li} ./res/
        else
            echo "${MicroMsg_PATH}/${li} 不存在跳过"
        fi
    done

    ## FIXME: 好像是旧版本的微信才会把数据放在sdcard路径，新版本都是在上面的路径
    SDCARD_PATH="/sdcard/Android/data/com.tencent.mm/MicroMsg"
    EXPORT_LIST="attachment emoji voice2"
    SHA_DIR=$(adb shell ls ${SDCARD_PATH} | grep -E '[0-9 a-z]{32}')
    for li in $EXPORT_LIST
    do
        PULL_PATH=${SDCARD_PATH}/${SHA_DIR}/${li}
        adb shell test -e ${PULL_PATH}
        if [ $? == 0 ]; then
            adb pull ${PULL_PATH} ./res/
        else
            echo "${PULL_PATH} 不存在跳过"
        fi
    done
}

function decodeDB() {
    ENCODE_FILE=$1
    AUTH_KEY=$2
    DECODE_DB=${ENCODE_FILE%.*}_plain
    echo "$ENCODE_FILE $AUTH_KEY $DECODE_DB.db"
    sqlcipher $ENCODE_FILE << EOF
PRAGMA key='$AUTH_KEY';
PRAGMA cipher_use_hmac = off;
PRAGMA kdf_iter = 4000;
PRAGMA cipher_page_size = 1024;
PRAGMA cipher_hmac_algorithm = HMAC_SHA1;
PRAGMA cipher_kdf_algorithm = PBKDF2_HMAC_SHA1;
ATTACH DATABASE '${DECODE_DB}.db' AS ${DECODE_DB} KEY '';
SELECT sqlcipher_export('${DECODE_DB}');
DETACH DATABASE ${DECODE_DB};
.exit
EOF
}

function fixedFileName() {
    FIND_PATH=$1
    FILES=`find ${FIND_PATH} -name '*⌖'`

    # echo $FILES
    for FILE in $FILES
    do
        FIXED_FILE=${FILE%⌖}
        echo "cp $FILE $FIXED_FILE"
        cp $FILE $FIXED_FILE
    done

    FILES=`find ${FIND_PATH} -name '*__hd'`

    # echo $FILES
    for FILE in $FILES
    do
        FIXED_FILE=${FILE%%__*d}
        echo "cp $FILE $FIXED_FILE"
        cp $FILE $FIXED_FILE
    done
}

function decodeSilk2MP3() {
    PRE_PATH=$(pwd)
    cd ..
    if [ ! -f "silk-v3-decoder/converter.sh" ]; then
        git submodule update --init
    fi
    cd  silk-v3-decoder

    TARGET_DIR=${PRE_PATH}/res/voice2/
    FILE_LISTS=$(find ${TARGET_DIR} -name '*.amr')
    for FILE in ${FILE_LISTS}
    do
        sh converter.sh $FILE mp3
    done

    cd ${PRE_PATH}
}

# 检测依赖的环境是否满足
dependCheck || exit -1

AUTH_FILE="/data/data/com.tencent.mm/shared_prefs/auth_info_key_prefs.xml"

DEVICE_NUMBER=$(adb devices | grep -w 'device' | wc -l)
if [ $DEVICE_NUMBER != 1 ]; then
    echo "请确保已经连接上adb设备，并且当前只有一个adb设备"
    exit -1
fi

adb shell test -f $AUTH_FILE
if [ $? != 0 ]; then
    echo "该设备没有微信用户"
    exit -1
fi

if [ -d export_dir ]; then
    rm export_dir -rf
fi
mkdir export_dir/.tmp -p
cd export_dir

adb pull $AUTH_FILE .tmp/
AUTH_UIN=$(cat .tmp/auth_info_key_prefs.xml | grep '_auth_uin' | awk -F '"' '{print $4}')
AUTH_KEY=$(echo -n "1234567890ABCDEF${AUTH_UIN}" | md5sum | cut -c -7)
echo "获取微信数据库密钥: $AUTH_KEY"

echo "开始拉取聊天记录"
pull_WeChat_Data
echo "拉取聊天记录结束"

echo "开始解密数据库"
cd res
decodeDB EnMicroMsg.db ${AUTH_KEY}
decodeDB WxFileIndex.db ${AUTH_KEY}
cd - > /dev/null
echo "解密数据路结束"

echo "开始修复错误的图片名称"
fixedFileName res/image2
echo "结束修复错误的图片名称"

echo "开始解码语音数据"
decodeSilk2MP3
echo "结束解码语音数据"
echo "" && echo ""
echo "============= 数据导出结束 ==============="
echo "运行 go build . && ./wechat-backup -f export_dir/res/ 启动程序"